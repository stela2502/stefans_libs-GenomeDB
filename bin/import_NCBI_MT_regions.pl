#! /usr/bin/perl -w

#  Copyright (C) 2014-03-20 Stefan Lang

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

=head1 import_NCBI_MT_regions.pl

This is an small extra tool to import the mitochondrial genome for a NCBI genome. This are is not imported using the NCBI import script, but Iis quite important for the NGS data.

To get further help use 'import_NCBI_MT_regions.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $organism, $force, $version, $gbFile);

Getopt::Long::GetOptions(
	 "-organism=s"    => \$organism,
	 "-version=s"    => \$version,
	 "-gbFile=s"    => \$gbFile,
	 "-force"       => \$force,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $organism) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version) {
	$error .= "the cmd line switch -version is undefined!\n";
}
unless ( -f $gbFile) {
	$error .= "the cmd line switch -gbFile is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for import_NCBI_MT_regions.pl

   -organism       :<please add some info!>
   -version       :<please add some info!>
   -gbFile       :<please add some info!>
   -force       :do not check whether the data has already been imported!

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/import_NCBI_MT_regions.pl';
$task_description .= " -organism $organism" if (defined $organism);
$task_description .= " -version $version" if (defined $version);
$task_description .= " -gbFile $gbFile" if (defined $gbFile);



## Do whatever you want!

use stefans_libs::database::genomeDB::genbank_flatfile_db;
use stefans_libs::database::genomeDB;


my $genome = genomeDB->new(variable_table->getDBH() );

my $interface = $genome -> GetDatabaseInterface_for_Organism_and_Version($organism, $version);
$interface = $interface ->get_rooted_to('gbFilesTable');

my $test = $interface -> get_chr_calculator();
if ( defined $test->{'chromosomes'}->{'MT'}) {
	print "The data seams to be already imported into the db - stop!\n";
	exit 0 unless ( $force);
}

my $genbank_flatfile_db = genbank_flatfile_db->new();
my $filemap = root->filemap( $gbFile );
$genbank_flatfile_db->{tempPath} = "$filemap->{'path'}/originals";
my ( $MT_gbFile ) = $genbank_flatfile_db -> loadFlatFile ( $gbFile );
$MT_gbFile = @$MT_gbFile[1];

$gbFile = $genbank_flatfile_db-> get_gbFile_obj_for_version ( $MT_gbFile );

open ( SEQ, ">$filemap->{'path'}/originals/$MT_gbFile.fa" ) or die "I could not craete the sequence file '$filemap->{'path'}/originals/$MT_gbFile.fa'\n";
print SEQ $gbFile->{'seq'};
close ( SEQ );
my $rv = $interface->AddDataset(
				{
					'gbFile'        => $gbFile,
					'chromosome'    => {
	'tax_id' => 1, ## unimportant
	'chromosome' => 'M',
	'chr_start' => 1,
	'chr_stop' => $gbFile->Length(),
	'orientation' => '+',
	'feature_name' => $MT_gbFile,
	'feature_type' => 'not recorded',
	'group_label' => '1',
	'weight' => 1,
},
					'sequence_file' => "$filemap->{'path'}/originals/$MT_gbFile.fa",
				}
);

print "I have added the MT chromosome as gbFile_id $rv\n";
















