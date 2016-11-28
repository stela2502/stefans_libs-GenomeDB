#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 9;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outfile, $infile, @options,@used_cols );

my $exec = $plugin_path . "/../bin/reformat_bed_gtf_intersect.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/reformat_bed_gtf_intersect";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$infile = $plugin_path. "/data/output/annotate_bed_with_gtf_genome/annotated_bed_file_real.bed.xls";

ok ( -f $infile, "Infile exists" );
@options = ( 'A', 'B');

@used_cols = qw(gtf_seqname	gtf_source	gtf_feature	gtf_start	gtf_end	gtf_score	gtf_strand	gtf_frame	gtf_gene_id	gtf_transcript_id	gtf_gene_type	gtf_gene_status	gtf_gene_name	gtf_transcript_type	gtf_transcript_status	gtf_transcript_name	gtf_exon_number	gtf_exon_id	gtf_level	gtf_tag	gtf_transcript_support_level	gtf_havana_gene	gtf_havana_transcript	gtf_protein_id	gtf_ccdsid	gtf_length);


my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -outfile " . $outpath."/outfile"
. " -infile " . $infile 
. " -options " . join(' ', @options )
. " -used_cols ".join(" ",@used_cols)
#. " -names " # or not?
#. " -debug"
;
system( $cmd );

#print $cmd."\n";
ok ( -f $outpath."/outfile.xls" ,"outfile exists" );

my $res = data_table->new( {filename => $outpath."/outfile.xls" } );
#print "\$exp = ".root->print_perl_var_def($res->get_line_asHash(0) ).";\n";

$exp = {
  'chromosome' => 'chr1',
  'end' => '93847608',
  'gtf_ccdsid' => '---',
  'gtf_end' => '93847657',
  'gtf_exon_id' => '---',
  'gtf_exon_number' => '---',
  'gtf_feature' => 'gene',
  'gtf_frame' => '.',
  'gtf_gene_id' => 'hg38:chr1-93847572:93847657',
  'gtf_gene_name' => 'tRNA-Arg-AGA',
  'gtf_gene_status' => 'KNOWN',
  'gtf_gene_type' => 'tRNA',
  'gtf_havana_gene' => '---',
  'gtf_havana_transcript' => '---',
  'gtf_length' => '85',
  'gtf_level' => '---',
  'gtf_protein_id' => '---',
  'gtf_score' => '.',
  'gtf_seqname' => 'chr1',
  'gtf_source' => 'MANUAL',
  'gtf_start' => '93847572',
  'gtf_strand' => '+',
  'gtf_tag' => '---',
  'gtf_transcript_id' => '---',
  'gtf_transcript_name' => '---',
  'gtf_transcript_status' => '---',
  'gtf_transcript_support_level' => '---',
  'gtf_transcript_type' => '---',
  'name' => 'X',
  'orig.bed.file.col.4' => '301.667',
  'orig.bed.file.col.5' => '+',
  'orig.bed.file.col.6' => '0.000296039',
  'orig.bed.file.col.7' => '0.231056',
  'start' => '93847572'
};

is_deeply( $res->get_line_asHash(0), $exp, "tRNA selected for peak 0");


#print "\$exp = ".root->print_perl_var_def($res->GetAsArray('gtf_gene_type') ).";\n";
$exp = [ 'tRNA', 'tRNA', 'tRNA', '', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 
'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 
'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 
'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA' ];
is_deeply( $res->GetAsArray('gtf_gene_type'), $exp , "only tRNA hits selected - good?" );


@options = ( "largest", "'gtf_gene_type;gtf_gene_name'" );

$infile = $plugin_path. "/data/CGGA_bin50_ZTNBR_signif.annotated.xls";
ok ( -f $infile, "Infile exists" );

$cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -outfile " . $outpath."/outfile"
. " -infile " . $infile 
. " -options " . join(' ', @options )
. " -priority 'gtf_gene_type;exon' 'smallest'"
. " -debug"
;
system( $cmd );

$res = data_table->new( {filename => $outpath."/outfile.xls" } );
#print "\$exp = ".root->print_perl_var_def($res->get_line_asHash(0) ).";\n";

