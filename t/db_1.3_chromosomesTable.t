#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::gbFile;
use Test::More tests => 29;
BEGIN { use_ok 'stefans_libs::database::genomeDB' }
use stefans_libs::file_readers::bed_file;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $genomeDB     = genomeDB->new( variable_table::getDBH() );
my $gbFilesTable =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( 'hu_genome',
	'36.3' );
$gbFilesTable->{'debug'} = 1;
my $test_obj = $gbFilesTable->get_chr_calculator();

is_deeply(
	ref($test_obj),
	'chromosomesTable::gbFile_to_chromosome',
	'get the right object type (chromosomesTable::gbFile_to_chromosome)'
);

is_deeply(
	$test_obj->{'data'}->AsString(),
"#gbFile_id\tchromosome\tstart\tend\n1\tY\t1\t34821\n2\tY\t84822\t171384\n3\tY\t201385\t967557\n",
	"the data is as expected"
);

is_deeply(
	[ $test_obj->gbFile_2_chromosome( 1, 1, 100 ) ],
	[ 'chrY', 1, 100 ],
	'gbFile_2_chromosome'
);

is_deeply(
	[ $test_obj->gbFile_2_chromosome( 2, 300, 570 ) ],
	[ 'chrY', 84821 + 300, 84821 + 570 ],
	'gbFile_2_chromosome #2'
);

is_deeply(
	[ $test_obj->Chromosome_2_gbFile( 'Y', 1, 100 ) ],
	[ [ 1, 1, 100 ] ],
	'Chromosome_2_gbFile'
);
is_deeply(
	[ $test_obj->Chromosome_2_gbFile( 'chrY', 1, 100 ) ],
	[ [ 1, 1, 100 ] ],
	'Chromosome_2_gbFile using chrY instead of Y'
);

is_deeply(
	[ $test_obj->Chromosome_2_gbFile( 'Y', 100, 84821 + 570 ) ],
	[ [ 1, 100, 34822 ], [ 2, 1, 570 ] ],
	'Chromosome_2_gbFile'
);

use stefans_libs::database::ROI_registration;
my $test = ROI_registration->new( variable_table::getDBH() );
$test->create();

$gbFilesTable = $gbFilesTable->get_rooted_to("gbFilesTable");
my $ROI_table = $gbFilesTable->Connect_2_result_ROI_table();
$ROI_table->create();
is_deeply ( $ROI_table->TableName(), 'hu_genome_36_3_ROI_table', 'the repeat table name');
my $data_file = stefans_libs::file_readers::bed_file->new();
$data_file->{'data'} = [ [ 'chrY', 1, 100 ], [ 'chrY', 100, 84821 + 570 ] ];
$data_file->write_file("$plugin_path/data/temp_data.bed");

system( "perl -I $plugin_path/../lib "
	  . root->perl_include()
	  . " $plugin_path/import_bed_file.t -organism  hu_genome -version '36.3' -bed_file $plugin_path/data/temp_data.bed -ROI_tag test_tag -ROI_name test_name -source_description 'just a test' "
);
my $value = $test->get_data_table_4_search(
	{
		'search_columns' => [ 'cmd', 'ROI_name', 'ROI_tag' ],
		'where' => [ [ 'genome_id', '=', 'my_value' ] ],
	},
	1
);
#print $value->AsString();

is_deeply(
	[ @{ @{ $value->{'data'} }[0] }[ 1 .. 2 ] ],
	[ 'test_name', 'test_tag' ],
	'ROI_registration was updated'
);

$value = $ROI_table->get_data_table_4_search(
	{
		'search_columns' => ['*'],
		'where'          => [],
	},
);

my $exp = [
'#hu_genome_36_3_ROI_table.gbFile_id	hu_genome_36_3_ROI_table.md5_sum	hu_genome_36_3_ROI_table.gbString	'.
'hu_genome_36_3_ROI_table.name	hu_genome_36_3_ROI_table.end	hu_genome_36_3_ROI_table.tag'.
'	hu_genome_36_3_ROI_table.id	hu_genome_36_3_ROI_table.start',
	'1	f19fab42a9464da45bc85edb7be4ba5d	     test_tag        1..100',
	'                     /bed_entry="chrY 1 100 "',
	'                     /gene="test_name"',
	'	test_name	100	test_tag	1	1',
	'1	86f9dd7a3a00ec55acbc43b72e6d6196	     test_tag        100..34822',
	'                     /bed_entry="chrY 100 85391 "',
	'                     /gene="test_name"',
	'	test_name	34822	test_tag	2	100',
	'2	51fccbdfbbf3ed5cd5bacf19e8d6d638	     test_tag        1..570',
	'                     /bed_entry="chrY 100 85391 "',
	'                     /gene="test_name"',
	'	test_name	570	test_tag	3	1'
];
is_deeply( [ split( "\n", $value->AsString() ) ], $exp, "import_bed_file.pl" );

$exp = [
	'     test_tag        1..100',
	'                     /bed_entry="chrY 1 100 "',
	'                     /gene="test_name"',
	'     test_tag        100..34822',
	'                     /bed_entry="chrY 100 85391 "',
	'                     /gene="test_name"',
	'     test_tag        1..570',
	'                     /bed_entry="chrY 100 85391 "',
	'                     /gene="test_name"'
];
my @values = @{ $ROI_table->get_ROI_as_gbFeature( { 'id' => [ 1, 2, 3 ] } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {id} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'tag' => 'test_tag' } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {tag} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'name' => 'test_name' } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {name} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'name' => 'test_name', 'tag' => 'test_tag' } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {tag AND name} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'name' => 'test_name', 'tag' => 'test_tag', 'gbFile_id' => 2 } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
$exp = [ @$exp[6..8]];
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {tag AND name AND gbFile_id} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'id'=> [1,2,3], 'gbFile_id' => 2 } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {id AND gbFile_id } )" );


