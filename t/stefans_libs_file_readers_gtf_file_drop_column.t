#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok 'stefans_libs::file_readers::gtf_file' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $test_object, $value, $exp, @values );
$test_object = stefans_libs::file_readers::gtf_file->new();


my $infile = $plugin_path."/data/test_real.gtf";
ok ( -f $infile, "infile $infile" );
$test_object->read_file($infile);

$exp = [ 'seqname', 'source', 'feature', 'start', 'end', 'score', 'strand', 'frame', 'attribute', 'gene_id', 'transcript_id', 'gene_type', 'gene_status', 'gene_name', 'transcript_type', 'transcript_status', 'transcript_name', 'exon_number', 'exon_id', 'level', 'tag', 'transcript_support_level', 'havana_gene', 'havana_transcript', 'protein_id', 'ccdsid' ];

is_deeply( $test_object->{'header'}, $exp, "the object header" );

#$test_object-> write_file ( $plugin_path."/data/processed_gtf_file.xls" ) unless ( -f  $plugin_path."/data/processed_gtf_file.xls");

my $dropped = $test_object->drop_column('attribute');

ok ( ref($dropped) eq "stefans_libs::file_readers::gtf_file", "still a stefans_libs::file_readers::gtf_file");

$exp = [ 'seqname', 'source', 'feature', 'start', 'end', 'score', 'strand', 'frame', 'gene_id', 'transcript_id', 'gene_type', 'gene_status', 'gene_name', 'transcript_type', 'transcript_status', 'transcript_name', 'exon_number', 'exon_id', 'level', 'tag', 'transcript_support_level', 'havana_gene', 'havana_transcript', 'protein_id', 'ccdsid' ];

is_deeply( $dropped->{'header'}, $exp, "the dropped object header" );

my $required = {
	gene_id                  => "ENSG00000260464.1",
	transcript_id            => "ENST00000565336.1",
	gene_type                => "lincRNA",
	gene_status              => "KNOWN",
	gene_name                => "RP4-561L24.3",
	transcript_type          => "lincRNA",
	transcript_status        => "KNOWN",
	transcript_name          => "RP4-561L24.3-001",
	exon_number              => 1,
	exon_id                  => "ENSE00002588542.1",
	level                    => 2,
	tag                      => "basic",
	transcript_support_level => "NA",
	havana_gene              => "OTTHUMG00000175883.1",
	havana_transcript        => "OTTHUMT00000431234.1"
};




$value = $test_object->get_line_asHash(0);

$exp = { map{ $_ => $value->{$_} } keys %$required };
print "\$exp = ".root->print_perl_var_def( $exp ).";\n";


is_deeply( $exp, $required, "the complex data has been parsed right" );

$value = $dropped->get_line_asHash(0);
$exp = { map{ $_ => $value->{$_} } keys %$required };
is_deeply( $exp, $required, "the data is unchanged by the drop_column" );

#print "\$exp = ".root->print_perl_var_def( $test_object->get_line_asHash(0) ).";\n";

$exp = {
#  'attribute' => 'gene_id "ENSG00000260464.1"; transcript_id "ENST00000565336.1"; gene_type "lincRNA"; gene_status "KNOWN"; gene_name "RP4-561L24.3"; transcript_type "lincRNA"; transcript_status "KNOWN"; transcript_name "RP4-561L24.3-001"; exon_number 1; exon_id "ENSE00002588542.1"; level 2; tag "basic"; transcript_support_level "NA"; havana_gene "OTTHUMG00000175883.1"; havana_transcript "OTTHUMT00000431234.1"',
  'ccdsid' => '',
  'end' => '93848939',
  'exon_id' => 'ENSE00002588542.1',
  'exon_number' => '1',
  'feature' => 'exon',
  'frame' => '.',
  'gene_id' => 'ENSG00000260464.1',
  'gene_name' => 'RP4-561L24.3',
  'gene_status' => 'KNOWN',
  'gene_type' => 'lincRNA',
  'havana_gene' => 'OTTHUMG00000175883.1',
  'havana_transcript' => 'OTTHUMT00000431234.1',
  'level' => '2',
  'protein_id' => '',
  'score' => '.',
  'seqname' => 'chr1',
  'source' => 'HAVANA',
  'start' => '93847174',
  'strand' => '+',
  'tag' => 'basic',
  'transcript_id' => 'ENST00000565336.1',
  'transcript_name' => 'RP4-561L24.3-001',
  'transcript_status' => 'KNOWN',
  'transcript_support_level' => 'NA',
  'transcript_type' => 'lincRNA'
};

is_deeply( $dropped->get_line_asHash(0), $exp, "the whole first line is unchecnged and the annotation finally dropped" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
