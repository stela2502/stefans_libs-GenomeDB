#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outfile, $bed_file, @options, );

my $exec = $plugin_path . "/../bin/bed_to_gtf.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/bed_to_gtf";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec.pl "
. " -outfile " . $outfile 
. " -bed_file " . $bed_file 
. " -options " . join(' ', @options )
. " -debug";
#print "\$exp = ".root->print_perl_var_def($value ).";\n