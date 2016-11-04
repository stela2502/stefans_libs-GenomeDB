#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 9;
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
$outfile = "$outpath/annotated_bed_file.bed";
$infile  = $plugin_path . "/data/test_file.bed";
ok( -f $infile, "infile ($infile)" );

$gtf = $plugin_path . "/data/test.gtf";

if ( -f '/home/stefanl/nobackup/genomes/human/hg38/gencode.v24.annotation.gtf' )
{
#$gtf ='/home/stefanl/nobackup/genomes/human/hg38/gencode.v24.annotation.gtf'; ## BIIGGG
}
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
  . " -options "
  . join( ' ', @options ) . " -gtf " . $gtf 
  #. " -debug"
  ;

#print $cmd."\n";
system($cmd );

ok( -f $outfile.".xls", "outfile #1 created" );
ok( -f $outfile.".2.xls", "outfile #2 created" );
ok( -f $plugin_path . "/data/test_file.annotated.xls", 'outfile #3 reated' );

my $t = data_table->new( { 'filename' => $outfile.".xls" } );

#print "\$exp = ".root->print_perl_var_def( $t->get_line_asHash( 0) ).";\n";
$exp = {
  'chromosome' => 'chr1',
  'end' => '41648811',
  'gtf_attribute' => 'ENSG00000223972.5',
  'gtf_end' => '41649811',
  'gtf_feature' => 'exon',
  'gtf_frame' => '.',
  'gtf_gene_id' => 'ENST00000456328.2',
  'gtf_gene_name' => 'DDX11L1',
  'gtf_gene_status' => 'KNOWN',
  'gtf_gene_type' => 'transcribed_unprocessed_pseudogene',
  'gtf_havana_gene' => undef,
  'gtf_level' => 'processed_transcript',
  'gtf_score' => '.',
  'gtf_seqname' => 'chr1',
  'gtf_source' => 'HAVANA',
  'gtf_start' => '41642425',
  'gtf_strand' => '+',
  'name' => '',
  'start' => '41648425'
};
is_deeply( $t->get_line_asHash(0),
	$exp, "outfile single feature match" );

$value = $t->get_line_asHash( 1);
#print "\$exp = ".root->print_perl_var_def( $t->get_line_asHash( 1) ).";\n";
$exp = {
  'chromosome' => 'chr1',
  'end' => '43632992',
  'gtf_attribute' => undef,
  'gtf_end' => undef,
  'gtf_feature' => undef,
  'gtf_frame' => undef,
  'gtf_gene_id' => undef,
  'gtf_gene_name' => undef,
  'gtf_gene_status' => undef,
  'gtf_gene_type' => undef,
  'gtf_havana_gene' => undef,
  'gtf_level' => undef,
  'gtf_score' => undef,
  'gtf_seqname' => "No information about this area on chromosome 'chr1' in the other file",
  'gtf_source' => undef,
  'gtf_start' => undef,
  'gtf_strand' => undef,
  'name' => $value->{'name'},
  'start' => '43632534'
};
is_deeply( $t->get_line_asHash(1),
	$exp, "outfile no match" );
	
#print "\$exp = ".root->print_perl_var_def( $t->get_line_asHash( 2) ).";\n";
$exp = {
  'chromosome' => 'chr10',
  'end' => '2607294',
  'gtf_attribute' => 'ENSG00000223972.5 // ENSG00000223972.52',
  'gtf_end' => '2609294 // 2609294',
  'gtf_feature' => 'exon // exon',
  'gtf_frame' => '. // .',
  'gtf_gene_id' => 'ENST00000456328.2 // ENST00000456328.22',
  'gtf_gene_name' => 'DDX11L1 // DDX11L12',
  'gtf_gene_status' => 'KNOWN // KNOWN',
  'gtf_gene_type' => 'transcribed_unprocessed_pseudogene // transcribed_unprocessed_pseudogene',
  'gtf_havana_gene' => ' // ',
  'gtf_level' => 'processed_transcript // processed_transcript',
  'gtf_score' => '. // .',
  'gtf_seqname' => 'chr10 // chr10',
  'gtf_source' => 'HAVANA // HAVANA',
  'gtf_start' => '2602004 // 2602004',
  'gtf_strand' => '+ // +',
  'name' => $value->{'name'},
  'start' => '2603004'
};
is_deeply( $t->get_line_asHash(2),
	$exp, "outfile two features match" );

#print $t ->AsString();

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
