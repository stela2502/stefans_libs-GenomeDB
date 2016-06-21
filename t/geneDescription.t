#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use HTML::TreeBuilder;

my $do_manual_test = $ARGV[0];
BEGIN { use_ok 'stefans_libs::database::genomeDB::gene_description' }

## I need to check if I can get the right entries from the website!

my $gene_description = gene_description->new( variable_table::getDBH() );

my ( $value, $error, $gene );

$gene  ="NOTNHING"; #"MARCH13";#"ARHGAP28";# "CASC5"; "RAG1"; 
$value = $gene_description->get_href_for_gene($gene);
is_deeply(
	$value,
	"http://www.genecards.org/cgi-bin/carddisp.pl?gene=$gene",
	'we get the right link'
);
my $mech = WWW::Mechanize->new( 'stack_depth' => 0 );

if ($do_manual_test) {
	my $treebuilder = HTML::TreeBuilder->new();
	$mech->get($value);
	my $data = $mech->content();
	$data =~ s/\<\/dd\>\<dd\>/ \<\/dd\>\<dd\>/g;
	$treebuilder->parse($data);
	$treebuilder->eof();
	my $i = 0;
	foreach $value ( $treebuilder->look_down( '_tag', 'body' ) ) {

		if ( ref($value) ) {
			##go on
			my @values = $value->look_down( '_tag', 'table' );
			unless ( ref( $values[0] ) ) {
				die "OOPS - I expected to find a table object!\n";
			}
			else {
				print "OK - we have a table!!\n";
				my $genes ;
				foreach $value (@values) {
					foreach my $table_entry ( $value->content_list() ) {
						if ( $table_entry->as_text() =~
							m/Aliases . Descriptionsfor.*According to/ )
						{
							$table_entry->as_text() =~ m/Aliases & Description(.*)External Ids/;
							my $str = $1 || ''; 
							while ( $str =~ m/Aliases & Description(.*)/ ){
								$str = $1;
							}
							if ( $str =~ m/\w/){
								foreach ( split (/ +/, $str) ){
									print "is that a gene symbol? $_\n";
									next if ( length($_) <=1 );
									next unless ( $_ eq uc($_));
									next unless ( $_ =~ m/^[\w\d\-\@]+$/);
									next if ( $_ =~ m/^\d+$/);
									next unless ( $_ =~ /\d\d(.*)[1234]/ );
									$genes->{$1} = 1;
								}
							}
							
						}
					}
				}
				$genes->{$gene} = 1;
				print "I think I have identified the gene names(symbols) ".join(", ", (keys %$genes ))."\n";
			}
		}
		else {
			die "we could not get the body of the page!\n";
		}

	}
	$treebuilder->delete();
	die;
}
#$gene_description->{DEBUG}=1;
( $value, $error ) =
  $gene_description->__get_hash_4_genecards_url( $gene, $value );

is_deeply( $error, '', 'there was no lib error' );
is_deeply( [ keys %$value ], [$gene], 'we get a result for gene ' );

is_deeply(
	$value->{$gene}->{'RefSeq_desc'},
'EntrezGene summary for RAG1: The protein encoded by this gene is involved in activation of immunoglobulin V-D-J recombination. The encoded protein is involved in recognition of the DNA substrate, but stable binding and cleavage activity also requires RAG2. Defects in this gene can be the cause of several diseases. (provided by RefSeq) UniProtKB/Swiss-Prot: RAG1_HUMAN, P15918Function: During lymphocyte development, the genes encoding immunoglobulins and T-cell receptors are assembled from variable (V), diversity (D), and joining (J) gene segments. This combinatorial process, known as V(D)J recombination, allows the generation of an enormous range of binding specificities from a limited amount of genetic information. The RAG1/RAG2 complex initiates this process by binding to the conserved recombination signal sequences (RSS) and introducing a double-strand break between the RSS and the adjacent coding segment. These breaks are generated in two steps, nicking of one strand (hydrolysis), followed by hairpin formation (transesterification). RAG1/2 has also been shown to function as a transposase in vitro, and to possess RSS-independent endonuclease activity (end processing) and hairpin opening. RAG1 alone can bind to RSS but stable, efficient binding requires RAG2. All known catalytic activities require the presence of both proteins',
	'the description has not changed'
);
is_deeply( $value->{$gene}->{'aliases'}, ['RNF74', 'RAG1', 'MGC43321'], 'we get the right aliases');
my $exp = $gene_description->_get_gene_description_from_genecards( 'TCF7L2' );
$value = $gene_description->_get_gene_description_from_genecards( 'ILMN_123456_TCF7L2' );
$exp->{'timestamp'} = $value ->{'timestamp'};
delete($exp->{search_array});
delete($value->{search_array});
$exp->{'id'} = $value ->{'id'};
is_deeply (  $value, $exp, "Same results with or without ILMN or AFFY Probe Set ID");
#print "\$exp = " . root->print_perl_var_def( $gene_description->_get_gene_description_from_genecards( 'TCF7L2' ) ) . ";\n";
#print "\$exp = " . root->print_perl_var_def( $gene_description->_get_gene_description_from_genecards( 'ILMN_123456_TCF7L2' ) ) . ";\n";
