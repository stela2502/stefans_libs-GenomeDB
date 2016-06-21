#! /usr/bin/perl -w

#  Copyright (C) 2012-12-10 Stefan Lang

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

=head1 create_regions_comparison_4_chromosome.pl

This script creates a plot over a whole chromosome showing the expressed genes in a middle row, the regions of tag 1 in the upper row and of tag 2 in the lower row. The regions are displayed by small bars and are colored according to the match (not in a gene in balck, in a gene in blue, promoter green and gene end red).

To get further help use 'create_regions_comparison_4_chromosome.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;
use stefans_libs::plot::compare_two_regions_on_a_chr;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $ROI_tag_1, $ROI_tag_2, $ROI_name_1, $ROI_name_2, $chromosme, $start, $end, $outfile, $organism_tag, $organism_version, $labbook_id, $labbook_entry_id, $workload_id);

Getopt::Long::GetOptions(
	 "-ROI_tag_1=s"    => \$ROI_tag_1,
	 "-ROI_tag_2=s"    => \$ROI_tag_2,
	 "-ROI_name_1=s"    => \$ROI_name_1,
	 "-ROI_name_2=s"    => \$ROI_name_2,
	 "-chromosme=s"    => \$chromosme,
	 "-start=s"    => \$start,
	 "-end=s"    => \$end,
	 "-outfile=s"    => \$outfile,
	 "-organism_tag=s"    => \$organism_tag,
	 "-organism_version=s"    => \$organism_version,
	 "-labbook_id=s"    => \$labbook_id,
	 "-labbook_entry_id=s"    => \$labbook_entry_id,
	 "-workload_id=s"    => \$workload_id,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

if  (!( defined $ROI_tag_1) && ! ( defined $ROI_name_1 ) ){
	$error .= "the cmd line switch -ROI_tag_1 and -ROI_name_1 are undefined!\n";
}
if  (!( defined $ROI_tag_2) && ! ( defined $ROI_name_2 ) ){
	$error .= "the cmd line switch -ROI_tag_2 and -ROI_name_2 are undefined!\n";
}

unless ( defined $chromosme) {
	$error .= "the cmd line switch -chromosme is undefined!\n";
}
unless ( defined $start) {
	$warn .= "the cmd line switch -start is undefined!\n";
}
unless ( defined $end) {
	$warn .= "the cmd line switch -end is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $organism_tag) {
	$error .= "the cmd line switch -organism_tag is undefined!\n";
}
unless ( defined $organism_version) {
	$warn .= "the cmd line switch -organism_version is undefined!\n";
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
 command line switches for create_regions_comparison_4_chromosome.pl

   -ROI_tag_1       :<please add some info!>
   -ROI_tag_2       :<please add some info!>
   -ROI_name_1       :<please add some info!>
   -ROI_name_2       :<please add some info!>
   -chromosme       :<please add some info!>
   -start       :<please add some info!>
   -end       :<please add some info!>
   -outfile       :<please add some info!>
   -organism_tag       :<please add some info!>
   -organism_version       :<please add some info!>
   -labbook_id       :<please add some info!>
   -labbook_entry_id       :<please add some info!>
   -workload_id       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/create_regions_comparison_4_chromosome.pl';
$task_description .= " -ROI_tag_1 $ROI_tag_1" if (defined $ROI_tag_1);
$task_description .= " -ROI_tag_2 $ROI_tag_2" if (defined $ROI_tag_2);
$task_description .= " -ROI_name_1 $ROI_name_1" if (defined $ROI_name_1);
$task_description .= " -ROI_name_2 $ROI_name_2" if (defined $ROI_name_2);
$task_description .= " -chromosme $chromosme" if (defined $chromosme);
$task_description .= " -start $start" if (defined $start);
$task_description .= " -end $end" if (defined $end);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -organism_tag $organism_tag" if (defined $organism_tag);
$task_description .= " -organism_version $organism_version" if (defined $organism_version);
$task_description .= " -labbook_id $labbook_id" if (defined $labbook_id);
$task_description .= " -labbook_entry_id $labbook_entry_id" if (defined $labbook_entry_id);
$task_description .= " -workload_id $workload_id" if (defined $workload_id);


## Do whatever you want!
my $genomeDB = genomeDB->new( variable_table->getDBH() );
my $interface = $genomeDB -> GetDatabaseInterface_for_Organism_and_Version ($organism_tag, $organism_version);
my $ROI_table = $interface->Connect_2_result_ROI_table();
my $helper = $interface-> get_chr_calculator ();
my @data =  $helper->Chromosome_2_gbFile( $chromosme, $start, $end );
$start = 1 unless ( defined $start );
unless ( defined $end ) {
	$end = 0;
	foreach ( @data ) {
		$end = @$_[2] if ( @$_[2] > $end ); 
	}
}
print "\\\@data = ".root->print_perl_var_def(\@data ).";\n"if ( $debug );
my @gbFile_IDs;
foreach ( @data ) {
	next unless ( ref ($_) eq "ARRAY" );
	push ( @gbFile_IDs, @$_[0] );
}
shift ( @gbFile_IDs ) unless ( defined $gbFile_IDs[0]);

## I need to get the values for the ROIs as bed files
my $bedA = $ROI_table -> get_ROI_as_bed_file ( { 'gbFile_id' => \@gbFile_IDs, 'tag' => $ROI_tag_1, 'name' => $ROI_name_1,  } );
my $bedC = $ROI_table -> get_ROI_as_bed_file ( { 'gbFile_id' => \@gbFile_IDs, 'tag' => $ROI_tag_2, 'name' => $ROI_name_2,  } );
## I need to get the genes lists as bed file object
my  $bedB = $interface -> get_genes_in_chromosomal_region_as_bedFile ($chromosme, $start, $end);
## that might be huge....
print $bedB->AsTestString() ;
## I need to plot the results
my $plot =  stefans_libs::plot::compare_two_regions_on_a_chr->new();
$plot -> plot(
	{
		'outfile' => $outfile ,
		'upper'   => { 'name' => "$ROI_tag_1 $ROI_name_1", 'object' => $bedA },
		'center'  => { 'name' => 'genes', 'object' => $bedB },
		'lower'   => { 'name' => "$ROI_tag_2 $ROI_name_2", 'object' => $bedC },
		'chr'     => $chromosme,
		'start'   => $start,
		'end'     => $end,
	}
);
## done!

