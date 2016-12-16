#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
BEGIN { use_ok 'stefans_libs::file_readers::gtf_file' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $test_object, $value, $exp, @values );
$test_object = stefans_libs::file_readers::gtf_file->new();
is_deeply(
	ref($test_object),
	'stefans_libs::file_readers::gtf_file',
	'simple test of function stefans_libs::file_readers::gtf_file -> new()'
);

my $infile = "$plugin_path/data/GOI.gtf3";
ok(-f $infile, "infile $infile");
$test_object->read_file($infile);

print $test_object->AsTestString();
# A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

