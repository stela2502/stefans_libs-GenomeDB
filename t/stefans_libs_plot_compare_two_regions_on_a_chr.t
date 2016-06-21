#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::plot::compare_two_regions_on_a_chr' }
BEGIN { use_ok 'stefans_libs::file_readers::bed_file' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $stefans_libs_plot_compare_two_regions_on_a_chr =
  stefans_libs::plot::compare_two_regions_on_a_chr->new();
is_deeply(
	ref($stefans_libs_plot_compare_two_regions_on_a_chr),
	'stefans_libs::plot::compare_two_regions_on_a_chr',
'simple test of function stefans_libs:plot:compare_two_regions_on_a_chr -> new()'
);

#####################
# The idear is to add three bed files and plot them in position 1 (TUBG) 2 (Genome) and 3 (H2Az)
# Therefore I need three bed objects here
#####################

my ( $bedA, $bedB, $bedC );

$bedA = stefans_libs_file_readers_bed_file->new();    ## the epigenetics 1
$bedB = stefans_libs_file_readers_bed_file->new();    ## the genes
$bedC = stefans_libs_file_readers_bed_file->new();    ## the epigenetics 2

#####################
# Add some data
#####################

## 1 overlap A and B
## 2 only A or B
## 3 gene start A and B
## 4 gene end A; gene body B
$bedA->parse_from_string( "#chromosome\tstart\tend\n"
	  . "chr2\t1500\t1700\n"
	  . "chr2\t2600\t2700\n"
	  . "chr2\t5000\t5400\n"
	  . "chr2\t7000\t7500\n" );
$bedC->parse_from_string( "#chromosome\tstart\tend\n"
	  . "chr2\t1300\t1600\n"
	  . "chr2\t2800\t3000\n"
	  . "chr2\t5000\t5400\n"
	  . "chr2\t5700\t6500\n" );
$bedB->parse_from_string( "#chromosome\tstart\tend\ţname\n"
	  . "chr2\t5000\t7200\ttest_gene\n"
	  . "chr2\t6700\t9000\toverlapping_gene1\n"
	  . "chr9\t1500\t7500\n");

unlink $plugin_path . "/test_bed_plot.svg"
  if ( -f $plugin_path . "/test_bed_plot.svg" );
$stefans_libs_plot_compare_two_regions_on_a_chr->plot(
	{
		'outfile' => $plugin_path . "/test_bed_plot.svg",
		'upper'   => { 'name' => 'Bed A', 'object' => $bedA },
		'center'  => { 'name' => 'genes', 'object' => $bedB },
		'lower'   => { 'name' => 'bed C', 'object' => $bedC },
		'chr'     => 'chr2',
		'start'   => 1000,
		'end'     => 11000,
	}
);
is_deeply( ( -f $plugin_path . "/test_bed_plot.svg" ), 1,
	"figure was created" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

