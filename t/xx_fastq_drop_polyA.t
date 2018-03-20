#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $ignored, @fastq, $cutoff );

my $exec = $plugin_path . "/../bin/fastq_drop_polyA.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/fastq_drop_polyA";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}
@fastq = ( $plugin_path."/data/test_polyA2.fastq.gz");
$ignored = 20;
$cutoff = 30;

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -ignored " . $ignored 
. " -fastq " . join(' ', @fastq )
. " -cutoff $cutoff"
. " -debug";
my $start = time;
system( $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";
#print "\$exp = ".root->print_perl_var_def($value ).";\n";