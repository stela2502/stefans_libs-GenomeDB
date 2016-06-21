#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 12;
use stefans_libs::root;
BEGIN { use_ok 'stefans_libs::database::genomeDB::gbFeaturesTable' }
use stefans_libs::database::genomeDB::gbFilesTable;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";


my $gbFeaturesTable =
  gbFeaturesTable->new( variable_table::getDBH( 'root', "geneexpress" ) );
is_deeply( ref($gbFeaturesTable), 'gbFeaturesTable',
	'simple test of function gbFeaturesTable -> new()' );

## test for new

my ( $value, @values, $gbFeature, $gbFeature_str );

## test for new

## test for TableName

$value = $gbFeaturesTable->TableName("hu_genome_36_3" );

is_deeply( $value, "hu_genome_36_3_gbFeaturesTable",
	"table base name is created correctly" );

#root::print_hashEntries( $gbFeaturesTable->_getLinkageInfo(),
#	10, "the linkage info of " . ref($gbFeaturesTable) );

$gbFeature_str =
  '      CDS             complement(join(76920..77043,79206..79358,79578..79726,
                     83265..83473,84612..84770,85996..86066))
                     /db_xref="GI:6912588"
                     /db_xref="GeneID:8225"
                     /db_xref="HGNC:30189"
                     /db_xref="MIM:300124"
                     /protein_id="NP_036359.1"
                     /exception="unclassified translation discrepancy"
                     /gene="GTPBP6"
                     /product="pseudoautosomal GTP-binding protein-like
                     protein"
                     /GO_function="GTP binding [GO ID 0005525] [Evidence TAS]
                     [PMID 9466997]"
                     /GO_component="intracellular [GO ID 0005622] [Evidence
                     IEA]"
                     /note="pseudoautosomal GTP-binding protein-like;
                     pseudoautosomal GTP binding protein-like"';

$gbFeature = gbFeature->new( "nix", "1..100" );
$gbFeature->parseFromString($gbFeature_str);

#$gbFeaturesTable->AddDataset(
#	{ 'gbFile' => { 'id' => 1 }, 'gbFeature' => $gbFeature } );

my $name = $gbFeature->Name();
if ( defined $name ) {
	$name =~ s/"//g;
}
$value =
  $gbFeaturesTable->get_gbFeatures( { 'tag' =>$gbFeature->Tag, 'name' =>  $name} );
@{$gbFeature -> {information}->{gene}}[0] = '"GTPBP6"';
#print @$value[0]->getAsGB();
is_deeply(
	$value,
	[ $gbFeature  ],
	"get_gbFeatures"
);

my $secondFeature_str =
  '     mRNA            complement(85996..>86066)
                     /db_xref="GI:6912587"
                     /db_xref="GeneID:8225"
                     /db_xref="HGNC:30189"
                     /db_xref="MIM:300124"
                     /exception="unclassified transcription discrepancy"
                     /gene="HUGO"
                     /product="GTP binding protein 6 (putative)"
                     /transcript_id="NM_012227.1"
                     /note="Derived by automated computational analysis using
                     gene prediction method: BestRefseq. Supporting evidence
                     includes similarity to: 1 mRNA"

';
my $secondGbFeature = gbFeature->new( "nix", "1..100" );
$secondGbFeature->parseFromString($secondFeature_str);


my $filename = "../t/data/hu_genome/originals/NT_113968.1.gb";
$filename = "t/data/hu_genome/originals/NT_113968.1.gb" if ( -f "t/data/hu_genome/originals/NT_113968.1.gb" );
unless ( -f $filename) { system ( "ls -lh" ); }

my $gbFile = gbFile->new($filename);
$gbFile ->{'path'} = $gbFile ->{'filename'} =undef;  ## nore does it know the path or filename...
$gbFile ->{'header'}->{'gbText'} = [split("\n", $gbFile ->{'header'}->{'gbText'})];
$gbFile ->Features();
#$gbFile ->{'features'} = []; ## this database does not read all the features....

