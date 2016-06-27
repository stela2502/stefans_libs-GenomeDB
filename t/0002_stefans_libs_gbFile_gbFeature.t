#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 19;
BEGIN { use_ok 'stefans_libs::gbFile::gbFeature' }
use stefans_libs::root;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = gbFeature->new( 'tag', '1..2' );
is_deeply( ref($OBJ), 'gbFeature',
	'simple test of function stefans_libs::gbFile::gbFeature -> new() ' );

ok( $OBJ->isMultilineStart( 'some crap " and some more crap', '"', '"' ),
	"multiline start \'" );
ok(
	$OBJ->isMultilineStart( 'some crap " and some more crap"', '"', '"' ) == 0,
	"multiline stop \'"
);

ok( $OBJ->isMultilineStart( 'some crap ( and some more crap"', '(', ')' ),
	"multiline start (" );
ok(
	$OBJ->isMultilineStart( 'some crap ( and some more crap)', '(', ')' ) == 0,
	"multiline stop ()"
);
$value = $OBJ->isMultilineStart( 'some crap ( (and some more crap"', '(', ')' );
ok( $value == 2, "two brackets == +2" );
$value += $OBJ->isMultilineStart( 'The closing ones: ))"', '(', ')' );
ok( $value == 0, "+ closing brackets sum up to 0" );

## now try a multi line region

$value = $OBJ->isMultilineStart( 'comlement(join(1..2,3..4,"', '(', ')' );
ok( $value == 2, "first line did add 2 to the opening brackets" );
$value += $OBJ->isMultilineStart( '3..5,6..8,9..10,', '(', ')' );
ok( $value == 2, "second line did not change the opening brackets" );
$value += $OBJ->isMultilineStart( '3..5,6..8,9..10)', '(', ')' );
ok( $value == 1, "third line did change the opening brackets to 1" );
$value += $OBJ->isMultilineStart( ')', '(', ')' );
ok( $value == 0, "fourth line set brackets to 0" );

my @tests = (
	'     CDS             complement(join(435459..435781,435906..436005,
                     443266..443460))
                     /gene="LOC439957"
                     /codon_start=1
                     /pseudo
                     /product="similar to hCG1742442"
                     /protein_id="XP_001716757.1"
                     /db_xref="GI:169217347"
                     /db_xref="GeneID:439957"',
	'     ncRNA           join(<12788761..>12788797,<12791047..>12791061,
                     <12794939..12795183)
                     /gene="LINC01194"
                     /gene_synonym="TAG"
                     /ncRNA_class="lncRNA"
                     /product="long intergenic non-protein coding RNA 1194"
                     /inference="similar to RNA sequence (same
                     species):RefSeq:NR_033383.1"
                     /exception="annotated by transcript or proteomic data"
                     /note="The RefSeq transcript has 9 substitutions and 1
                     indel and aligns at 47% coverage compared to this genomic
                     sequence; Derived by automated computational analysis
                     using gene prediction method: BestRefSeq."
                     /transcript_id="NR_033383.1"
                     /db_xref="GI:291045142"
                     /db_xref="GeneID:404663"
                     /db_xref="HGNC:37171"',

);

$OBJ->parseFromString( $tests[0] );

#print "\$exp = "  . root->print_perl_var_def( { map { $_ => $OBJ->{$_} } 'information', 'tag' } ) . ";\n";
$exp = {
	'tag'         => 'CDS',
	'information' => {
		'pseudo'      => [],
		'codon_start' => ['1'],
		'protein_id'  => ['"XP_001716757.1"'],
		'db_xref'     => [ '"GI:169217347"', '"GeneID:439957"' ],
		'product'     => ['"similar to hCG1742442"'],
		'gene'        => ['"LOC439957"']
	}
};
is_deeply( { map { $_ => $OBJ->{$_} } 'information', 'tag' },
	$exp, "load test 1" );

#print "\$exp = "  . root->print_perl_var_def( [ split( "\n", $OBJ->getAsGB() ) ] ) . ";\n";

