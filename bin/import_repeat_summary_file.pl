#! /usr/bin/perl -w

#  Copyright (C) 2012-10-29 Stefan Lang

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

=head1 import_repeat_summary_file.pl

This tool can be used to import the repeat information that can be found on the repeat masker home page for a given genome.

To get further help use 'import_repeat_summary_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;
use stefans_libs::database::ROI_registration;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile, $source, $organism, $version, $force )
  ;

Getopt::Long::GetOptions(
	"-infile=s"   => \$infile,
	"-source=s"   => \$source,
	"-organism=s" => \$organism,
	"-version=s"  => \$version,
	"-force"      => \$force,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $source ) {
	$error .= "the cmd line switch -source is undefined!\n";
}
unless ( defined $organism ) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version ) {
	$error .= "the cmd line switch -version is undefined!\n";
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
 command line switches for import_repeat_summary_file.pl

   -infile    :the repeat file as found on http://www.repeatmasker.org/PreMaskedGenomes.html
   -source    :where have you gotten the infos
   -organism  :the organism tag
   -version   :the organism version
   -force     :do not check whether has been imported before

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/import_repeat_summary_file.pl';
$task_description .= " -infile $infile"     if ( defined $infile );
$task_description .= " -source '$source'"     if ( defined $source );
$task_description .= " -organism '$organism'" if ( defined $organism );
$task_description .= " -version '$version'"   if ( defined $version );

## Do whatever you want!

my $genomeDB  = genomeDB->new( variable_table->getDBH() );
my $interface =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( $organism,
	$version );
my $ROI_reg = ROI_registration->new( $genomeDB->{'dbh'} );
## check whether this data has already been imported:
my $id;
unless ($force) {
	eval {
		$id =
		  $ROI_reg->_return_unique_ID_for_dataset(
			{ 'ROI_tag' => 'repeat', 'ROI_name' => 'repeatmasker' } );
	};

	if ( defined $id ) {
		print
"I already have a repeat dataset in the database.\nNothing was imported into the database!\n";
		exit 0;
	}
}
unless ($debug) {
	$ROI_reg->AddDataset(
		{
			'cmd'          => $task_description,
			'exec_version' => 1,
			'ROI_name'     => 'repeatmasker',
			'ROI_tag'      => 'repeat',
			'genome_id'    => $interface->{'genomeID'},
		}
	);
}

$interface = $interface->get_rooted_to("gbFilesTable");
my $repeat_table = $interface->Connect_2_REPEAT_ROI_table();

#print "I add to the data table ".$repeat_table->TableName()."\n";
my $imported_data_table = data_table->new();
foreach ( 'gbFile_id', 'tag', 'name', 'start', 'end', 'gbString' ) {
	$imported_data_table->Add_2_Header($_);
}
my $calculator = $interface->get_chr_calculator();
my ( $gbFeature, $dataset, @temp );
open( IN, "<$infile" ) or die "I could not open the infile '$infile'\n$!\n";
my $i = 0;
my $repeat;
WHILE: while (<IN>) {

#   SW  perc perc perc  query      position in query           matching       repeat              position in  repeat
#score  div. del. ins.  sequence    begin     end    (left)    repeat         class/family         begin  end (left)   ID
#
# 1504   1.3  0.4  1.3  chr1        10001   10468 (249240153) +  (CCCTAA)n      Simple_repeat            1  463    (0)      1
	$i++;
	next if ( $i < 3 );
	chomp($_);
	$_ =~ s/^\s+//;
	$repeat = [ split( /\s+/, $_ ) ];
	@temp = $calculator->Chromosome_2_gbFile( @$repeat[ 4 .. 6 ] );
	foreach (@temp) {
		$gbFeature = gbFeature->new( 'repeat', @$_[1] . ".." . @$_[2] );
		@$repeat[9] =~s/\?/./g;
		@$repeat[10] =~s/\?/./g;
		$gbFeature->Name( @$repeat[9] );
		$gbFeature->AddInfo( 'repeat_class', @$repeat[10] );
		$dataset = {
			'gbFile_id' => @$_[0],
			'tag'       => 'repeat',
			'name'      => @$repeat[9],
			'start'     => @$_[1],
			'end'       => @$_[2],
			'gbString'  => $gbFeature->getAsGB()
		};

		#$dataset -> {'gbString'} =~s /"/'/g;
		variable_table->__escape_putativley_dangerous_things($dataset);
		if ($debug) {
			print
"I have created a repeat for @$repeat[4]:@$repeat[5]..@$repeat[6] with the rep_family @$repeat[10] and the repeat name @$repeat[9]\n";
			root::print_hashEntries( $dataset, 3, "a repeat" );
			print "And the gbString repeated:\n$dataset->{'gbString'}";
			last WHILE;
		}
		else {
			$imported_data_table->AddDataset($dataset);
			#$interface->Connect_2_result_ROI_table->AddDataset( $dataset );
		}
	} # <- end foreach @temp
	if ( $i % 10000 == 0 ) {
		print "Insert until repeat $i\n";
		if ( $imported_data_table->Lines() > 0 ) {
			$repeat_table->BatchAddTable(
					$imported_data_table);
			$imported_data_table =
				  $imported_data_table->_copy_without_data();
		}
	}
}
#print "The imported data table:\n" . $imported_data_table->AsString();
$repeat_table->BatchAddTable($imported_data_table) if ( $imported_data_table->Lines() > 0 );

print "Done";