$value = $gbFeaturesTable->get_gbFile_for_acc( 'NT_113968.1' );
#$value ->{'features'} = []; ## this database does not read all the features....
#$value->{feature_locations} = undef;
$value ->{'header'}->{'gbText'} = [split("\n", $value ->{'header'}->{'gbText'})];

is_deeply ( $value->Name(),$gbFile->Name() , "Got the right gbFile 'name'");
is_deeply ( scalar ( @{$value->Features()} ), scalar( @{$gbFile ->Features($gbFile ->{'features'})}), 'got the same number of features' );

is_deeply( $value, $gbFile, "got the right gbfile");

$value = $gbFeaturesTable->get_as_bed_file ( {'tag' => 'gene'} );
my $exp = "#chromosome	start	end	name
chrY	110310	112812	CXYorf11
chrY	132991	160020	PLCXD1
chrY	161426	170887	GTPBP6
chrY	214970	267627	PPP2R3B
chrY	314638	321773	LOC100132231
chrY	411242	426592	LOC100132931
chrY	430733	431810	LOC100131063
chrY	435060	447636	LOC100132419
chrY	505079	540146	SHOX
chrY	543615	553913	LOC100132233
chrY	641903	662454	LOC100132334
chrY	834110	840111	LOC100132123
chrY	877093	889906	LOC100133010
chrY	889945	890836	LOC100132757
";
is_deeply ( $value->AsString( ), $exp, 'get_as_bed_file({tag})');
$value->calculate_on_columns ( {
	'data_column' => 'start', 
	'target_column' => 'start',
	'function' => sub{return $_[0] - 5000 }
});
$value->calculate_on_columns ( {
	'data_column' => 'start', 
	'target_column' => 'end',
	'function' => sub{return $_[0] + 7000 }
});
## complements: LOC100132757 (14) LOC100132334 (11) LOC100132231(4) PPP2R3B (3) GTPBP6 (2)
@{$value->{'data'}}[2] = [ 'chrY',168887,175887, 'GTPBP6'];
@{$value->{'data'}}[3] = [ 'chrY',265627,272627, 'PPP2R3B' ];
@{$value->{'data'}}[7] = [ 'chrY', 447636- 2000,447636 + 5000, 'LOC100132419'];
@{$value->{'data'}}[4] = [ 'chrY',321773 - 2000, 321773+5000, 'LOC100132231' ];
@{$value->{'data'}}[10] = [ 'chrY',662454 - 2000, 662454+5000, 'LOC100132334' ];
@{$value->{'data'}}[13] = [ 'chrY',890836 - 2000, 890836+5000, 'LOC100132757' ];
$value->calculate_on_columns ( {
	'data_column' => 'name', 
	'target_column' => 'name',
	'function' => sub{return $_[0]. "_promotor" }
});
$exp = $value->AsString();
$value = $gbFeaturesTable->get_as_bed_file ( {'tag' => 'gene', 's_start' => 5000, 's_end' => 2000 } );
is_deeply ( [split("\n",$value->AsString( )) ], [split("\n",$exp)], 'get_as_bed_file({tag, s_start })');

$value = $gbFeaturesTable->get_as_bed_file ( {'tag' => 'gene'} );
$value->calculate_on_columns ( {
	'data_column' => 'end', 
	'target_column' => 'start',
	'function' => sub{return $_[0] - 5000 }
});

$value->calculate_on_columns ( {
	'data_column' => 'start', 
	'target_column' => 'end',
	'function' => sub{return $_[0] + 7000 }
});

