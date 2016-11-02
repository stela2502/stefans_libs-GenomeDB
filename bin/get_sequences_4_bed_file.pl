#! /usr/bin/perl -w

#  Copyright (C) 2014-02-20 Stefan Lang

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

=head1 get_sequences_4_bed_file.pl

This script gets you all sequences for a given bed file. Make sure you use the right genome for that.

To get further help use 'get_sequences_4_bed_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;

use stefans_libs::file_readers::bed_file;
use stefans_libs::fastaDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my $includes = "-I " . join( " -I ", @INC );

my ( $help, $debug, $database, $bed_file, $bp_in_center, $masked, $organism, $version, $outfile, $no_N_regions );

Getopt::Long::GetOptions(
	 "-bed_file=s"    => \$bed_file,
	 "-organism=s"    => \$organism,
	 "-version=s"    => \$version,
	 "-outfile=s"    => \$outfile,
	 "-masked"       => \$masked,
	 "-bp_in_center=s" => \$bp_in_center,
	 "-no_N_regions" => \$no_N_regions,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $bed_file) {
	$error .= "the cmd line switch -bed_file is undefined!\n";
}
unless ( defined $organism) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version) {
	$warn .= "the cmd line switch -version is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
else {
	my $filemap = root->filemap($outfile);
	mkdir( $filemap->{'path'} ) unless ( -d $filemap->{'path'});
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
 command line switches for get_sequences_4_bed_file.pl

   -bed_file   :the bed file containing the positions for the fasta table
   -organism   :the genome organism e.g. M_musculus or H_sapiens
   -version    :the genome version (can be lest empty)
   -outfile    :the fasta db file
   
   -bp_in_center  :select only <bin_in_center> bp around the center of the bed region
   -no_N_regions  :suppress the output of N only regions
   
   -masked     :use repeat masker data to convert repeat sequences into N seq
   
   -help       :print this help
   -debug      :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.$includes.' '.$plugin_path .'/get_sequences_4_bed_file.pl';
$task_description .= " -bed_file $bed_file" if (defined $bed_file);
$task_description .= " -organism $organism" if (defined $organism);
$task_description .= " -version $version" if (defined $version);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -masked" if ( $masked );
$task_description .= " -bp_in_center $bp_in_center" if ( $bp_in_center);
$task_description .= " -no_N_regions" if ( $no_N_regions );

open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );

my ($genomeDB, $bed, );
## Do whatever you want!
$genomeDB = genomeDB->new(variable_table->getDBH());

my $interface =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( $organism,
	$version );
$interface = $interface->get_rooted_to('gbFilesTable');
$interface -> Connect_2_REPEAT_ROI_table() if ( $masked );
$masked ||= 0;
#print "Do I have to mask the genome? $masked\n";

$bed = stefans_libs::file_readers::bed_file->new();
$bed -> read_file ( $bed_file );

## so now iónle get the info from the DB - fingers crossed!
my $fastaDB = $bed -> get_as_fastaDB ( $interface, $bp_in_center, $no_N_regions );

$fastaDB->WriteAsFastaDB($outfile);