$exp = [ split( "\n", $tests[0] ) ];

is_deeply( [ split( "\n", $OBJ->getAsGB() ) ], $exp, "getAsGB(1)" );

$OBJ = $OBJ->new( 'x', '1..2' );

$OBJ->parseFromString( $tests[1] );

#print "\$exp = ".root->print_perl_var_def( { map {$_ => $OBJ->{$_}} 'information', 'tag' } ).";\n";

$exp = {
	'information' => {
		'gene'          => ['"LINC01194"'],
		'product'       => ['"long intergenic non-protein coding RNA 1194"'],
		'transcript_id' => ['"NR_033383.1"'],
		'db_xref' => [ '"GI:291045142"', '"GeneID:404663"', '"HGNC:37171"' ],
		'ncRNA_class' => ['"lncRNA"'],
		'inference' =>
		  ['"similar to RNA sequence (same species):RefSeq:NR_033383.1"'],
		'note' => [
'"The RefSeq transcript has 9 substitutions and 1 indel and aligns at 47% coverage compared to this genomic sequence; Derived by automated computational analysis using gene prediction method: BestRefSeq."'
		],
		'gene_synonym' => ['"TAG"'],
		'exception'    => ['"annotated by transcript or proteomic data"']
	},
	'tag' => 'ncRNA'
};

is_deeply( { map { $_ => $OBJ->{$_} } 'information', 'tag' },
	$exp, "load test 1" );

#print "\$exp = "
#  . root->print_perl_var_def( [ split( "\n", $OBJ->getAsGB() ) ] ) . ";\n";
$exp = [ split( "\n", $tests[1] ) ];

is_deeply( [ split( "\n", $OBJ->getAsGB() ) ], $exp, "getAsGB(2)" );

$tests[2] = '     misc_RNA        complement(join(302112..302516,306690..306826,
                     307714..307822,311607..311756,312599..312705,
                     330589..330764,343350..343477,344592..344734,
                     347239..347409,348344..348350))
                     /gene="LOC100128190"
                     /product="similar to NHE domain-containing 1 protein"
                     /note="Derived by automated computational analysis using
                     gene prediction method: GNOMON. Supporting evidence
                     includes similarity to: 9 ESTs, 3 Proteins"
                     /pseudo
                     /transcript_id="XR_037566.1"
                     /db_xref="GI:169217343"
                     /db_xref="GeneID:100128190"';

$OBJ = $OBJ->new( 'x', '1..2' );

#$OBJ->{'debug'} = 1;
$OBJ->parseFromString( $tests[2] );

$exp = [ split( "\n", $tests[2] ) ];
is_deeply( [ split( "\n", $OBJ->getAsGB() ) ], $exp, "getAsGB(3)" );

#print "\$exp = ".root->print_perl_var_def(  [split( "\n", $OBJ->getAsGB(302112) ) ] ).";\n";
$exp = [
'     misc_RNA        complement(join(<1..404,4578..4714,5602..5710,9495..9644,',
	'                     10487..10593,28477..28652,41238..41365,42480..42622,',
	'                     45127..45297,46232..46238))',
	'                     /gene="LOC100128190"',
'                     /product="similar to NHE domain-containing 1 protein"',
'                     /note="Derived by automated computational analysis using',
	'                     gene prediction method: GNOMON. Supporting evidence',
	'                     includes similarity to: 9 ESTs, 3 Proteins"',
	'                     /pseudo',
	'                     /transcript_id="XR_037566.1"',
	'                     /db_xref="GI:169217343"',
	'                     /db_xref="GeneID:100128190"'
];
is_deeply( [ split( "\n", $OBJ->getAsGB(302112) ) ],	$exp, "getAsGB() changed positions 1" );

@$exp[2] = '                     45127..>45297))';
is_deeply( [ split( "\n", $OBJ->getAsGB(302112,347409 ) ) ],	$exp, "getAsGB() changed positions 1" );


#print "\$exp = ".root->print_perl_var_def( { map {$_ => $OBJ->{$_}} 'information', 'tag' } ).";\n";

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