@{$value->{'data'}}[2] = [ 'chrY',161426 - 2000,161426 +5000, 'GTPBP6'];
@{$value->{'data'}}[3] = [ 'chrY',214970 - 2000, 214970+5000, 'PPP2R3B' ];
@{$value->{'data'}}[7] = [ 'chrY',435060 - 2000,435060 + 5000, 'LOC100132419'];
@{$value->{'data'}}[4] = [ 'chrY',314638 - 2000,314638 +5000, 'LOC100132231' ];
@{$value->{'data'}}[10] = [ 'chrY',641903 - 2000,641903 +5000, 'LOC100132334' ];
@{$value->{'data'}}[13] = [ 'chrY',889945 - 2000,889945 +5000, 'LOC100132757' ];
$value->calculate_on_columns ( {
	'data_column' => 'name', 
	'target_column' => 'name',
	'function' => sub{return $_[0]. "_mRNA_stop" }
});
$exp = $value->AsString();
$value = $gbFeaturesTable->get_as_bed_file ( {'tag' => 'gene', 'e_start' => 5000, 'e_end' => 2000 } );
is_deeply ( [split("\n",$value->AsString( )) ], [split("\n",$exp)], 'get_as_bed_file({tag, e_start })');

## check get_chromosomal_region

$value = $gbFeaturesTable->get_chromosomal_region ( 'Y', 161426 - 2000, 161426 +5000 );
$exp = [ 'LOCUS       Y:159426..166426       7001 bp  DNA    linear', 'DEFINITION  the chromosomal region Y:159426..166426', 'ACCESSION   Y:159426..166426', 'FEATURES             Location/Qualifiers', '     source          84821..>166426', '                     /mol_type="genomic DNA"', '                     /db_xref="taxon:9606"', '                     /chromosome="Y"', '                     /organism="Homo sapiens"', '     gene            132990..160019', '                     /db_xref="GeneID:55344"', '                     /db_xref="HGNC:23148"', '                     /gene="PLCXD1"', '                     /note="Derived by automated computational analysis using', '                     gene prediction method: BestRefseq. Supporting evidence', '                     includes similarity to: 1 mRNA"', '     mRNA            join(132990..133060,138148..138350,140833..140980,', '                     145399..145535,147314..147442,148165..148320,149701..149884,', '                     155763..156058,159259..160019)', '                     /db_xref="GI:94158612"', '                     /db_xref="GeneID:55344"', '                     /db_xref="HGNC:23148"', '                     /gene="PLCXD1"', '                     /product="phosphatidylinositol-specific phospholipase C, X', '                     domain containing 1"', '                     /transcript_id="NM_018390.2"', '                     /note="Derived by automated computational analysis using', '                     gene prediction method: BestRefseq. Supporting evidence', '                     includes similarity to: 1 mRNA"', '     gene            complement(161425..>166426)', '                     /db_xref="GeneID:8225"', '                     /db_xref="HGNC:30189"', '                     /db_xref="MIM:300124"', '                     /gene="GTPBP6"', '                     /note="Derived by automated computational analysis using', '                     gene prediction method: BestRefseq. Supporting evidence', '                     includes similarity to: 1 mRNA"', '     mRNA            complement(join(161425..161863,164026..164178,', '                     164398..164546))', '                     /db_xref="GI:6912587"', '                     /db_xref="GeneID:8225"', '                     /db_xref="HGNC:30189"', '                     /db_xref="MIM:300124"', '                     /exception="unclassified transcription discrepancy"', '                     /gene="GTPBP6"', '                     /product="GTP binding protein 6 (putative)"', '                     /transcript_id="NM_012227.1"', '                     /note="Derived by automated computational analysis using', '                     gene prediction method: BestRefseq. Supporting evidence', '                     includes similarity to: 1 mRNA"', '     STS             161454..161615', '                     /db_xref="UniSTS:99581"', '     CDS             complement(join(161740..161863,164026..164178,', '                     164398..164546))', '                     /db_xref="GI:6912588"', '                     /db_xref="GeneID:8225"', '                     /db_xref="HGNC:30189"', '                     /db_xref="MIM:300124"', '                     /exception="unclassified translation discrepancy"', '                     /protein_id="NP_036359.1"', '                     /gene="GTPBP6"', '                     /GO_component="intracellular [GO ID 0005622] [Evidence', '                     IEA]"', '                     /GO_function="GTP binding [GO ID 0005525] [Evidence TAS]', '                     [PMID 9466997]"', '                     /product="pseudoautosomal GTP-binding protein-like', '                     protein"', '                     /note="pseudoautosomal GTP-binding protein-like;', '                     pseudoautosomal GTP binding protein-like"', 'ORIGIN', '   159426 AGACGGGGTT TCACCATGTT GGCCAGGCTG GTCTCGATCT CCTGACCTCA GGTGATCCAC', '   159486 CCGCCTCGGC CTCCCAAAGT GCTGGGATGA CAGGCGTGAG CCACCGCGCC CGGCCTATAC', '   159546 CTCATTTTCT ACATGTCGCT TGTTGGAGCT GCTGGTTCAA GTTCCCAGCC AGCCAATGGA', '   159606 TGCCAGCACC ATTTTTACTC CCCTTTCCCA AGCAAATCGT GCATTTTTGT CTAACGAGAG', '   159666 ACATCAGTTT CTCAGGATGA TCCTCAAGAA CGTTATGGAG TCCATGTTGC AATAGGTTCT', '   159726 CTTTGGGACC TAATGACTCA TTTTCCAAAA ATCCGCTTCT ACTTTTGGTA CCCGGTTGCT', '   159786 ACGGTGAAAT GAAGGTGCCC CGCATCCAGA AAGACGCACT CCTGGACCAC AACCGGCGGC', '   159846 TACCTCAGCC CCACGGCTCT GCAGGATCAG GGCTCGGGCA GGCCCCGCGG AGATGAAGAA', '   159906 TTTGCAGGGA GCCTCCCTGA CTTCCGTCGG CTGTGAATCC TTGTCTGTCA GGGGCGTATC', '   159966 CACAAAATCA CCGAATTCAT ACAGATCGTT TAAATAAATG AACATCATTA AAGTCAAATA', '   160026 TGAGTATGAA TTTTATTACC ACCAATGCAG CCAAGACACC TCTGGCAGCT TTCAGGATAG', '   160086 CACGCCAGAA GCATCTTTAG AAAATGTTAA TTCAGGAGGC CGGGTGCGGT GGCTCACGCC', '   160146 TGTAATCCCA GCACTTTGGG AGGCCGAGGT GGGCGGATCA CAAGGTCAAG AGTTCGAGAC', '   160206 CAGCCTGACC GACATGGTGA AAATACAAAA AATTACTAAA TATACAAAAA TAATATATAA', '   160266 ATTATAAATA TATAAGAATA CTAAAAATAT AAAAAATTAG CCAGGCATGG TGGTGGGGGC', '   160326 CTGTAGTCCC AGCTACTCAA GAGGCTGAGG CAGGAGAATG GTGTGAACCC GGGAGGCGGA', '   160386 GCTTGCAGTG AGCCGAGACT GCACCACTGC ACTCCAGCCT GGATGACAGA GTGACACTCA', '   160446 TTCCGTCTAA AAAAAAAAAA AAAAGTTAAT TCAGGCCGGG CACAGTGGCT CCGCCTGTAA', '   160506 TCCCAGCACT TTGGGAGGCC GAGTTGGGTG GATCACCTGA GGTCAGGAGT TTGAGACCAG', '   160566 CCTGACCGAC ATGCTGAAAA CCCATCTCTA CTAAAAATGC AAAAAATTAG CCGGGCGTGG', '   160626 TGGCGGGCGC CTGTAATCCC AGCTACTTGG GAGGTTGAGG CAGGAGAACT GTCTGAACTC', '   160686 AAGAGGCAGA GGTTGCAGTG AACTGAGATC GCACCACTGT ACTCCAGCCT GGGTGACAGA', '   160746 GCGAGATTCT GTCTCAAAAC ATACAAGGCA TTTTGTTTTC CCGTTGATGG AGACGGCTAA', '   160806 TGTGCGTGTA ACGGCTGCAC AGCCTGGCCA CACGCAGGTG AAATTCTCTC TCTGCATCTC', '   160866 TTAGTGGATG GTCTGTGACA CATCACCGTC TGGTTTGTTT GTTTTGAGAC GGAGTCTCGC', '   160926 TCTGTCTTCC AGGCTGGAGT GCAGTGGCGC GATCTTGGCT CACTGCAACC TCCGCCTCCC', '   160986 GGGTTCATGC CATCCTCCTG CCTCAGCCTC CCGAGTAGCT GGGACTACAG GCGCCCGCCA', '   161046 CCACCCCCGG CTAATTTTTT GTATTTTTAG CAGAGGTGGG GTTTCACCAT GTTAGCCAGG', '   161106 ATGGTCTGGA TCTCCTGACC TCGTGATCCA CCCACCTCAG CCTCTCAAAG TGCTGGGATT', '   161166 ACAGGCGTGA GCCACCGTGC CCGTCCTCAC GGTCTGGTTT GAAGCTGCTT CTTTAGTAAA', '   161226 ACTATTTGCT TTCCCTTCTA CTTTTGTGGA AGGGTTCTCT GTGCTGCCGG GAAACCTGAT', '   161286 TTTTCGTCAT TTCCCCGACA CCACCATGGG AAACGAGACC ATCTGTGAAC ACAGACAGCC', '   161346 GGGCGGAGGG GCCGTCGGTG CCCACCAGGG CCACGGCTCA CGGCAGGTGC AGGAGGAACT', '   161406 GGAAATGCTG CTCACGGAAG TAAAATCAAA GGTTTAATGT CCTGTTACGG AAACATTCCG', '   161466 AGGGAAAGCA GTTCACAGCA GGCACCGAGG GCCCACTGGA ATTGTGTGGA TGCTCAGGCT', '   161526 TGGAGTGGAC GCTCGGGCGG CCCGCTTTGG GGCAGGTGCG GCCGTGTCAC CGGCCTGCAC', '   161586 GGTCATCCCA GCAAATGGCT GGGAGCGAGA CGGGTGCAGA ACCAGACAAG GAGGACCCTG', '   161646 CTGCACCTGA CACCAAGCTG CCCCCAACAC AGCGGTAACG CCTCAGCTCC CCAGGCAGCG', '   161706 ATGCCCCCAC CCCGCAGGCC TCTGTGGGCG TCCGTTCATC CTGGAAAGAG CTTCCGGAAT', '   161766 TTGCCGTAGG CTGAGTTGCT GATGATGACC CTCACGTCGG CCGCCCCGTC CTCAGGGATC', '   161826 ACGTCCACCT CCTGAACTGT GGCCTCCTTA TACAGCCAGC TGGGCACAGA TGCGCGTTGT', '   161886 ATGGAGACAA GCAGAACCCG TAAGTATTTG CTTAGTTTCA TGATAAATAA TTACGCTAAA', '   161946 AAGAGCTTAG CTCAAACCAT TCATCAGACC GTCCTGTTTC CTTTTGTTTT TTTTTTTTTT', '   162006 TGAGACGGAG TCTCACTCTG TCGCGTAGGC TGGAGTGCAG TGGCGCGATC TCAGCTCACT', '   162066 GCAAGCTCCA CCTCCCGGGT TCAAGTGATT CTCCTGCCTC AGCCTCCCGA GTAGCTGGGA', '   162126 CTACAGGTGC ATGCCACCAC ACCTGGCTAA TTTTTTGTGT TTTTAGTAGA GACGGGGTTT', '   162186 CACCGTGTTA GCCAGGATGG TCTCGATCTC CTGACTTCGT GATCCACCCG CCTCGGCCTC', '   162246 CCAAAGTGCT GGGATGACAG GCATGAGCCA CTGCGCCCGG CTTTTTATTT TTTATTTTTT', '   162306 TTTTTGAGAC AGAGTCTCGC TCTGTCGCCA GGCTGGGGTG CAGTGGCACG ATCTTGGCTC', '   162366 ACTGCAACCT CGGCCTCCTG GGTTCCAGCA ATTCTCCGGC CTTAGCCTCC CGAGTAGCTG', '   162426 GGACTACAGG TGCCCGCCAC TGCGCCCGGC TAATTTTTTG TATTTTTATT AGAGACGGGG', '   162486 TTTCACCGTG TTAGCCAGGC TGGTCTCGAT CTCCTGACCT TGTGGTCCGC CCACCTCGGC', '   162546 CTCCCAACGT GTTGGGATTA CAGGTGTGAG CCACCCCACC TGGGGTGGTA ACTTTTTATT', '   162606 CTTTGTAGAG ATGGGGTCTC ACCATGTTGC CCAGCCTGGC CTCAAACTCC TCTCAGCTCA', '   162666 AGCAATCCTC CTGCCTCGGC CTCCCAAAGT CTTGGGGTTA CAGGCCTGTG CCACGGCATC', '   162726 CAGCTGGAGC TTGCTTTCTT ATTGGTAGGG AGACCTGTAC CCCTTGACTG GCAGCACAGA', '   162786 TTAGGCACCT GTTGTGCGCA CAGTCAGAAA TGTATTTTGA CTGTCAAGTG CAGATTAGGC', '   162846 ACCTGTTGTA TGCAGTCAGA AATGTACATT TTGACTGTCA AGCGCAGATT AGGCACCTGT', '   162906 TGTATGCAGT CAGAAATGTA CATTTTGACT GTCAGCACAG ATTAGGCACC TGTTGTATGC', '   162966 ACAGTCAGAA ATGTACATTT TGACTGTCAG TGCAGATTAG GCACCTGTTG TATGCACAGA', '   163026 AATGTACATT TTGGCTGTCA AGCACAGATT AGGCACCTGT TGTATGGTCA GAAATGTACA', '   163086 TTTTCACTGT CAGCATAATT AGGCACCTGT TGTATCCACA GTCAGAAATG TACATTGAGT', '   163146 GTCAGCACAC ATTAGGCACC TGTTGTATGC ACAGTCAGAA ATGTACATTT TGTCAGCACA', '   163206 GATTAGGCAA CTGTTGTATG CAGTCAGAAA TGTATTTTTA CTGTCAAGCA CAGATTAGGC', '   163266 ACCTGTTGTA TGCAGTCAGA AATGTACATT TTGACTGTCA GCACAGATTA GGCACCTGTT', '   163326 GTATGCAGTC AGAAATGTAC ATTTTGACTG TCAGTGCAGA TTAGGCACCT GTTGTATGCA', '   163386 CAGAAATGTA CATTTTGGCT GTCAAGCACA GATTAGGCAC CTGTTGTATG GTCAGAAATG', '   163446 TACATTTTCA CTGTCAGCAT AATTAGGCAC CTGTTGTATC CACAGTCAGA AATGTATATT', '   163506 TTGAGTGTCA GCACAGATTA GGCACCTGTT GTATGCAGTC AGAAATGTAC ATTTTGACTG', '   163566 TCAGCACAGA TTAGGCACCT GTTGTATGCA GTCAGAAATG TACATTTTGA CTGTCAGCAC', '   163626 AGATTAGGCA CCTGTTGTAT GCAGTCAGAA ATGTACATTT TGACTGTCAA GCACAGATTA', '   163686 GGCAACTGTT GTATGCAGTC AGAAATGTAT TTTTACTGTC AAGCACAGAT TAGGCACCCG', '   163746 TTGTATGCAG TCAGAAATGT ACATTTTGAC TGTCAGCACA GATTAGGCAC CTGTTGTATG', '   163806 CACAGTCACA AATGTAGATT TTGACTCTCA AGCGCAGATT AGGCACCTCT TGTATGCACA', '   163866 GTCACAAATG TACATTTGAT GCAAACCCAT TCATCTCGTC TGTACATCCT AAAGCTCTCG', '   163926 GGGATCTCAC AGCTCCTTGT GCACCCACGA AGAGCCCGTT TCAGAGCCAG AGACAGGCAT', '   163986 CCAAAGCACC ATCCCGTCTC CTGCCCCTGC AGGCCGCTCA CCTGAGCTGC GCCCCTGCGA', '   164046 GCCTCACACG GAGAGTGAGG ATCTGTCTCC CCGTCGCCTT CAAAACCGCC GCATCGAGCT', '   164106 CAGCTTTCAG CTCCTGGAGC CCGTGGCCCC GCAGGGCAGA CACGGGCACG ACGTTCGGTT', '   164166 CCGTGGGGCT GTACCTGCAA GGGTGGGGAT GTCACAGGCC CCGCTCAGCG TCGGGGCGGC', '   164226 CGGACGAAAT CAGGGTCCCC AGGAGTCCAC TGCCCACGGG GCACAGTCTG GGGCCACTCC', '   164286 CTGTGTCCTG ACTGCCACCG CTGCGGTTCA CACGAGGAGA CGGGGCATCT CCCCACCCGG', '   164346 CTCCAGCGCG TGCAGGGGAA GGAGACGCTT GCGGACCCCA GGGCCGGACT CACCCGGGCA', '   164406 CGAGGTCCAC CTTGTTGTGA ACCTCCACCA TGGAGTCCAG GAGCGGGGCG GGCAGCTGCA', '   164466 GGCCACGCAG CGTGGACAGA ACGCTGCATT TCTGGAGCTC CGCCTCGGGG TGGCTGACGT', '   164526 CCCTCACGTG CAAGATGAGA TCCTGTGGGC CGGGCCGTGG GGTCAGAGCT GCGGAGCCTC', '   164586 TGGTCCCTGA CCCCAAGCTT GCAGACAGGC CCAGGAGAGG GGCTCACACG AGCTCCCAAC', '   164646 GACAGGCTGG GCATGGGAGG TACGCCTGTG TGCAGGCCCC TCGGACACCC CAGGACGGGG', '   164706 GCTCCTAGAC CAACAGTGGA CGCGAGCCCA CCCGGCTGCA CTTACCCAAC CTTCCAAGCC', '   164766 ACAGGCAGCA GCTCCGCACC CCCAGACCCA CACGCAAGGG GGTGCCATAT ATGAGCACCC', '   164826 AACCACCACC CACCCACCCA GGGGGTCTTC ATTCAAAGCT TTAGGGCGGC TTCATCCTCC', '   164886 TGTGAAATGT CTTTTAACAG CGGAATTATT TCCTCTTTAA AGGATGCTTT TTTTCTCACG', '   164946 TTCAAAAAAA ATCTTACAGG CAGGCTCCTT ACACAAAATT TGAAAAACAC AGGGAAAAAA', '   165006 AAATAAAGCC GTGTGTAATT CTCCAACTTA TACTACCGGG GTATCCACGT CTACTTTTTG', '   165066 TTTGTTTGGA TGCACTTAAT ACAAATAATA TTTTTCCTGT AACTGAGGCA CTTTGGGAGG', '   165126 TGGCTTGAGC CCAGAAGTTT GAGACCAGCC TGGGCAAGAG AGTGAGGCCG TTTCTACAGA', '   165186 AAGTACAAAA ATTAGCCATG GCCTGGTTGT GCGTGTCTGT GGTCTCAGCT ACTCAGGAGG', '   165246 CTGAGGTGGG AGGATCACTT GAGCCCAGGA GGTCGAGGCT GCAGTGAGCC GAGATCATAC', '   165306 CACTGCGGTT CAGTCTGGGT GACAGAGCGA GACCCTGTCT CTAAAGAAGA AAAGTAAAAA', '   165366 CAAAAAAAAT AATTTCATCC CAGGAAAGTT TTACTTTTTT TTTTTTTTTT TTTTTGAGAC', '   165426 GAGTCTCGCT CTGTCACACA GGCTGGAGTG CAGTGGCGCG ATCTCAGCTC ACTGCAAGCT', '   165486 CCGCCTCCCG GGTTCAGCCA TTCTCCTGCC TCAGCCTCTC TTGAGTAGCT GGGACTACAG', '   165546 GCACCCGCCA CCATGCCTGG CTAATTTTTT ATATTTTTAG TAGAGACGGG ATTTCGCCGT', '   165606 GGTCTCGATC TCCTGACCTG AAGTGATCCA CCCGCCTCAA CCTCCCAAAG TGCTGGGATT', '   165666 GCAGGCGTGA GCCACCACAC CCGGTCCATA ATTTATTGTC GGGAGGAGTC GAAAGCGGAG', '   165726 TCCAGGCTCC GGGCGGGGTT CAGTCCCATC TCCTCAAGGA GGTGGCAGCC GCGTCCGTTC', '   165786 TTTGGGACAT TTGCTGCTTC TCCCTCAGGG CAAAAAACAA AGCCGTAGCC TGAATGTGAC', '   165846 AATCTCACAC CTTGTTTTCC TGCCTTGTTG CTTGACAATA TTTCCCCGTG CTCTTCATGC', '   165906 ACTTGGAAAG TCTACGGTAC GGATGGAGTG TGCAGCTCAC TCAGCACCCT ACGGCCGGGG', '   165966 GCAGTTCCGG AGCCAAACAG CACCCCGCCC CCAAATCCAC ATCCACCAGC AGCCTCAGAA', '   166026 TGGGACCCTA CCCAGAATTA AGATCTCTGC GGATGCAGCT GGTGAAGATG AGGTCAGGGT', '   166086 GGAGCAGAGT GGGCCTTAAA TCCAACGACC GACCGGTATG TTTACGACAG AAAGAAAGAG', '   166146 ATGTGGGGCA GACACAGAAG AGAAGGGGAC CTTGCTTGGA AATGGAGTTT TTGCAGATGT', '   166206 AGTTAAGATG AGGTTACCCT GGATTTATCT AGGTGGCCCC TAAATGCAAT GACAGGTGTC', '   166266 CTAGGAGACA CAGACACAGA GAAGGCCACG TGGAGATGGA GGCAGAGACT GGAGTGGTGC', '   166326 GGCCACAAGC CCAGGGACGC CTGGAGCCCC CAGGAGCTGG GAGAGGCAGG AAGGACCCTC', '   166386 ACCTAGAGCC TCCAGAAGGA ACTGGATCCA ACTGAAGTGA A', '//' ];
is_deeply ( [split("\n", $value->getAsGB())], $exp, 'get_chromosomal_region');

$exp = [ '#chromosome', 'start', 'end', 'name', 'chrY', '130991', '134991', 'PLCXD1', 'chrY', '168887', '172887', 'GTPBP6', 'chrY', '265627', '269627', 'PPP2R3B', 'chrY', '220590', '224590', 'PPP2R3B', 'chrY', '503079', '507079', 'SHOX', 'chrY', '503079', '507079', 'SHOX' ];
$value = $gbFeaturesTable-> get_promoter_regions_4_genes ([ 'PLCXD1', 'GTPBP6', 'PPP2R3B', 'SHOX'] );
is_deeply ( [ split(/[\t\n]/,$value->AsString()) ], $exp, "get promotor regions as bed file" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
#print "\$exp = ".root->print_perl_var_def([ split(/[\t\n]/,$value->AsString()) ]  ).";\n";