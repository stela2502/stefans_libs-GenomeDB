#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $bed_file, $organism, $outfile, $version, $feature_name, $feature_tag, $max_distance, );

my $exec = $plugin_path . "/../bin/annotate_bed_like_file.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/annotate_bed_like_file";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec.pl "
. " -bed_file " . $bed_file 
. " -organism " . $organism 
. " -with_header " # or not?
. " -outfile " . $outfile 
. " -version " . $version 
. " -feature_name " . $feature_name 
. " -feature_tag " . $feature_tag 
. " -max_distance " . $max_distance 
. " -debug";
#print "\$exp = ".root->print_perl_var_def($value ).";\n