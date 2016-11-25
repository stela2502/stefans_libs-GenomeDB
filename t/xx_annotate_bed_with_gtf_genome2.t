#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 13;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::file_readers::gtf_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outfile, $infile, @options, $gtf, );

my $exec = $plugin_path . "/../bin/annotate_bed_with_gtf_genome.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/annotate_bed_with_gtf_genome";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}
mkdir($outpath);
$outfile = "$outpath/annotated_bed_file_real.bed";
$infile  = $plugin_path . "/data/test_real.bed";
ok( -f $infile, "infile ($infile)" );

$gtf = $plugin_path . "/data/test_real.gtf";

ok( -f $gtf, "gtf file ($gtf)" );

@options = ('exon');
my $gtf_file = stefans_libs::file_readers::gtf_file->new();
$gtf_file->read_file($gtf);
$gtf_file =  $gtf_file->select_where( 'feature', sub { $_[0] eq $options[0]  } );

#print $gtf_file ->AsTestString();

@options = ( 'gtf_feature', 'exon' );

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
  . " -outfile "
  . $outfile. " ". $outfile.".2"
  . " -infile "
  . $infile. " ". $infile. " ". $infile
  . " -options ''"
  . " -gtf " . $gtf 
  #. " -debug"
  ;

#print $cmd."\n";
system($cmd );

ok( -f $outfile.".xls", "outfile #1 created" );
ok( -f $outfile.".2.xls", "outfile #2 created" );
ok( -f $plugin_path . "/data/test_file.annotated.xls", 'outfile #3 reated' );

my $t = data_table->new( { 'filename' => $outfile.".xls" } );


$value = $t->get_line_asHash( 29 );
#print "\$exp = ".root->print_perl_var_def( $value ).";\n";

#the first entry:
#chr2	HAVANA	gene	27042364	27070622	.	+	.	gene_id "ENSG00000084693.15"; gene_type "protein_coding"; gene_status "KNOWN"; gene_name "AGBL5"; level 1; havana_gene "OTTHUMG00000128406.7";

#the second entry  consits of this: 
#chr2	MANUAL	gene	27050781	27050871	.	+	.	gene_id "hg38:chr2-27050781:27050871"; gene_type "tRNA"; gene_status "KNOWN"; gene_name "tRNA-Tyr-TAC";

ok ( $value->{'gtf_seqname'} eq "chr2 // chr2" , "gtf_seqname ($value->{'gtf_seqname'})");
ok ( $value->{'gtf_source'} eq "HAVANA // MANUAL", "gtf_source ($value->{'gtf_source'})" );

ok ( $value->{'gtf_frame'} eq ". // .", "the last predefined variable ($value->{'gtf_frame'})" );

ok ( $value->{'gtf_gene_id'} eq "ENSG00000084693.15 // hg38:chr2-27050781:27050871", "the first of the complex data (gene_id ='$value->{'gtf_gene_id'}')" );
ok ( $value->{'gtf_gene_name'} eq "AGBL5 // tRNA-Tyr-TAC", "the gtf_gene_name (last defined in the tRNA) '$value->{'gtf_gene_name'}'" );
ok ( $value->{'gtf_level'} eq "1 // ", "the first not defined in the tRNA (level = '$value->{'gtf_level'}') " );

$exp = {
  'chromosome' => 'chr2',
  'end' => '27050832',
  'gtf_ccdsid' => ' // ',
  'gtf_end' => '27070622 // 27050871',
  'gtf_exon_id' => ' // ',
  'gtf_exon_number' => ' // ',
  'gtf_feature' => 'gene // gene',
  'gtf_frame' => '. // .',
  'gtf_gene_id' => 'ENSG00000084693.15 // hg38:chr2-27050781:27050871',
  'gtf_gene_name' => 'AGBL5 // tRNA-Tyr-TAC',
  'gtf_gene_status' => 'KNOWN // KNOWN',
  'gtf_gene_type' => 'protein_coding // tRNA',
  'gtf_havana_gene' => 'OTTHUMG00000128406.7 // ',
  'gtf_havana_transcript' => ' // ',
  'gtf_level' => '1 // ',
  'gtf_protein_id' => ' // ',
  'gtf_score' => '. // .',
  'gtf_seqname' => 'chr2 // chr2',
  'gtf_source' => 'HAVANA // MANUAL',
  'gtf_start' => '27042364 // 27050781',
  'gtf_strand' => '+ // +',
  'gtf_tag' => ' // ',
  'gtf_transcript_id' => ' // ',
  'gtf_transcript_name' => ' // ',
  'gtf_transcript_status' => ' // ',
  'gtf_transcript_support_level' => ' // ',
  'gtf_transcript_type' => ' // ',
  'name' => 'X',
  'orig.bed.file.col.4' => '508.667',
  'orig.bed.file.col.5' => '+',
  'orig.bed.file.col.6' => '1.1625E-12',
  'orig.bed.file.col.7' => '0.828306',
  'start' => '27050760'
};
is_deeply( $value, $exp , "the whole first line is OK" );


#print "\$exp = ".root->print_perl_var_def($value ).";\n";
