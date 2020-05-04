#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::gbFile::file_parser' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = stefans_libs::gbFile::file_parser -> new({'debug' => 1});
is_deeply ( ref($OBJ) , 'stefans_libs::gbFile::file_parser', 'simple test of function stefans_libs::gbFile::file_parser -> new() ');

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


