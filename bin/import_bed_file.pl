#! /usr/bin/perl -w

#  Copyright (C) 2012-10-28 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 import_bed_file.pl

This tool allows to import a bed file for a genome. The user needs to make sure, that the bed file was careted on the right genome version.

To get further help use 'import_bed_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;
use stefans_libs::database::ROI_registration;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,     $debug,    $database,
	$organism, $version,  $bed_file,
	$ROI_tag,  $ROI_name, $source_description
);

Getopt::Long::GetOptions(
	"-organism=s"           => \$organism,
	"-version=s"            => \$version,
	"-bed_file=s"           => \$bed_file,
	"-ROI_tag=s"            => \$ROI_tag,
	"-ROI_name=s"           => \$ROI_name,
	"-source_description=s" => \$source_description,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $organism ) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version ) {
	$error .= "the cmd line switch -version is undefined!\n";
}
unless ( defined $bed_file ) {
	$error .= "the cmd line switch -bed_file is undefined!\n";
}
unless ( defined $ROI_tag ) {
	$error .= "the cmd line switch -ROI_tag is undefined!\n";
}
unless ( defined $ROI_name ) {
	$error .= "the cmd line switch -ROI_name is undefined!\n";
}
unless ( defined $source_description ) {
	$error .= "the cmd line switch -source_description is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for import_bed_file.pl

   -organism  :the organism tag
   -version   :the organism version
   -bed_file  :the bed file you want to import
   -ROI_tag   :the region of interest tag inside the database
   -ROI_name  :the ROI name inside the database
   -source_description 
              :please let me know where you got the bed file from

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/import_bed_file.pl';
$task_description .= " -organism $organism" if ( defined $organism );
$task_description .= " -version $version"   if ( defined $version );
$task_description .= " -bed_file $bed_file" if ( defined $bed_file );
$task_description .= " -ROI_tag $ROI_tag"   if ( defined $ROI_tag );
$task_description .= " -ROI_name $ROI_name" if ( defined $ROI_name );
$task_description .= " -source_description $source_description"
  if ( defined $source_description );

## Do whatever you want!

my $genomeDB  = genomeDB->new( variable_table->getDBH() );
my $interface =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( $organism,
	$version );
my $ROI_reg = ROI_registration->new( $genomeDB->{'dbh'} );
## check whether this data has already been imported:
my $id;
eval {
	$id =
	  $ROI_reg->_return_unique_ID_for_dataset(
		{ 'ROI_tag' => $ROI_tag, 'ROI_name' => $ROI_name } );
};

if ( defined $id ) {
	print
"A dataset with the ROI_tag $ROI_tag and the ROI_name $ROI_name has already been inserted into the database.\nNothing was imported into the database!\n";
	exit 0;
}
$ROI_reg->AddDataset(
	{
		'cmd'          => $task_description,
		'exec_version' => 1,
		'ROI_name'     => $ROI_name,
		'ROI_tag'      => $ROI_tag,
		'genome_id'    => $interface->{'genomeID'},
	}
);
my $data_file = stefans_libs_file_readers_bed_file->new();
$data_file->read_file($bed_file);

$interface = $interface->get_rooted_to("gbFilesTable");
#$interface->Connect_2_result_ROI_table()->batch_mode(1);

my $imported_data_table = data_table->new();
foreach ( 'gbFile_id', 'tag', 'name', 'start', 'end', 'gbString' ) {
	$imported_data_table->Add_2_Header($_);
}
my $calculator = $interface->get_chr_calculator();
my ( $gbFeature, $dataset, @temp );

for ( my $i = 0 ; $i < $data_file->Lines() ; $i++ ) {
	@temp =
	  $calculator->Chromosome_2_gbFile(
		@{ @{ $data_file->{'data'} }[$i] }[ 0 .. 2 ] );
	foreach (@temp) {
		$gbFeature = gbFeature->new( $ROI_tag, @$_[1] . ".." . @$_[2] );
		$gbFeature->Name($ROI_name);
		$gbFeature->AddInfo( 'bed_entry',
			join( "\t", @{ @{ $data_file->{'data'} }[$i] } ) );
		#push ( @{$interface->{'data'}}, [ @$_[0], $ROI_tag,$ROI_name,@$_[1],@$_[2],$gbFeature->getAsGB(),]);
		$dataset = {
			'gbFile_id' => @$_[0],
			'tag'       => $ROI_tag,
			'name'      => $ROI_name,
			'start'     => @$_[1],
			'end'       => @$_[2],
			'gbString'  => $gbFeature->getAsGB()
		};
		$interface->Connect_2_result_ROI_table->AddDataset( $dataset );
		
		#variable_table->__escape_putativley_dangerous_things($dataset);
		#print "'".$dataset ->{ 'gbString' }."'\n";
		#$imported_data_table->AddDataset($dataset);
	}
}
#$interface->Connect_2_result_ROI_table()->commit();
#$interface->Connect_2_result_ROI_table->BatchAddTable($imported_data_table);

print "Done";

