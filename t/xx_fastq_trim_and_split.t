#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 12;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my (
	$value,   @values, $exp,       $fastq, @barcodes, @options,
	$outpath, $linker, $rev_compl, $tmp,   @tmp
);

my $exec = $plugin_path . "/../bin/fastq_trim_and_split.pl";
ok( -f $exec, 'the script has been found' );

$outpath = "$plugin_path/data/output/fastq_trim_and_split";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$fastq = "$plugin_path/data/test_4_implement.fastq.gz";
ok( -f $fastq, "input fastq file $fastq" );
@barcodes = qw(TCCG TGCC TATT TTAA AACC ACAA GCCA GACC);
$linker   = 'CACGACGCTCTTCCGATCT';

$rev_compl = 0;    ## reverse complement linker but not barcodes

#$rev_compl = 1; ## rev compl barcodes, but not linker

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
  . " -fastq "
  . $fastq
  . " -barcodes "
  . join( ' ', @barcodes )
  . " -linker $linker"

  #. " -options " . join(' ', @options )
  . " -outpath " . $outpath . " -debug";

$cmd .= " -rev_barcode" if ($rev_compl);

print $cmd. "\n";

my $start_run = time();

system($cmd );

my $end_run  = time();
my $run_time = $end_run - $start_run;

print "The run has taken $run_time seconds to process 10000 fastq enries\n";

open( TEST,
	"zcat $plugin_path/data/output/fastq_trim_and_split/*.gz | wc -l |" )
  or die "I could not run the bash dependant test\n";
is_deeply( <TEST>, "40000\n", "right summary line count overall" );
close(TEST);

#@values = map { &rev_compl($_) } @barcodes ;
#$exp = { map { $_ => "1\n"} @barcodes, @values };
#print "\$exp = ".root->print_perl_var_def($exp ).";\n";

if ( !$rev_compl ) {
	$exp = {
		'TTAA' => '8',
		'AACC' => '60',
		'ACAA' => '0',
		'GCCA' => '8',
		'GACC' => '48',
		'TCCG' => '1096',
		'TGCC' => '12',
		'TATT' => '0'
	};
}
else {
	$exp = {
		'GGTT' => '128',    #H9 PUS7KO
		'GGTC' => '800',    #H9 PUS7KO+PUS7
		'AATA' => '52',     #293T PUS7KO
		'TTGT' => '36',     #H9 PUS7KO+PUS7
		'CGGA' => '8',      #293T PUS7KO
		'GGCA' => '24',     #293T PUS7KO+PUS7
		'TGGC' => '16',     #H9 PUS7KO
		'TTAA' => '16',     #293T PUS7KO+PUS7
	};
	$exp = {};
}

my $summary = 0;
foreach my $barcode (@barcodes) {
	$barcode = rev_compl($barcode) if ($rev_compl);
	open( TEST,
"zcat $plugin_path/data/output/fastq_trim_and_split/test_4_implement_$barcode.fastq.gz | wc -l |"
	) or die "I could not run the bash dependant test for sample $barcode\n";
	$tmp = join( "", <TEST> );
	close(TEST);
	chomp($tmp);
	is_deeply( $tmp, $exp->{$barcode},
		"right summary line count $barcode ($exp->{$barcode})" );
	$summary += $tmp;
	$value->{$barcode} = $tmp;
}

print "I got "
  . ( $summary / 4 )
  . " out of 10.000 reads mapped to a sample "
  . sprintf( "%d.3", ( $summary * 100 / 40000 ) ) . "%\n";

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";

sub rev_compl {
	my ($forward) = @_;
	my $rev = reverse($forward);
	$rev =~
	  tr/ABCDGHMNRSTUVWXYabcdghmnrstuvwxy/TVGHCDKNYSAABWXRtvghcdknysaabwxr/;
	return $rev;
}

open( IN,
"zcat $plugin_path/data/output/fastq_trim_and_split/test_4_implement_TTAA.fastq.gz |"
) or die "Could not read test_4_implement_TTAA.fastq.gz\n";
$value = [<IN>];
$value = [ map { chomp(); $_ } @$value ];
close(IN);
$exp = [
	'@NS500281:228:HFKVCBGXY:1:11101:15532:1678:TCTGA:TTAA 1:N:0:0',
	'GTCTCATTTTGCATCTCGGCAGTCTCTTTCTGATTGTCCAGTTGC',
	'+',
	'AEEEE/EEEEEE/E/EEEE/E/EAEEEEEEEE6EEEAEEEEAEE/',
	'@NS500281:228:HFKVCBGXY:1:11101:5862:1869:AACCC:TTAA 1:N:0:0',
	'GCTACTAAATGCCGCGGATTGGTTTCGCTGAATCAGGTTATTAAA',
	'+',
	'<EEEEE///EEA//E/6E/EAE/E<EEEEE/EEE/EEEEEEAA//'
];

is_deeply( $value, $exp, "right TTAA fastq file" );

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
