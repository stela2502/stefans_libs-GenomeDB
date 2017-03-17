#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 3;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $gtf, $liftover_bed, $outfile, );

my $exec = $plugin_path . "/../bin/Liftover_GTF.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/Liftover_GTF";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$outfile = $outpath."/liftover_hg38.gtf";

$gtf =  $plugin_path . "/data/liftover_hg19.gtf";
ok ( -f $gtf, "gtf file '$gtf'");
$liftover_bed = $plugin_path . "/data/liftover_hg38.bed";
ok( -f $liftover_bed, "liftover_bed file '$liftover_bed'");

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -gtf " . $gtf 
. " -liftover_bed " . $liftover_bed 
. " -outfile " . $outfile 
. " -debug";
my $start = time;
system( $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";
#print "\$exp = ".root->print_perl_var_def($value ).";\n";