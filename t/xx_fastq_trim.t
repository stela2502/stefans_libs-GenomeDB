#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $start, @fastq, $end, );

my $exec = $plugin_path . "/../bin/fastq_trim.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/fastq_trim";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}
@fastq = ( $plugin_path."/data/test_polyA2.fastq.gz");

$start = 0;
$end = 35;

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -start " . $start 
. " -fastq " . join(' ', @fastq )
. " -end " . $end 
. " -debug";

$start = time;
system( $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";


#print "\$exp = ".root->print_perl_var_def($value ).";\n";