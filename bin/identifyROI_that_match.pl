#! /usr/bin/perl -w

#  Copyright (C) 2012-11-02 Stefan Lang

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

=head1 identifyROI_that_match.pl

This script extracts ROI elements, that do matcha given genomic information like promotor, terminator or transcribed_region.

To get further help use 'identifyROI_that_match.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $ROI_tag, $ROI_name, @gene_type, $organism, $version, $outfile);

Getopt::Long::GetOptions(
	 "-ROI_tag=s"    => \$ROI_tag,
	 "-ROI_name=s"    => \$ROI_name,
	 "-gene_type=s{,}"    => \@gene_type,
	 "-organism=s"    => \$organism,
	 "-version=s"    => \$version,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $ROI_tag) {
	$warn .= "the cmd line switch -ROI_tag is undefined!\n";
}
unless ( defined $ROI_name) {
	$warn .= "the cmd line switch -ROI_name is undefined!\n";
}
unless ( defined $gene_type[0]) {
	@gene_type = qw(promotor terminator gene);
}
unless ( defined $organism) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version) {
	$error .= "the cmd line switch -version is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for identifyROI_that_match.pl

   -ROI_tag       :a ROI tag I should use to identify the ROI elements
   -ROI_name      :a ROI name I should use to identify the ROI elements
   -gene_type     :something out of the list promotor terminator gene
                   you will get the whole bunch if you leave this value empty
   -organism      :the organism to iudentify the genome
   -version       :the version to identify the genome
   -outfile       :where to print the data to

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/identifyROI_that_match.pl';
$task_description .= " -ROI_tag $ROI_tag" if (defined $ROI_tag);
$task_description .= " -ROI_name $ROI_name" if (defined $ROI_name);
$task_description .= ' -gene_type '.join( ' ', @gene_type ) if ( defined $gene_type[0]);
$task_description .= " -organism $organism" if (defined $organism);
$task_description .= " -version $version" if (defined $version);
$task_description .= " -outfile $outfile" if (defined $outfile);


## Do whatever you want!
my $genomeDB = genomeDB->new( variable_table->getDBH());
my $interface = $genomeDB -> GetDatabaseInterface_for_Organism_and_Version ($organism, $version);
my $ROI_table = $interface-> Connect_2_result_ROI_table();
my $result_bed_file = $ROI_table->get_ROI_as_bed_file( {'tag' => $ROI_tag, 'name' => $ROI_name });
my ($other_bed_file, $info) ;
$interface = $genomeDB -> GetDatabaseInterface_for_Organism_and_Version ($organism, $version);
foreach ( @gene_type ) {
	$other_bed_file = undef;
	if ( $_ eq "promotor"){
		$other_bed_file = $interface->get_as_bed_file ( {'tag' => 'gene', 's_start' => 5000, 's_end' => 2000 } );
		$info = $result_bed_file -> match_to ( $other_bed_file );
		$result_bed_file -> add_info_to_name ($info, $other_bed_file );
		$other_bed_file->print2file ( $outfile."_$_" );
	}
	elsif ( $_ eq  "terminator" ) {
		$other_bed_file = $interface->get_as_bed_file ( {'tag' => 'gene', 'e_start' => 250, 'e_end' => 250 } );
		$info = $result_bed_file -> match_to ( $other_bed_file );
		$result_bed_file -> add_info_to_name ($info, $other_bed_file );
		$other_bed_file->print2file ( $outfile."_$_" );
	} 
	elsif (  $_ eq  "gene"){
		$other_bed_file = $interface->get_as_bed_file ( {'tag' => 'gene' } );
		$info = $result_bed_file -> match_to ( $other_bed_file );
		$result_bed_file -> add_info_to_name ($info, $other_bed_file );
		$other_bed_file->print2file ( $outfile."_$_" );
	}
	else { 
		warn "I can not use the gene_type '$_'\n";
	}
}
$result_bed_file-> print2file ( $outfile );

