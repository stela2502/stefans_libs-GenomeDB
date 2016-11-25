#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outfile, $infile, @options, );

my $exec = $plugin_path . "/../bin/reformat_bed_gtf_intersect.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/reformat_bed_gtf_intersect";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$infile = $plugin_path. "/data/output/annotate_bed_with_gtf_genome/annotated_bed_file_real.bed.xls";

@options = ( 'A', 'B');

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -outfile " . $outpath."/outfile"
. " -infile " . $infile 
. " -options " . join(' ', @options )
. " -names " # or not?
. " -debug";
system( $cmd );

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


$cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -outfile " . $outpath."/outfile"
. " -infile " . $infile 
. " -options " . join(' ', @options )
. " -priority 'gtf_gene_type;exon' 'smallest'"
. " -debug";
system( $cmd );

$res = data_table->new( {filename => $outpath."/outfile.xls" } );
print "\$exp = ".root->print_perl_var_def($res->get_line_asHash(0) ).";\n";

is_deeply( $res->get_line_asHash(0), $exp, "tRNA selected for peak 0");

print "\$exp = ".root->print_perl_var_def($res->GetAsArray('gtf_gene_type') ).";\n";

is_deeply( $res->GetAsArray('gtf_gene_type'), $exp , "only tRNA hits selected - good?" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";