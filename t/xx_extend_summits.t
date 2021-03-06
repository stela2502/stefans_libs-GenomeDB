#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outpath, $extend, @summits, );

my $exec = $plugin_path . "/../bin/extend_summits.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/extend_summits";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -outpath " . $outpath 
. " -extend " . $extend 
. " -summits " . join(' ', @summits )
. " -debug";
system( $cmd );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";