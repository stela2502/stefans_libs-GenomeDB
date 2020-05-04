#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 35;

use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $data_table = data_table->new();
my ($exp, $value, @values, $temp);
my $includes = "-I " . join( " -I ", @INC );
my $path     = $plugin_path . "/data";
my $outpath  = "$path/output";

#system("rm -R $path/output ");
mkdir($path)    unless ( -d $path );
mkdir($outpath) unless ( -d $outpath );
system ( "rm -R $outpath/*" );
foreach (
	"$outpath/sample_expression_dataset_Control.xls",
	"$outpath/sample_expression_dataset.log",
	"$outpath/sample_expression_dataset_Groupings.xls",
	"$outpath/sample_expression_dataset.xls"
  )
{
	unlink( $_ ) if ( -f $_);
}


open ( BKG , ">$path/background_list.txt");
print BKG "RAG1 RAG2 E2F PAX5 NFKB TCF7L2 IL24 IL1 IL2 IL3 IL4 IL5 IL6 IL7 IL8 SEPT1 SEPT2 SEPT3 SEPT4 SEPT5 SEPT6 SEPT7\n";
close ( BKG );
open (PATHWAY, ">$path/pathway_random.gmt");
print PATHWAY "positive_pathway with a ridiculousely long name that is really hard to get into a table	some web page	RAG1	RAG2	E2F	PAX5	NFKB	TCF7L2	IL24	IL1	IL2	IL3	IL4	IL5	IL6	IL7	IL8\n".
"negative_pathway	some other web pageGCK	PGK2	PGK1	PDHB	PDHA1	PDHA2	PGM2	TPI1	ACSS1	FBP1	ADH1B	HK2	ADH1C	HK1	HK3	ADH4	PGAM2	ADH5	PGAM1	ADH1A\n";
close ( PATHWAY );
system(
	"perl $includes $plugin_path/../bin/create_pathway_analysis.pl "
	  . " -pathways $path/pathway_random.gmt"
	  . " -genes RAG1 RAG2 E2F PAX5 NFKB TCF7L2"
	  . " -outfile $outpath/A/sample_expression_dataset"
	  ." -gene_description 'Some test script run'"
	  ." -background_list $path/background_list.txt"
	  . " > /dev/null 2> /dev/null" 
);
	  
foreach ( qw(
sample_expression_dataset.tex
sample_expression_dataset.PERL.log
Figures/error_logfile
Figures/last_figure_id.log
Tables/0000.xls
Tables/0001.xls
Tables/last_table_id.log
Makefile
) )

{
	is_deeply( -f "$outpath/A/$_", 1, "gene list outfile $_" );
}

system ( "make all -C $outpath/A/ ". " > /dev/null 2> /dev/null"  );
foreach ( qw(
sample_expression_dataset.pdf
sample_expression_dataset.tar.gz
) )

{
	is_deeply( -f "$outpath/A/$_", 1, "gene list outfile $_" );
}

open ( BKG , ">$path/GoI.txt");
print BKG "#This is a random gene list and should not be any problem!!\n";
print BKG "PGK1 PDHB PDHA1 PDHA2 PGM2 TPI1 ACSS1 FBP1 ADH1B HK2\n";
close ( BKG );

system(
	"perl $includes $plugin_path/../bin/create_pathway_analysis.pl "
	  . " -pathways $path/pathway_random.gmt"
	  . " -genes $path/GoI.txt"
	  . " -outfile $outpath/B/sample_expression_dataset"
	  ." -gene_description 'Some test script run'"
	  ." -background_list $path/background_list.txt"
	  . " > /dev/null 2> /dev/null" 
);
	  
foreach ( qw(
sample_expression_dataset.tex
sample_expression_dataset.PERL.log
Figures/error_logfile
Figures/last_figure_id.log
Tables/0000.xls
Tables/0001.xls
Tables/last_table_id.log
Makefile
) )

{
	is_deeply( -f "$outpath/B/$_", 1, "gene file outfile $_" );
}

system ( "make all -C $outpath/B/ ". " > /dev/null 2> /dev/null"  );
foreach ( qw(
sample_expression_dataset.pdf
sample_expression_dataset.tar.gz
) )

{
	is_deeply( -f "$outpath/B/$_", 1, "gene file outfile $_" );
}


#### test the gene summary input file...
open ( BKG , ">$path/GoI.txt");
print BKG "gene_lists\n";
print BKG "GeneListA RAG1 RAG2 E2F PAX5 NFKB TCF7L2\n";
print BKG "GeneListB TCF7L2 IL24 IL1 IL2 IL3\n";
close ( BKG );

system(
	"perl $includes $plugin_path/../bin/create_pathway_analysis.pl "
	  . " -pathways $path/pathway_random.gmt"
	  . " -genes $path/GoI.txt"
	  . " -outfile $outpath/C/sample_expression_dataset"
	  ." -gene_description 'Some test script run'"
	  ." -background_list $path/background_list.txt"
	  . " > /dev/null 2> /dev/null" 
);

foreach my $path_ext ('GeneListA', 'GeneListB' ){
foreach ( qw(
Figures/error_logfile
Figures/last_figure_id.log
Tables/0000.xls
Tables/0001.xls
Tables/last_table_id.log
Makefile
) ){
	is_deeply( -f "$outpath/C/$path_ext/$_", 1, "gene_list outfile $path_ext/$_" );
}
}
ok ( -f "$outpath/C/Makefile", "$outpath/C/Makefile" );

system ( "make all -C $outpath/C/  > /dev/null 2> /dev/null"); ## this should create all pdf files!
foreach my $path_ext ('GeneListA', 'GeneListB' ){
	ok ( -f "$outpath/C/$path_ext/$path_ext"."_sample_expression_dataset.pdf", "$outpath/$path_ext/$path_ext"."_sample_expression_dataset.pdf");
}

#print "\$exp = " . root->print_perl_var_def( $value ) . ";\n";