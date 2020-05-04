#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::fastaFile' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = fastaFile -> new();
is_deeply ( ref($OBJ) , 'fastaFile', 'simple test of function stefans_libs::fastaFile2 -> new() ');


my $seq = "AGGTTCCAA";
$exp = "TTGGAACCT";
$value = $OBJ -> revComplement ( $seq );
ok ( $value eq $exp, "revComplement" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


