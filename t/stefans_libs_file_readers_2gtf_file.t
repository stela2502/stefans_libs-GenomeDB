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

#0: gene	4490931	4497354
#1: transcript	4490931	4496413
#8: exon	4490931	4492668
#15: three_prime_UTR	4490931	4491715
#16: transcript	4491250	4496757
#19: exon	4491250	4492663
#25: three_prime_UTR	4491250	4491715
#27: transcript	4491390	4497354
#34: exon	4491390	4492668
#39: three_prime_UTR	4491390	4491715

$exp = [ '0', '1', '8', '15', '16', '19', '25', '27', '34', '39' ];
print "\n";
is_deeply( \@values, $exp, "efficient_match_chr_position" );

@values = sort { $a <=> $b } 
  $test_object->efficient_match_chr_position_plus_one( 'chr1', 4491393 );
 print "\n";

push(@$exp, 40 ); ## just happens to be the right id ;-)
is_deeply( \@values, $exp, "efficient_match_chr_position_plus_one" );


@values =
  $test_object->efficient_match_chr_position( 'chr1', 4390931, 4391413 );
print "\n";


is_deeply( \@values, [], "efficient_match_chr_position 1 mb from the real data" );

@values =
  $test_object->efficient_match_chr_position_plus_one( 'chr1', 4390931, 4391413);
print "\n";
print "\$exp = " . root->print_perl_var_def( \@values ) . ";\n";

is_deeply( \@values, [0], "efficient_match_chr_position_plus_one 1 mb from the real data" );

#print "\$exp = " . root->print_perl_var_def( \@values ) . ";\n";


# A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

