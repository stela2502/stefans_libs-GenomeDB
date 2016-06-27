#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $gbFile, );

my $exec = $plugin_path . "/../bin/test_gbFile.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/test_gbFile";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$gbFile = "$plugin_path/data/hu_genome/originals/NT_113819.1.gb";
my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -gbFile " . $gbFile 
. " -debug";

system ( $cmd );

#print "\$exp = ".root->print_perl_var_def($value ).";\n