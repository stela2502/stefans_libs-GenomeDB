#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok 'stefans_libs::file_readers::gtf_file' }

use Time::HiRes qw[ time ];

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
ok( -f $infile, "infile $infile" );

my $begin = time();
#warn "I want to see a has change between here \n$test_object\n";
$exp = $test_object->read_file($infile);
#warn "And there:\n$exp\n";

printf( "read_file consumed %.3f second(s)\n", time() - $begin );
#4.656 our
#4.603 my
ok ( ! defined $test_object->Header_Position('attribute'), "attribute column is gone" );

#print $test_object->AsString();
@values =											  
  $test_object->efficient_match_chr_position( 'chr1', 4490931, 4491413 );

$exp = [ '0', '1', '8', '15', '16', '19', '25', '27', '34', '39' ];
is_deeply( \@values, $exp, "efficient_match_chr_position" );

@values =
  $test_object->efficient_match_chr_position_plus_one( 'chr1', 4490931, 4491413 );
  
push(@$exp, 40 );
is_deeply( \@values, $exp, "efficient_match_chr_position_plus_one" );


@values =
  $test_object->efficient_match_chr_position( 'chr1', 4390931, 4391413 );

is_deeply( \@values, [], "efficient_match_chr_position 1 mb from the real data" );

@values =
  $test_object->efficient_match_chr_position_plus_one( 'chr1', 4390931, 4391413);

is_deeply( \@values, [0], "efficient_match_chr_position_plus_one 1 mb from the real data" );

#print "\$exp = " . root->print_perl_var_def( \@values ) . ";\n";


# A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

