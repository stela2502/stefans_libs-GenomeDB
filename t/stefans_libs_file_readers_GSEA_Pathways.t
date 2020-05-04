#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::file_readers::GSEA_Pathways' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $stefans_libs_file_readers_GSEA_Pathways = stefans_libs::file_readers::GSEA_Pathways -> new();
is_deeply ( ref($stefans_libs_file_readers_GSEA_Pathways) , 'stefans_libs::file_readers::GSEA_Pathways', 'simple test of function stefans_libs::file_readers::GSEA_Pathways -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

$value = $stefans_libs_file_readers_GSEA_Pathways->read_file("$plugin_path/data/pathway_random.gmt" );
#print "\$exp = ".root->print_perl_var_def($value->{'pathways'} ).";\n";
$exp = {
  'positive_pathway with a ridiculousely long name that is really hard to get into a table' => [ 'E2F', 'IL1', 'IL2', 'IL24', 'IL3', 'IL4', 'IL5', 'IL6', 'IL7', 'IL8', 'NFKB', 'PAX5', 'RAG1', 'RAG2', 'TCF7L2' ],
  'negative_pathway' => [ 'ACSS1', 'ADH1A', 'ADH1B', 'ADH1C', 'ADH4', 'ADH5', 'FBP1', 'HK1', 'HK2', 'HK3', 'PDHA1', 'PDHA2', 'PDHB', 'PGAM1', 'PGAM2', 'PGK1', 'PGK2', 'PGM2', 'TPI1' ]
};

is_deeply( $value->{'pathways'} , $exp, "read pathways" );

$value = $stefans_libs_file_readers_GSEA_Pathways-> load_background ( "$plugin_path/data/background_list.txt" );

#open ( IN, "<$plugin_path/data/background_list.txt");
#open ( OUT, ">$plugin_path/data/background_list.mouse.txt");
#while ( <IN> ){
#	print OUT lc($_);
#}
#close ( IN);
#close ( OUT );

$exp = {
  'positive_pathway with a ridiculousely long name that is really hard to get into a table' => '15',
  'negative_pathway' => '0'
};

is_deeply ($value, $exp, 'read background' );

$stefans_libs_file_readers_GSEA_Pathways = stefans_libs::file_readers::GSEA_Pathways -> new();
$stefans_libs_file_readers_GSEA_Pathways->read_file("$plugin_path/data/pathway_random.gmt");
$value = map { lc($_) => $_ } ( 'E2F', 'IL1', 'IL2', 'IL24', 'IL3', 'IL4', 'IL5', 'IL6', 'IL7', 'IL8', 'NFKB', 'PAX5', 'RAG1', 'FBP1', 'HK1', 'HK2', 'HK3');
$value = $stefans_libs_file_readers_GSEA_Pathways-> load_background ( "$plugin_path/data/background_list.mouse.txt", $value );
$exp->{'positive_pathway with a ridiculousely long name that is really hard to get into a table'}= 13;

is_deeply ($value, $exp, 'read background (mouse)' );


#print "\$exp = ".root->print_perl_var_def($value ).";\n";