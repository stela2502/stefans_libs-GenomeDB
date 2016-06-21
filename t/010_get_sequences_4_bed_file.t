#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 18;

use stefans_libs::database::genomeDB;
use stefans_libs::file_readers::bed_file;
use stefans_libs::fastaDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $data_table = data_table->new();
my ($exp, $value, @values, $temp);
my $includes = "-I " . join( " -I ", @INC );
my $path     = $plugin_path . "/data";
my $outpath  = "$path/output";

#system("rm -R $path/output ");
mkdir($path)    unless ( -d $path );
mkdir($outpath) unless ( -d $outpath );

print "This script is meant to run with the mm9 version of the mouse genome.
Just ignore the results if you have installed a different version of the Mus musculus genome or none at all.\n";

## now I would need to create my bed file....

##lern some perl...
#my $seq = 'AGCT' x 30;
#print $seq."\n";
#print "And now replace the first 30 values by \n".('N' x 30)."\n";
#print "replaced_region: \n". substr ($seq,0, 30, 'N' x 30)."\n";
#print $seq."\n";
#die;

is_deeply( &get_chr1_seq( 1,100,1), 'GNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'get_chr1_seq' );

is_deeply( &get_chr1_seq( 146,166,1), 'NNNNNNNNNNNCTGTCATAGA', 'get_chr1_seq' );

my $bed = stefans_libs_file_readers_bed_file->new();

$bed -> AddDataset({ 'chromosome' => 'chr1',
			'start'      => 3000001,
			'end'        => 3000100,
			'name'       => 'chr1:3000001-3000100',
			 });
$bed -> AddDataset({ 'chromosome' => 'chr1',
			'start'      => 3000146,
			'end'        => 3000166,
			'name'       => 'chr1:3000146-3000166',
			 });	
$bed -> AddDataset({ 'chromosome' => 'chr1',
			'start'      =>  22473349,
			'end'        =>  22473370,
			'name'       => 'chr1:22473349-22473370',
	});
$bed -> AddDataset({ 'chromosome' => 'chr1',
			'start'      =>  22473350 + 840,
			'end'        =>  22473350 + 879,
			'name'       => 'chr1:22474190-22474229',
	});	
$bed->write_file( "$outpath/sample_bed_file.bed" );

my $cmd = 
        "perl $includes $plugin_path/../bin/get_sequences_4_bed_file.pl "
	  . " -bed_file $outpath/sample_bed_file.bed"
	  . " -outfile $outpath/resulting_fastaDB.fa"
	  . " -organism 'M_musculus'"
	  ." -version '37.2.0'";
#print $cmd."\n";
system(
	$cmd
	  #. " > /dev/null 2> /dev/null" 
);
my @regions = ( [], [1, 100], [146,166 ],[1,21], [841,880] );


my $fastaDB = fastaDB->new( "$outpath/resulting_fastaDB.fa" );
my $mapped = 0;
for ( my $i =1; $i < 5; $i ++ ){
	@values = $fastaDB->get_next();
	is_deeply($values[0], @{@{$bed->{'data'}}[$i-1]}[3], "acc == @{@{$bed->{'data'}}[$i-1]}[3]" );
	if ( $i < 3 ) {
	is_deeply( $values[1], uc(&get_chr1_seq(@{$regions[$i]},$mapped )),"Seq $i no repeat masking" );
	}
	else {
		is_deeply( $values[1], uc(&get_chr1_2_seq(@{$regions[$i]},$mapped )),"Seq $i no repeat masking" );
	}
}
system(
	$cmd. " -masked"
	  #. " > /dev/null 2> /dev/null" 
);
$mapped = 1;
$fastaDB = fastaDB->new( "$outpath/resulting_fastaDB.fa" );
for ( my $i =1; $i < 5; $i ++ ){
	@values = $fastaDB->get_next();
	if ( $i < 3 ) {
	is_deeply( $values[1], uc(&get_chr1_seq(@{$regions[$i]},$mapped )),"Seq $i masked" );
	}
	else {
		is_deeply( $values[1], uc(&get_chr1_2_seq(@{$regions[$i]},$mapped )),"Seq $i masked" );
	}
}


system(
	$cmd. " -masked". " -bp_in_center 8"
	  #. " > /dev/null 2> /dev/null" 
);
$fastaDB = fastaDB->new( "$outpath/resulting_fastaDB.fa" );
for ( my $i =1; $i < 5; $i ++ ){
	@values = $fastaDB->get_next();
	$value = int((@{$regions[$i]}[0] + @{$regions[$i]}[1])/2 );
	@{$regions[$i]}[0] = $value - 4;
	@{$regions[$i]}[1] = $value + 3;
	if ( $i < 3 ) {
	is_deeply( $values[1], uc(&get_chr1_seq(@{$regions[$i]},$mapped )),"Seq $i bp_in_center" );
	}
	else {
		is_deeply( $values[1], uc(&get_chr1_2_seq(@{$regions[$i]},$mapped )),"Seq $i bp_in_center" );
	}
}


#is_deeply( $values[1], uc($seq_1),'Seq 1 no repeat masking' );
##print $fastaDB->getAsFastaDB();
#
#@values = $fastaDB->get_next();
#is_deeply( $values[1], uc($seq_2),'Seq 2 no repeat masking' );
#
#system(
#	$cmd. " -masked"
#	  #. " > /dev/null 2> /dev/null" 
#);
#
#$seq_1 = 'GNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN';
#$seq_2 ='NNNNNNNNNNNCTGTCATAGA';
#
#$fastaDB = fastaDB->new( "$outpath/resulting_fastaDB.fa" );
#@values = $fastaDB->get_next();
#is_deeply( $values[1], uc($seq_1),'Seq 1 masked' );
#
#@values = $fastaDB->get_next();
#is_deeply( $values[1], uc($seq_2),'Seq 2 masked' );
#
#system(
#	$cmd. " -masked". " -bp_in_center 8"
#	  #. " > /dev/null 2> /dev/null" 
#);
#
#$fastaDB = fastaDB->new( "$outpath/resulting_fastaDB.fa" );
#$seq_1 = "NNNNNNNN";
#$seq_2 = 'NNNNNCTG';
#@values = $fastaDB->get_next();
#is_deeply( $values[1], uc($seq_1),'Seq 1 masked 8bp' );
#
#@values = $fastaDB->get_next();
#is_deeply( $values[1], uc($seq_2),'Seq 2 masked 8bp' );

sub get_chr1_seq{
	my ($start, $end, $mapped ) = @_;
	#print "I will replace with N'2 (?):$mapped\n";
my $seq = "Gaattcttttctatgatttagtttaatatgttttctgggtgtttcagctgaaacttttgtccttctttta
ttcctatttttcttaggtttggtcttttcatagtgtcccagatttcctggctgtttcttgttaggatttt
tttagatttaacatttCTGTCATAGATTAATCTATTTTGCAGATGTAATTGTATGTATTATAATTGTAAT
AGTATATACTTGTATGTACTTAAAATAttttatcatagttttcaatgcctaagattttgtctttcttctc
ttgtaatctgttggtaatgcttgcttctgtagttactgtttgcttacctagattcttcttttccagaatt
ctcttagtttgtgatgtctttattgcttctatttccattttcaggttttaaacagtttccttctcctgct
tgctttttttcttgggtttctgatattctttaaaggatttattgatttcctccaatttttaatttgcttt
tttcttgatttctttaggatatttctttttcattttcctttgaggatctctatcatcttcataaaatttg
ttttgtccttcagcggattaaaatattcaggtcttgctgtcataggttctggtggtgccatatcatgttg
gctctttttgattatgttcttacactggaggttagcaatctagggtcagataattataggtctaggtgct
gatttctgagtttttgttggatgggcgtttttggtttgtttgttttttttgtttgtttgtttgttttttc
tgtttccttttcagttttttggCTTTTGTGATCTGGATTTTTGATGGCTATCATGACCTCTGAATGACTA
GGGAATCTTGGACCACATTGGGGGCCTCTACTAGCTGTTAGCTTGGCATTTGGTACCATGCGGGGGGGGG
GGGGAGGTGTCTCTGTTCTGAGTATTATGGCCTGCACCTGTTATTCTGGCTGTTGTGGCCTGTACTTAAG
CAGGAAAGTCAAGCAGAATTGAGGGTAGGGGCCCAGCAGTGGGATAGGTGGTGAGATAGGTGGGGAGGTG
CTAGAATGGGTCTTTGGGGACTGAGTTTAGGGAGTGGGACAATTCTACTGCCAGCCAGGTGTATCACCTG
TTCTTCTCACTGGTGTGGCCTGAGTCAGAACAACTAGAGTCCTCTAGAGCTGGAGGAAGGGACTCAACAA
TGCTAGGAGTTAATAGTATGATCTCTTATGACTTTTTAGGCATTCTTAATGTTTTTATTTTCCCATCTCC
TCCCTAATTAGAGTCATTCTGGTTTTTtttttccattttttcaattagataatttgcactcttctattcc
cctctctgttactcacgtcaacttccatcccacagtggtccctttctccttctctggtttctgcggttat
tacaggatatatattcacatctgaagatttggagctaggagagagaacatagatggggtgtttttcttta
tgggtctgggttacttcactctataagatcttctcttgtttcaccaacttactggagaaaggccagatgt
ttttatattcataaagtatgattgtattgtgcatactacatttGTAGCCTTTAAAAACAACTTGTCACAG
GCATTCCAATGGACAGTAATCGTATCAATTTTATATCTATTGATAACATTTTATTCTATAGTTCAATCAC
TTATTTAATGGCTTATGTATTAAGAATTGAGAAAAACAATACtgccaagaaccagcttctgctaggagag
gggttcctgaggattgagtgtttcagaactgccagagaaatgactcaaagtcaatagtgggaacaagctg
acagctctgtgttctgcttgagctgactctctagacagctatgtggatatttcaactctgtaagaccaaa
gccaagccttgtatttatatatcaattcaatcactatcccaggttctcttttgattatcccatgagtaac
cactttatgatttaagagccttgattcatatgagaagaaagcaagtatatatatatatatatatatatat
atatatatatatatatatatacttaaacatagcaaatggattcagagatttgtctgcctttgtaagcact
gacaataaactagctatgtgggatcttgctctgagatcaccagttccaccctgcctgtcctaaactggct
tttttgcggatgacctgcctttgtgtctttttgactagctggctcattagtgtagctgcctttgttcttt
taggtccatgaagcccctcatacaattcatattgtgagaaattatgtattcttgaactcatgttttcaga
attctttcatacagtcttaagggctgtcgtgaagaccacagtgttcaccaccttgctgaggaacacctat
acacccgtgcctcctggactcatgatgtttctaattatcatagagacattgaccttggcagggagaatat
tgtttgtcacaggaacataaagtaaagtaaattatgtacattattatacaaacaagctttctgcctagca
actgtcagccatggaggcccacaccctgctagctctggtccagggatagaatggaactatgtcatgccat
ccattctgcgtggtaggactcagcaACATGTTTTCTAGTTTGTTGCTGTTTGAATTAAGACTGTGTTTAA
CATGCTTGTATATGACACTTGTTTTTTCCACATATTTCATTAAGATAACTTTATCTATTATTATACTTCA
TTTTGATTACCTAATTACTGATCAGTTCTGAGACAAGTTTTCACTTTATCTATGAAGCCCACTAGGGTGC
AGTCCTGTGCTGAACAAGTAACAATGGCCTGAGTGTGACAATGACTGAGGTGACATTCTACTTACTAGTT
CTAAAAACAGTCAGTTGTGCATGTCCATGTAGTTCAGATACTTTGTGCTGCGATTTTACTTATCATTTTT
AATCACATATTTAAAATTAAATGTAGAGAATTTGGAAGGATTATCAGAGGGAGATTTTGCTTTCATCTTA
GTCTGAACCATTGTGAAATAAGTCAGCCCCTTTAGTTCATTAATGTAAAATTGTCATTTTTTTCAACCTC
AAATTTCTTGCTTGTTTTTTTTTTTTTTTGTTTAACTCCCTTTTAGAAAATCCATAAGTGATTTATTCTT
CTGTATCTGGTTAGTGTTTATTGATTTAACTCATCCATACTACTTAGGTCTTCCATATGTCTttggtcta
";
	$seq = join("", split("\n",$seq));
	$start -= 1;
	$seq = substr ( $seq, $start, $end -$start );
	$seq =~ s/[agct]/N/g if ( $mapped );
	return $seq;
}

sub get_chr1_2_seq {
	my ($start, $end , $mapped) = @_;
	my $seq = "Agagtgctgtatctgaatgtaatgtcaaagtgtgcatctgacttataagtgacttttacacaaaactgag
gaattcatacaaaaagctaacaggaaccaactggggaaaaaaaatcaatgttaaaaactgggatcaaaag
cagccccacctaaggtcagtttattagaagccaggagcaagggcttcatgcccttgccatagttccaact
ctagtctactgtatagtccaccttccccgcaggccattgtaaattccggtgtgtgggagtgactctgcta
ttgttctaagtatttactctagttccttagggccattgtaaattcctgtgtgggagtgatgactctgcta
ttgttctaagtatttactatgtagattagccctgagattactagctctattcaagtaaattgtaatgcct
gatttctttcacctcatacaatactagaggtaattctgaatgttactgaattggtaacattcttactgaa
ttccaagctcagggtcggctcaaggactgcctaggacattggaacactggtggaaactaatctaacttag
ctatatgtcaaaatcaatcctttgaggcatttatgataaaacaatactgaaagaaagcacacagatccat
acagcccactatacaaacagggacaggtttggagcatttcttttacaggatgccattgttccaggaaaag
aagtttccctgaactattcacctggggacggcttccaagctcctgggcctgtcactactggagtgagtgt
ggcatgtgtgtgtggtgtggtttgtgtatgtgtgctgtgtgtatgtgctgtggatgtgctgtgtgtcgtg
tgcgtgtgtgtATACACACATGCATTTAGCTTCAGTGCAGGCAAACTCTTGCAGGTTTGAGTCCTTGCTT
GTCAATGTTTCATCTTGTCAAAAAGTTGGAGACTTACAGCAAGTCTGCCATtttatttatttatttattt
attttatttatttattttggtttttcgagacagggtttctctgtatagccctggttgtcctggaactcac
tttgaagaccaagctggcttcgaactcagaaatccacctgcctctaccgcccaagtgctgggattaaagg
catgcaccaccattgcccagcATGTCTGCCATTATTATTTTTCACATTCCTTCCGTTTCCTTCTTCTACA
ATGTCCCACTAGCCTTAGAGGCTCATATCTATAAATGTCTTCTACAAGGCTGAAA";
	$seq = join("", split("\n",$seq));
	$start -= 1;
	$seq = substr ( $seq, $start, $end -$start );
	$seq =~ s/[agct]/N/g if ( $mapped );
	return $seq;
}