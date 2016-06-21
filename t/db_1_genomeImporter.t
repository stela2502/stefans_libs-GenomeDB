#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
use File::HomeDir;
BEGIN { use_ok 'stefans_libs::database::genomeDB::genomeImporter' }
my $home = File::HomeDir->my_home();

use FindBin;
my $plugin_path = "$FindBin::Bin";

## test for new

#warn "we do not test the download capabilites of this lib - that would take too much time and bandwidth ;-)";

open( DB, ">$home/create_test.db" )
  or die "could not create file $home/create_test.db\n";
print DB "create database geneexpress;\n";
close(DB);
open( DB, ">$home/drop_test.db" )
  or die "could not drop file $home/create_test.db\n";
print DB "drop database geneexpress;\n";
close(DB);

#system("mysql -uroot -palmdiR < $home/drop_test.db");
#system("mysql -uroot -palmdiR < $home/create_test.db");

my ( $value, @values );

my $genomeImporter = genomeImporter->new("geneexpress");
is_deeply( ref($genomeImporter), 'genomeImporter',
	'simple test of function genomeImporter -> new()' );

$genomeImporter->{databaseDir} = "$plugin_path/data";
$genomeImporter->{'noDownload'} = 1; # I have artificial files here!
$genomeImporter->import_refSeq_genome_for_organism("hu_genome");

my $genomeDB = genomeDB->new( variable_table->getDBH() );

#$genomeDB ->printReport();

my $chromsomesTable = $genomeDB->GetDatabaseInterface_for_Organism("hu_genome");

my $helper = $chromsomesTable->get_chr_calculator();

$value =
  [ $helper->gbFile_2_chromosome( 1, 1, 821 ) ];    # ID( undef, 'Y', 1, 821 );

is_deeply(
	$value,
	[ 'chrY', 1, 821 ],
	"I get the gbFile location on the chromosome!"
);

$value = $chromsomesTable->get_Columns(
	{ 'search_columns' => ['gbString'] },
	{
		'start'      => 1,
		'end'        => 34821,
		'chromosome' => 'Y'
	}
);

is_deeply(
	$value,
	[
		'     source          1..34821
                     /mol_type="genomic DNA"
                     /organism="Homo sapiens"
                     /db_xref="taxon:9606"
                     /chromosome="Y"
'
	],
"we can execute horribly complex searches using 'getArray_of_Array_for_search' "
);

$value = $chromsomesTable->get_chromosomal_region( 'chrY', 5, 967557 );

my $str = '';

my $exp = [
	'     gene            110310..112812',
	'                     /db_xref="GeneID:677739"',
	'                     /db_xref="HGNC:31847"',
	'                     /gene="CXYorf11"',
	'                     /note="chromosome X and Y open reading frame 11"',
	'     gene            132991..160020',
	'                     /db_xref="GeneID:55344"',
	'                     /db_xref="HGNC:23148"',
	'                     /gene="PLCXD1"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: BestRefseq. Supporting evidence',
	'                     includes similarity to: 1 mRNA"',
	'     gene            complement(161426..170887)',
	'                     /db_xref="GeneID:8225"',
	'                     /db_xref="HGNC:30189"',
	'                     /db_xref="MIM:300124"',
	'                     /gene="GTPBP6"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: BestRefseq. Supporting evidence',
	'                     includes similarity to: 1 mRNA"',
	'     gene            complement(214970..267627)',
	'                     /db_xref="GeneID:28227"',
	'                     /db_xref="HGNC:13417"',
	'                     /db_xref="MIM:300339"',
	'                     /gene="PPP2R3B"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: BestRefseq. Supporting evidence',
	'                     includes similarity to: 2 mRNAs"',
	'     gene            complement(314638..321773)',
	'                     /db_xref="GeneID:100132231"',
	'                     /gene="LOC100132231"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            411242..426592',
	'                     /db_xref="GeneID:100132931"',
	'                     /gene="LOC100132931"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            430733..431810',
	'                     /db_xref="GeneID:100131063"',
	'                     /gene="LOC100131063"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            complement(435060..447636)',
	'                     /db_xref="GeneID:100132419"',
	'                     /gene="LOC100132419"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            505079..540146',
	'                     /db_xref="GeneID:6473"',
	'                     /db_xref="HGNC:10853"',
	'                     /db_xref="MIM:312865"',
	'                     /gene="SHOX"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: BestRefseq. Supporting evidence',
	'                     includes similarity to: 2 mRNAs"',
	'     gene            543615..553913',
	'                     /db_xref="GeneID:100132233"',
	'                     /gene="LOC100132233"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            complement(641903..662454)',
	'                     /db_xref="GeneID:100132334"',
	'                     /gene="LOC100132334"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            834110..840111',
	'                     /db_xref="GeneID:100132123"',
	'                     /gene="LOC100132123"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            877093..889906',
	'                     /db_xref="GeneID:100133010"',
	'                     /gene="LOC100133010"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"',
	'     gene            complement(889945..890836)',
	'                     /db_xref="GeneID:100132757"',
	'                     /gene="LOC100132757"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: GNOMON. Supporting evidence includes',
	'                     similarity to: 1 Protein"'
];

foreach ( @{ $value->Features() } ) {
	$str .= $_->getAsGB() if ( $_->Tag() eq "gene" );
}
$str = [ sort split( "\n", $str ) ];
#print "\$exp = " . root->print_perl_var_def($str) . ";\n";
is_deeply ( $str, [ sort @{$exp}], "All genes were imported as expected");

is_deeply ( $value->Get_SubSeq( 34821, 34823), 'ANN', 'first chromosomal breakpoint' );
is_deeply ( $value->Get_SubSeq( 84820, 84822), 'NNG', 'second chromosomal breakpoint' );
is_deeply ( $value->Get_SubSeq( 171384, 171386), 'CNN', 'third chromosomal breakpoint' );
is_deeply ( $value->Get_SubSeq( 201383, 201385), 'NNG', 'fourth chromosomal breakpoint' );

#print "\$exp = " . root->print_perl_var_def($str) . ";\n";
