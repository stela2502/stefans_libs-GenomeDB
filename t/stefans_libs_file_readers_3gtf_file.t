#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::file_readers::gtf_file' }
my ( $simple, $complex, $exp, $value, @value, $tmp ) ;
$simple = [ qw(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chrX chrY chrM)];
$complex = [ 
	qw(GL456210.1 GL456211.1 GL456212.1 GL456213.1 GL456216.1 GL456219.1 GL456221.1 GL456233.1 GL456239.1 GL456350.1 GL456354.1 GL456359.1 
	GL456360.1 GL456366.1 GL456367.1 GL456368.1 GL456370.1 GL456372.1 GL456378.1 GL456379.1 GL456381.1 GL456382.1 GL456383.1 GL456385.1 
	GL456387.1 GL456389.1 GL456390.1 GL456392.1 GL456393.1 GL456394.1 GL456396.1 JH584292.1 JH584293.1 JH584294.1 JH584295.1 JH584296.1 
	JH584297.1 JH584298.1 JH584299.1 JH584300.1 JH584301.1 JH584302.1 JH584303.1 JH584304.1 KQ030490.1 KB469738.3 JH792830.1 KV575237.1
	KK082442.1 KV575240.1 KV575235.1 KV575239.1 KQ030495.1 KV575238.1 KV575234.1 KQ030485.1 KQ030486.1 KQ030487.1 KB469739.1 KB469741.2 
	JH792829.1 KV575236.1 KV575233.1 JH792826.1 JH792828.1 KB469740.1 JH792832.1 JH792833.1 JH792827.1 JH792834.1 JH792831.1 KB469742.1 
	KQ030484.1 KQ030494.1 KQ030496.1 KQ030497.1 KQ030492.1 KQ030493.1 KQ030491.1 KQ030488.1 KQ030489.1 KV575232.1 KV575241.1 KV575242.1
	KK082441.1
) ];

$exp = [ @$simple, @$complex];

my $test_object = stefans_libs::file_readers::gtf_file->new();

is_deeply( [ map {$test_object ->_checkChr($_) } @$exp ], $exp, "correct are not touched");

$tmp = [ @$simple, map{ "chr$_" } @$complex];

is_deeply( [ map {$test_object ->_checkChr($_) } @$tmp ], $exp, "problems are fixed");

print scalar( @$complex );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

