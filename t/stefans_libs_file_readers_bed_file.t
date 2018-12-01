#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;
BEGIN { use_ok 'stefans_libs::file_readers::bed_file' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $outpath = "$plugin_path/data/output";
mkdir ( $outpath) unless ( -d $outpath );

my ( $value, @values, $exp );
my $bed_file = stefans_libs::file_readers::bed_file->new();
is_deeply(
	ref($bed_file),
	'stefans_libs::file_readers::bed_file',
	'simple test of function stefans_libs::file_readers::bed_file -> new()'
);

unless ( -f "$plugin_path/data/test_file.bed" ) {
	Carp::confess(
"Sorry but my test file '$plugin_path/data/test_file.bed' does not exist!\n"
	);
}

ok ( -f"$plugin_path/data/test_file.bed", 'infile 1' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$bed_file->read_file("$plugin_path/data/test_file.bed");
is_deeply( $bed_file->Lines(), 5, "the right number of lines" );

$bed_file = stefans_libs::file_readers::bed_file->new();
$bed_file->{'data'} = [
	[ 1, 1,   100 ],
	[ 1, 150, 250 ],
	[ 1, 400, 450 ],
	[ 1, 500, 550 ],
	[ 1, 600, 650 ],
	[ 2, 1,   2000 ]
];

$exp = [ '1', '1', '100', '1', '150', '250', '1', '400', '450', '1', '500', '550', '1', '600', '650', '2', '1', '2000' ];

#print "\$exp = ".root->print_perl_var_def([split(/[\t\n]/, $bed_file->AsString() )] ) .";\n";
is_deeply([split(/[\t\n]/, $bed_file->AsString() )], $exp, "data prints right" );

my $other_bed_file = stefans_libs::file_readers::bed_file->new();
$other_bed_file->{'data'} = [
	[ 1, 200, 300,  'geneA' ],
	[ 1, 500, 700,  'geneB' ],
	[ 1, 900, 2000, 'geneC' ],
	[ 2, 650, 700,  'geneD' ],
	[ 2, 900, 950,  'geneE' ]
];
$value = $bed_file->match_to($other_bed_file);
$exp = [ [], [0], [], [1], [1], [ 3, 4 ] ];
is_deeply( $value, $exp, ' the match_to function ' );

## And now I want to add some of the info in $other_bed_file to $bed_file 'name' column
$bed_file->add_info_to_name( $value, $other_bed_file );
is_deeply(
	$bed_file->{'data'},
	[
		[ 1, 1,   100,  '' ],
		[ 1, 150, 250,  'geneA ' ],
		[ 1, 400, 450,  '' ],
		[ 1, 500, 550,  'geneB ' ],
		[ 1, 600, 650,  'geneB ' ],
		[ 2, 1,   2000, 'geneD geneE ' ]
	],
	" add_info_to_name "
);

$other_bed_file = stefans_libs::file_readers::bed_file->new();
$other_bed_file->{'data'} = [
	[ 1, 200, 300,  'Ctcf1' ],
	[ 1, 500, 700,  'Ctcf2' ],
	[ 1, 900, 2000, 'Ctcf3' ],
	[ 2, 650, 700,  'Ctcf4' ],
	[ 2, 900, 950,  'Ctcf5' ]
];

$bed_file->add_info_to_name( $value, $other_bed_file );
is_deeply(
	$bed_file->{'data'},
	[
		[ 1, 1,   100,  '' ],
		[ 1, 150, 250,  'geneA Ctcf1 ' ],
		[ 1, 400, 450,  '' ],
		[ 1, 500, 550,  'geneB Ctcf2 ' ],
		[ 1, 600, 650,  'geneB Ctcf2 ' ],
		[ 2, 1,   2000, 'geneD geneE Ctcf4 Ctcf5 ' ]
	],
	" add_info_to_name (once more)"
);
$bed_file->Add_2_Description ( 'track type=narrowPeak visibility=3 db=hg19 name="595_3" description="0h (1) vs C1"');
$exp = [ 'track type=narrowPeak visibility=3 db=hg19 name="595_3" description="0h (1) vs C1"
1', '1', '100', '
1', '150', '250', 'geneA Ctcf1 
1', '400', '450', '
1', '500', '550', 'geneB Ctcf2 
1', '600', '650', 'geneB Ctcf2 
2', '1', '2000', 'geneD geneE Ctcf4 Ctcf5 
' ];
#print "\$exp = ".root->print_perl_var_def([split(/[\t]/, $bed_file->AsString() )] ) .";\n";
is_deeply([split(/[\t]/, $bed_file->AsString() )], $exp, "data prints right" );

$bed_file = $bed_file->calculate_on_columns ( {
	'data_column' => 'chromosome', 
	'target_column' => 'chromosome',
	'function' => sub{ return map{'chr'.$_}@_ }
});
$exp = [ 'track type=narrowPeak visibility=3 db=hg19 name="595_3" description="0h (1) vs C1"
chr1', '1', '100', '
chr1', '150', '250', 'geneA Ctcf1 
chr1', '400', '450', '
chr1', '500', '550', 'geneB Ctcf2 
chr1', '600', '650', 'geneB Ctcf2 
chr2', '1', '2000', 'geneD geneE Ctcf4 Ctcf5 
' ];
is_deeply([split(/[\t]/, $bed_file->AsString() )], $exp, "data prints right 2" );

#print $bed_file->get_pdls_4_chr( 'chr1' ); ## cool that does work!
my $bed_file_2 = $bed_file->copy();
#print $bed_file_2->get_pdls_4_chr( 'chr2' );

$bed_file->efficient_match($bed_file_2, 'test' );
$bed_file = $bed_file->drop_column('test');

#print "\$exp = ".root->print_perl_var_def($bed_file->{'header'} ).";\n";
$exp = [ 'chromosome', 'start', 'end', 'name' ];
is_deeply( $bed_file->{'header'}, $exp, "test column has been dropped");

#print "\$exp = ".root->print_perl_var_def([split(/[\t\n]/, $bed_file->AsString() )] ) .";\n";

$exp = [ 'track type=narrowPeak visibility=3 db=hg19 name="595_3" description="0h (1) vs C1"', 
'chr1', '1', '100', '', 
'chr1', '150', '250', 'geneA Ctcf1 ', 
'chr1', '400', '450', '', 
'chr1', '500', '550', 'geneB Ctcf2 ', 
'chr1', '600', '650', 'geneB Ctcf2 ', 
'chr2', '1', '2000', 'geneD geneE Ctcf4 Ctcf5 ' 
];


is_deeply([split(/[\t\n]/, $bed_file->AsString() )], $exp, 'efficient_match' );

$bed_file->print_as_table( "$outpath/test_bed.narrowPeak" );

ok ( -f "$outpath/test_bed.narrowPeak.xls" , "Test bed file  '$outpath/test_bed.narrowPeak.xls'" );

$bed_file = ref($bed_file)->new();
$bed_file -> read_file( "$plugin_path/data/test_bed.narrowPeak" );
#print "\$exp = ".root->print_perl_var_def([split(/[\t\n]/, $bed_file->AsString() )] ) .";\n";

$exp = [ 'chr1', '15980', '16126', 'e_coli_test_1_peak_1', '18', '.', '1.96097', '3.70904', '1.82123', '73', 
'chr1', '19646', '19792', 'e_coli_test_1_peak_2', '18', '.', '1.96097', '3.70904', '1.82123', '73', 
'chr1', '28825', '28971', 'e_coli_test_1_peak_3', '18', '.', '1.96097', '3.70904', '1.82123', '73', 
'chr1', '39504', '39650', 'e_coli_test_1_peak_4', '15', '.', '1.81900', '2.33404', '1.53323', '73', 
'chr1', '41262', '41408', 'e_coli_test_1_peak_5', '15', '.', '1.81900', '2.33404', '1.53323', '66', 
'chr1', '46222', '46368', 'e_coli_test_1_peak_6', '18', '.', '1.94203', '3.35974', '1.82123', '73', 
'chr1', '48299', '48445', 'e_coli_test_1_peak_7', '15', '.', '1.81900', '2.33404', '1.53323', '73', 
'chr1', '53001', '60518', 'e_coli_test_1_peak_8', '51', '.', '1.99993', '9.19993', '5.13068', '2847', 
'chr1', '65799', '65945', 'e_coli_test_1_peak_9', '15', '.', '1.81900', '2.33404', '1.53323', '73'
];

is_deeply([split(/[\t\n]/, $bed_file->AsString() )], $exp, "narrowPeak prints right" );

$bed_file = $bed_file->calculate_on_columns ( {
	'data_column' => 'chromosome', 
	'target_column' => 'chromosome',
	'function' => sub{ return map{'chr'.$_}@_ }
});
$exp = [ 'track type=narrowPeak visibility=3 db=e_coli name="e_coli_test vs e_coli_test_1" description="e_coli_test vs e_coli_test_1"
chrchr1', '15980', '16126', 'e_coli_test_1_peak_1', '18', '.', '1.96097', '3.70904', '1.82123', '73
chrchr1', '19646', '19792', 'e_coli_test_1_peak_2', '18', '.', '1.96097', '3.70904', '1.82123', '73
chrchr1', '28825', '28971', 'e_coli_test_1_peak_3', '18', '.', '1.96097', '3.70904', '1.82123', '73
chrchr1', '39504', '39650', 'e_coli_test_1_peak_4', '15', '.', '1.81900', '2.33404', '1.53323', '73
chrchr1', '41262', '41408', 'e_coli_test_1_peak_5', '15', '.', '1.81900', '2.33404', '1.53323', '66
chrchr1', '46222', '46368', 'e_coli_test_1_peak_6', '18', '.', '1.94203', '3.35974', '1.82123', '73
chrchr1', '48299', '48445', 'e_coli_test_1_peak_7', '15', '.', '1.81900', '2.33404', '1.53323', '73
chrchr1', '53001', '60518', 'e_coli_test_1_peak_8', '51', '.', '1.99993', '9.19993', '5.13068', '2847
chrchr1', '65799', '65945', 'e_coli_test_1_peak_9', '15', '.', '1.81900', '2.33404', '1.53323', '73
' ];


#print "\$exp = ".root->print_perl_var_def($value ).";\n";
