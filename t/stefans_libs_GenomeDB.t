#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::GenomeDB' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = stefans_libs::GenomeDB -> new({'debug' => 1});
is_deeply ( ref($OBJ) , 'stefans_libs::GenomeDB', 'simple test of function stefans_libs::GenomeDB -> new() ');

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