$gbFilesTable = $gbFilesTable->get_rooted_to("gbFilesTable");
$ROI_table = $gbFilesTable->Connect_2_REPEAT_ROI_table();
$ROI_table->create();
is_deeply ( $ROI_table->TableName(), 'hu_genome_36_3_repeat_ROI_table', 'the repeat table name');
$data_file = stefans_libs::file_readers::bed_file->new();
$data_file->{'data'} = [ [ 'chrY', 1, 100 ], [ 'chrY', 100, 84821 + 570 ] ];
$data_file->write_file("$plugin_path/data/temp_data.bed");

system( "perl -I $plugin_path/../lib "
	  . root->perl_include()
	  . " $plugin_path/import_repeat_summary_file.t -organism  hu_genome -version '36.3' -infile $plugin_path/data/temp_repeat_fa.out -source 'just a repeat test' -force"
);
#print "I exectued the command\n"."perl -I $plugin_path/../lib "
#	  . root->perl_include()
#	  . " $plugin_path/import_repeat_summary_file.t -organism  hu_genome -version '36.3' -infile $plugin_path/data/temp_repeat_fa.out -source 'just a repeat test' \n";
$value = $test->get_data_table_4_search(
	{
		'search_columns' => [ 'cmd', 'ROI_name', 'ROI_tag' ],
		'where' => [ [ 'genome_id', '=', 'my_value' ] ],
	},
	1
);
#print $value->AsString();

is_deeply(
	[ @{ @{ $value->{'data'} }[1] }[ 1 .. 2 ] ],
	[ 'repeatmasker', 'repeat' ],
	'ROI_registration was updated'
);

$exp = [
'#hu_genome_36_3_repeat_ROI_table.gbFile_id	hu_genome_36_3_repeat_ROI_table.md5_sum	hu_genome_36_3_repeat_ROI_table.gbString	'.
'hu_genome_36_3_repeat_ROI_table.name	hu_genome_36_3_repeat_ROI_table.end	hu_genome_36_3_repeat_ROI_table.tag'.
'	hu_genome_36_3_repeat_ROI_table.id	hu_genome_36_3_repeat_ROI_table.start',
	'1	02427ef253d1474d7c3a47ec744db598	     repeat          1..100',
	'                     /repeat_class="Simple_repeat"',
	'                     /gene="(CCCTAA)n"',
	'	(CCCTAA)n	100	repeat	1	1',
	'1	97386159049be69235d10d1fc7d69228	     repeat          102..34822',
	'                     /repeat_class="Satellite/telo"',
	'                     /gene="TAR1"',
	'	TAR1	34822	repeat	2	102',
	'2	1a67f4e15e51acff0669222b32cc99ef	     repeat          1..570',
	'                     /repeat_class="Satellite/telo"',
	'                     /gene="TAR1"',
	'	TAR1	570	repeat	3	1'
];
$value = $ROI_table->get_data_table_4_search(
	{
		'search_columns' => ['*'],
		'where'          => [],
	},
);
is_deeply( [ split( "\n", $value->AsString() ) ], $exp, "import_bed_file.pl" );


$exp = [
	'     repeat          1..100',
	'                     /repeat_class="Simple_repeat"',
	'                     /gene="(CCCTAA)n"',
	'     repeat          102..34822',
	'                     /repeat_class="Satellite/telo"',
	'                     /gene="TAR1"',
	'     repeat          1..570',
	'                     /repeat_class="Satellite/telo"',
	'                     /gene="TAR1"',
];
@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'id' => [ 1, 2, 3 ] } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {id} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'tag' => 'repeat' } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {tag} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'name' =>  ['(CCCTAA)n', 'TAR1'] } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {name} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'name' =>  ['(CCCTAA)n', 'TAR1'], 'tag' => 'repeat' } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {tag AND name} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'name' => ['(CCCTAA)n', 'TAR1'], 'tag' => 'repeat', 'gbFile_id' => 2 } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
$exp = [ @$exp[6..8]];
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {tag AND name AND gbFile_id} )" );

@values = @{ $ROI_table->get_ROI_as_gbFeature( { 'id'=> [1,2,3], 'gbFile_id' => 2 } ) };
$value = '';
foreach (@values) {
	$value .= $_->getAsGB() ;
}
is_deeply ([ split( "\n", $value ) ], $exp, "get_ROI_as_gbFeature ( {id AND gbFile_id } )" );

## now I check whether I can get the masked gbFile from the database!

my $gbFeaturesTable =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( 'hu_genome',
	'36.3' );

$value = $gbFeaturesTable -> get_masked_gbFile_for_gbFile_id ( 1 );

#print  "The sequence:".$value -> {'seq'}. "\n";
is_deeply ( $value -> Get_SubSeq( 100,102), 'NCN', 'the breakpoint #1 of the masked sequences is OK');

$value = $gbFeaturesTable -> get_masked_gbFile_for_gbFile_id ( 2 );
is_deeply ( $value -> Get_SubSeq( 569,571), 'NNC', 'the breakpoint #2 of the masked sequences is OK');

$value = $ROI_table->get_ROI_as_bed_file ({'name' =>  ['(CCCTAA)n', 'TAR1'], 'tag' => 'repeat' } );
$exp = [ '#chromosome', 'start', 'end', 'chrY', '1', '100', 'chrY', '102', '34822', 'chrY', '84822', '85391' ];
is_deeply ( [ split( /[\n\t]/ ,$value->AsString() )], $exp, "ROI_table->get_ROI_as_bed_file()");
#print "\$exp = ".root->print_perl_var_def([ split( /[\n\t]/ ,$value->AsString() )] ).";\n";

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