$exp = {
  'chromosome' => 'chr1',
  'end' => '629650',
  'gtf_ccdsid' => '---',
  'gtf_end' => '629570',
  'gtf_exon_id' => '---',
  'gtf_exon_number' => '---',
  'gtf_feature' => 'gene',
  'gtf_frame' => '.',
  'gtf_gene_id' => 'hg38:chr1-629498:629570',
  'gtf_gene_name' => 'tRNA-Gln-CAA_',
  'gtf_gene_status' => 'KNOWN',
  'gtf_gene_type' => 'tRNA',
  'gtf_havana_gene' => '---',
  'gtf_havana_transcript' => '---',
  'gtf_length' => '72',
  'gtf_level' => '---',
  'gtf_ont' => '---',
  'gtf_protein_id' => '---',
  'gtf_score' => '.',
  'gtf_seqname' => 'chr1',
  'gtf_source' => 'MANUAL',
  'gtf_start' => '629498',
  'gtf_strand' => '-',
  'gtf_tag' => '---',
  'gtf_transcript_id' => '---',
  'gtf_transcript_name' => '---',
  'gtf_transcript_status' => '---',
  'gtf_transcript_support_level' => '---',
  'gtf_transcript_type' => '---',
  'largest gtf_gene_name' => 'RP5-857K21.4',
  'largest gtf_gene_type' => 'lincRNA',
  'name' => 'X',
  'orig.bed.file.col.4' => '40.5',
  'orig.bed.file.col.5' => '+',
  'orig.bed.file.col.6' => '8.1829e-05',
  'orig.bed.file.col.7' => '1.79176',
  'start' => '629550'
};

is_deeply( $res->get_line_asHash(0), $exp, "tRNA selected for peak 0");

#print "\$exp = ".root->print_perl_var_def($res->get_line_asHash(5) ).";\n";
$exp = {
  'chromosome' => 'chr1',
  'end' => '633500',
  'gtf_ccdsid' => '---',
  'gtf_end' => '720200',
  'gtf_exon_id' => '---',
  'gtf_exon_number' => '---',
  'gtf_feature' => 'transcript',
  'gtf_frame' => '.',
  'gtf_gene_id' => 'ENSG00000230021.8',
  'gtf_gene_name' => 'RP5-857K21.4',
  'gtf_gene_status' => 'KNOWN',
  'gtf_gene_type' => 'lincRNA',
  'gtf_havana_gene' => 'OTTHUMG00000002331.6',
  'gtf_havana_transcript' => 'OTTHUMT00000006710.2',
  'gtf_length' => '118764',
  'gtf_level' => '2',
  'gtf_ont' => '---',
  'gtf_protein_id' => '---',
  'gtf_score' => '.',
  'gtf_seqname' => 'chr1',
  'gtf_source' => 'HAVANA',
  'gtf_start' => '601436',
  'gtf_strand' => '-',
  'gtf_tag' => 'not_best_in_genome_evidence',
  'gtf_transcript_id' => 'ENST00000440200.5',
  'gtf_transcript_name' => 'RP5-857K21.4-001',
  'gtf_transcript_status' => 'KNOWN',
  'gtf_transcript_support_level' => '5',
  'gtf_transcript_type' => 'lincRNA',
  'largest gtf_gene_name' => 'RP5-857K21.4',
  'largest gtf_gene_type' => 'lincRNA',
  'name' => 'X',
  'orig.bed.file.col.4' => '38',
  'orig.bed.file.col.5' => '+',
  'orig.bed.file.col.6' => '1.22515e-12',
  'orig.bed.file.col.7' => '2.07944',
  'start' => '633450'
};
is_deeply( $res->get_line_asHash(5), $exp, "tRNA selected for peak 5");

#print "\$exp = ".root->print_perl_var_def([@{$res->GetAsArray('gtf_gene_type')}[0..40]] ).";\n";
$exp = [ 'tRNA', 'unprocessed_pseudogene', 'unprocessed_pseudogene', 'unprocessed_pseudogene', 'lincRNA',
 'lincRNA', 'snRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'snoRNA', 'snoRNA', '', 'snoRNA', 'snoRNA',
  'snoRNA', '', 'tRNA', 'scaRNA', 'snRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 
  'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA', 'tRNA' ];


is_deeply( [@{$res->GetAsArray('gtf_gene_type')}[0..40]], $exp , "only tRNA hits selected - good?" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";