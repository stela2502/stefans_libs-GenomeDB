#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
BEGIN { use_ok 'stefans_libs::file_readers::gtf_file' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $test_object, $value, $exp, @values );
$test_object = stefans_libs::file_readers::gtf_file->new();
is_deeply(
	ref($test_object),
	'stefans_libs::file_readers::gtf_file',
	'simple test of function stefans_libs::file_readers::gtf_file -> new()'
);

$value = $test_object->AddDataset(
	{
		'seqname' => 0,
		'source'  => 1,
		'feature' => 2,
		'start'   => 3,
		'end'     => 4,
		'score'   => 5,
		'strand'  => 6,
		'frame'   => 7,
		'attribute' =>
		  'gene_id "GAFFER"; something_else "1 2 3"; and_more "nothing"',
	}
);
is_deeply( $value, 1, "we could add a sample dataset" );

ok ( 0 == $test_object->get_chr_subID_4_start( 1 ),"chr slice id for start ==1 " );
ok ( 0 == $test_object->get_chr_subID_4_start( 999999 ),"chr slice id for start ==999999 " );
ok ( 1 == $test_object->get_chr_subID_4_start( 1000000 ),"chr slice id for start ==1000000 " );


#print "\$exp = ".root->print_perl_var_def( [ split(/[\t\n]/,$test_object->AsString() )] ).";\n";
$exp = [
	'#', '0', '1', '2', '3', '4', '5', '6', '7',
	'gene_id "GAFFER"; something_else "1 2 3"; and_more "nothing"'
];
is_deeply( [ split( /[\t\n]/, $test_object->AsString() ) ],
	$exp, "data read as expected (test)" );

#$test_object->After_Data_read();

my $infile = "$plugin_path/data/test.gtf";

$test_object = stefans_libs::file_readers::gtf_file->new();
$test_object->read_file($infile);
$test_object->After_Data_read();

$exp = {
  'attribute' => 'gene_id "ENSG00000223972.5"; gene_type "transcribed_unprocessed_pseudogene"; gene_status "KNOWN"; gene_name "DDX11L1"; level 2; havana_gene "OTTHUMG00000000961.2"',
  'end' => '14409',
  'exon_id' => undef,
  'exon_number' => undef,
  'feature' => 'gene',
  'frame' => '.',
  'gene_id' => 'ENSG00000223972.5',
  'gene_name' => 'DDX11L1',
  'gene_status' => 'KNOWN',
  'gene_type' => 'transcribed_unprocessed_pseudogene',
  'havana_gene' => 'OTTHUMG00000000961.2',
  'havana_transcript' => undef,
  'level' => '2',
  'score' => '.',
  'seqname' => 'chr1',
  'source' => 'HAVANA',
  'start' => '11869',
  'strand' => '+',
  'tag' => undef,
  'transcript_id' => undef,
  'transcript_name' => undef,
  'transcript_status' => undef,
  'transcript_support_level' => undef,
  'transcript_type' => undef
};


#print "\$exp = ".root->print_perl_var_def( $test_object->get_line_asHash(0) ).";\n";

is_deeply( $test_object->get_line_asHash(0),
	$exp, "a real world file has been parsed as expected (1st line)" );

#print "\$exp = ".root->print_perl_var_def( $test_object->get_line_asHash( 5) ).";\n";

$exp = {
  'attribute' => 'gene_id "ENSG00000223972.5"; transcript_id "ENST00000456328.2"; gene_type "transcribed_unprocessed_pseudogene"; gene_status "KNOWN"; gene_name "DDX11L1"; transcript_type "processed_transcript"; transcript_status "KNOWN"; transcript_name "DDX11L1-002"; exon_number 3; exon_id "ENSE00002312635.1"; level 2; tag "basic"; transcript_support_level "1"; havana_gene "OTTHUMG00000000961.2"; havana_transcript "OTTHUMT00000362751.1"',
  'end' => '14409',
  'exon_id' => 'ENSE00002312635.1',
  'exon_number' => '3',
  'feature' => 'exon',
  'frame' => '.',
  'gene_id' => 'ENSG00000223972.5',
  'gene_name' => 'DDX11L1',
  'gene_status' => 'KNOWN',
  'gene_type' => 'transcribed_unprocessed_pseudogene',
  'havana_gene' => 'OTTHUMG00000000961.2',
  'havana_transcript' => 'OTTHUMT00000362751.1',
  'level' => '2',
  'score' => '.',
  'seqname' => 'chr1',
  'source' => 'HAVANA',
  'start' => '13221',
  'strand' => '+',
  'tag' => 'basic',
  'transcript_id' => 'ENST00000456328.2',
  'transcript_name' => 'DDX11L1-002',
  'transcript_status' => 'KNOWN',
  'transcript_support_level' => '1',
  'transcript_type' => 'processed_transcript'
};


is_deeply( $test_object->get_line_asHash(5),
	$exp, "a real world file has been parsed as expected (last line)" );

#print "\$exp = ".root->print_perl_var_def( $test_object->{'header'} ).";\n";
$exp = [ 'seqname', 'source', 'feature', 'start', 'end', 'score', 'strand', 'frame', 'attribute', 'gene_id', 'gene_type', 'gene_status', 'gene_name', 'level', 'havana_gene', 'transcript_id', 'transcript_type', 'transcript_status', 'transcript_name', 'tag', 'transcript_support_level', 'havana_transcript', 'exon_number', 'exon_id' ];
is_deeply ( $test_object->{'header'}, $exp ,'right header info');

#print "\$exp = ".root->print_perl_var_def( $test_object->{'header_position'} ).";\n";
$exp = {
  'attribute' => '8',
  'end' => '4',
  'exon_id' => '23',
  'exon_number' => '22',
  'feature' => '2',
  'frame' => '7',
  'gene_id' => '9',
  'gene_name' => '12',
  'gene_status' => '11',
  'gene_type' => '10',
  'havana_gene' => '14',
  'havana_transcript' => '21',
  'level' => '13',
  'score' => '5',
  'seqname' => '0',
  'source' => '1',
  'start' => '3',
  'strand' => '6',
  'tag' => '19',
  'transcript_id' => '15',
  'transcript_name' => '18',
  'transcript_status' => '17',
  'transcript_support_level' => '20',
  'transcript_type' => '16'
};
is_deeply ( $test_object->{'header_position'}, $exp ,'right header info');
ok( $test_object->{'__max_header__'} == 24, "internal Max_Header \$test_object ($test_object->{'__max_header__'})" );


$value = $test_object->select_where('feature', sub { $_[0] eq "exon"});

is_deeply(
	ref($value),
	'stefans_libs::file_readers::gtf_file',
	'select_where returns a  stefans_libs::file_readers::gtf_file'
);

is_deeply( $value->get_line_asHash(0), $test_object->get_line_asHash(2), 'dropped all but exons' );
#$value->{'__max_header__'} = 24;
ok( $value->{'__max_header__'} == 24, "internal Max_Header subset ($value->{'__max_header__'})" );

print "The pdl should just not throw any errors...\n";
print $value->get_pdls_4_chr('chr1');

# A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

