#! /usr/bin/perl -w

#  Copyright (C) 2010-11-09 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 plot_best_batch_results_per_file.pl

The scipt will take a list of batch statistics result files and plot a configurable amount of best correlated genes.

To get further help use 'plot_best_batch_results_per_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::stat_results;
use stefans_libs::database::genomeDB::gene_description;
use stefans_libs::database::pathways::kegg::kegg_genes;
use stefans_libs::Latex_Document;
use stefans_libs::histogram_container;
use stefans_libs::array_analysis::table_based_statistics::group_information;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,            $debug,               $database,
	$outpath,         @genes,               $outfile,
	$number_of_genes, $introduction_str,    @infiles,
	$bar_graph,       @random_correlations, $title,
	$genes_to_select, $grouping_file,       $kegg_reference_geneset
);

Getopt::Long::GetOptions(
	"-outfile=s"                => \$outfile,
	"-number_of_genes=s"        => \$number_of_genes,
	"-infiles=s{,}"             => \@infiles,
	"-random_correlations=s{,}" => \@random_correlations,
	"-bar_graph"                => \$bar_graph,
	"-introduction=s"           => \$introduction_str,
	"-title=s"                  => \$title,
	"-genes=s{,}"               => \@genes,
	"-grouping_file=s"            => \$grouping_file,
	"-kegg_reference_geneset=s" => \$kegg_reference_geneset,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
else {
	my @temp = split( "/", $outfile );
	$outfile = pop(@temp);
	unless ( defined $title ) {
		$title = join( " ", split( /[\-_]/, $outfile ) );
		$title =~ s/tex$//;
	}
	$outpath = join( "/", @temp );
	if ( $outpath eq "" ) {
		$error .= "Sorry, but we need the absolute path to the outfile!\n";
	}
	elsif ( !-d $outpath ) {
		mkdir($outpath);
	}
}

unless ( defined $number_of_genes ) {
	$error .= "the cmd line switch -number_of_genes is undefined!\n";
}
unless ( defined $infiles[0] ) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
if ( defined $genes[0] ) {
	foreach (@genes) {
		$genes_to_select->{$_} = 1;
	}
}
unless ( defined $kegg_reference_geneset ) {
	$warn .= "the cmd line switch -kegg_reference_geneset has to be given!\n";
}
if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for plot_best_batch_results_per_file.pl

   -outfile   :the absolute position of the outfile
               we will create a lot of directories in that path
               so do not create the file in a previously used path!
   -infiles   :the correlation results you want to create a PDF report for

   -number_of_genes :how many of the top correlated genes should I plot? (default 10)
   
   -random_correlations :If you give me a random set of correlations, I 
                         will use the max p_value for these to calculate 
                         the 5% quantile p_value cut off value
                         
   -genes     :In case you are especially interested in a list of genes, 
               I can give you the topmost for that list of genes.
   -bar_graph :Instead of using a whisker plot you will get a mean +- std plot
               I would recomend to use the whisker instead!
               
   -kegg_reference_geneset :if you want to add a KEGG statistics part I need a
                            reference gene list that you previously did match
                            to the KEGG pathways (e.g. 'HUGene_v1')
                            
   -grouping_file :The file that you used to for the statistics analysis using either
                   batchStatistics.pl or the second version of that file
                   
   -introduction :a text introduction for the PDF result file to explain the data 
                  that is presented in the document
   -title        :the title for the PDF file - I I do not get one I will take the
                  PDF file name as title!
   
                  
   -help           :print this help
   -debug          :verbose output
   

";
}

my ( $task_description, $stat_results, $table_obj, @file, $temp,
	$histogram_container );
$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/plot_best_batch_results_per_file.pl';
$task_description .= " -outfile $outpath/some_crap"
  if ( defined $outpath );
$task_description .= " -number_of_genes $number_of_genes"
  if ( defined $number_of_genes );
$task_description .= " -bar_graph" if ($bar_graph);
$task_description .= ' -infiles ' . join( ' ', @infiles )
  if ( defined $infiles[0] );
$task_description .= " -introduction '$introduction_str'"
  if ( defined $introduction_str );
$task_description .= " -title '$title'" if ( defined $title );
$task_description .= " -kegg_reference_geneset '$kegg_reference_geneset'"
  if ( defined $kegg_reference_geneset );
$task_description .= " -genes " . join( " ", @genes ) if ( defined $genes[0] );
$task_description .= " -grouping_file $grouping_file"
  if ( defined $grouping_file );

open( LOG, ">$outpath/$outfile.creation.log" )
  or die
"Sorry, but I could not create the log file '$outpath/$outfile.creation.log'\n$!\n";
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!

## Initialize the objects - and set the standard header
## so that we know which are the sample IDs
$stat_results = stat_results->new();
my $all_results = data_table->new();

$all_results->Add_2_Header('Gene Symbol');
$all_results->Add_2_Header('Probe Set ID');
$all_results->createIndex('Gene Symbol');
$all_results->createIndex('Probe Set ID');
$all_results->define_subset( 'gene_name', [ 'Gene Symbol', 'Probe Set ID' ] );

## Initialize the output object
my @data_columns;
my (
	$introduction,          $results,
	$appendix,              $result_by_SNP,
	$result_section,        $text,
	$figure,                $genes,
	$quantil_cutoff,        $other_histogram,
	$selected_results,      $restricted_results_section,
	$restrict_results_text, $genes_2_describe,
	$actual_genes
);

my $Latex_Document = stefans_libs::Latex_Document->new();
$Latex_Document->Outpath($outpath);

my $data_table = data_table->new();
my $randomData = data_table->new();

foreach ( 'group name', 'affected gene', 'p value', 'q value' ) {
	$data_table->Add_2_Header($_);
	$randomData->Add_2_Header($_);
}
if ($bar_graph) {
	$bar_graph = 'bars';
}
else {
	$bar_graph = '';
}
my $figure_id = 1;

## create the random figures - in case we have got random correlations....
if ( -f $outpath . "/plotted_data.xls" ) {
	unlink( $outpath . "/plotted_data.xls" );
}
if ( -f "$outpath/random_SNPs_best_correlating_gene.txt" ) {
	$randomData->read_file("$outpath/random_SNPs_best_correlating_gene.txt");
	warn
"If you do not get what you expected please remove the file '$outpath/random_SNPs_best_correlating_gene.txt'\n";
}
else {
	foreach my $infile (@random_correlations) {
		@file      = split( "/", $infile );
		$table_obj = $file[ @file - 1 ];
		@file      = split( /\./, $table_obj );
		my $table_obj = $stat_results->read_file($infile);
		$temp      = $table_obj->_copy_without_data();
		$table_obj = $table_obj->Sort_by( [ [ 'p-value', 'numeric' ] ] );
		$temp      = $table_obj->get_line_asHash(0);
		$randomData->AddDataset(
			{
				'group name'    => $file[0],
				'affected gene' => $temp->{'Gene Symbol'},
				'p value'       => $temp->{'p-value'}
			}
		);
	}
}
my @temp2;
if ( scalar( @{ $randomData->{'data'} } ) > 100 ) {
	foreach ( @{ $randomData->getAsArray('p-value') } ) {
		push( @temp2, -&log10($_) );
	}
	$quantil_cutoff = root->quantilCutoff( \@temp2, 95 );
}
$quantil_cutoff = 10**-$quantil_cutoff;

## create the output document

$Latex_Document->Title($title);
$Latex_Document->Author('Stefan Lang');

$introduction = $Latex_Document->Section( 'Introduction', 'sec::intro' );

my $restricted_results = $Latex_Document->Section(
	'Results p cut off ' . sprintf( '%.2e', $quantil_cutoff ), 'sec::res2' )
  if ( $quantil_cutoff != 1 );

$results = $Latex_Document->Section( 'Results p cut off 0.05', 'sec::res' );

$Latex_Document->Section( 'Methods', 'meth' )->Section('Script Call')
  ->AddText(
	"The following command line was used to create this PDF document:\n"
	  . $task_description );

my $introduction_text = $introduction->AddText(
	'This document is mainly ment to sum up the first analysis I have done. 
I do not go into detail about the method.
In short about the method: Genes have been grouped as reported in section \ref{app::desc::groups} on page \pageref{app::desc::groups} using of my batchStatistics.pl script.
At the moment the script supports three different analysis methods: 
\begin{enumerate}
\item{Two Group comparisons using the \href{http://stat.ethz.ch/R-manual/R-patched/library/stats/html/wilcox.test.html}{R implementation} of the \href{http://udel.edu/~mcdonald/statsignedrank.html}{Wilcoxon signed-rank} test} 
\item{Multi group comparisons using the \href{http://stat.ethz.ch/R-manual/R-devel/library/stats/html/kruskal.test.html}{R implementation} of the \href{http://udel.edu/~mcdonald/statkruskalwallis.html}{Kruskal Wallis} test}
\item{Linear correlations using the \href{http://stat.ethz.ch/R-manual/R-patched/library/stats/html/cor.test.html}{R implementation} of the \href{http://udel.edu/~mcdonald/statspearman.html}{Spearman signed rank} test }
\end{enumerate}
The analyzed expression values are depicted in the figures. Grouped comparisons are shown as \href{https://en.wikipedia.org/wiki/Box_plot}{Box Plot}, linear correlations as X-Y plot.\\\\
For the linear analysis I wanted to highlight the correlation and therefore I have not only plotted each data point,
the spearman p value and the spearman rho in the figures, but also included a regression line. 
The regression line is calculated using preason statistics and therefore does not represent the results from the spearman analysis.

All genes from one gouping are analyzed using KEGG pathways for humans. Each KEGG analysis is grouping specific and not all top genes need to be found in a KEGG analysis.

The following table shows the gene that correlates best for each grouping.'
);
if ( defined $grouping_file ) {
	$introduction_text->AddText(
"The sample goupings that have been used for this analysis are descibed in the section 'Sample Groupings' \\ref{app::desc::groups} on page \\pageref{app::desc::groups}."
	);
	my $temp = $Latex_Document->Section( 'APPENDIX', 'app' );
	my $group_object =
	  stefans_libs_array_analysis_table_based_statistics_group_information->new();
	$group_object->AddFile($grouping_file);
	#Carp::confes (print root::get_hashEntries_as_string ({'filename' => $grouping_file, 'groups' => $group_object->GetGroups()}  , 3 , "wyh do I not get the right information into the section?" ) ) ;
	$Latex_Document -> UsePackage('{multirow}');
	#$group_object-> OnlyTheseGroups ($data_table-> )
	$group_object->As_LaTex_section(
		{ 'latex_section' => $temp, 'section_label' => 'app::desc::groups' } );
}

$introduction_text->Add_Table($data_table);

$introduction_str =
"The first overview over the dataset is to look at the best correlated gene for each grouping. "
  . "The question is, if we see a extreme difference between the best p values for the differnet grouping."
  . " The question is, if all groups seam to influence several genes in a s similar way, "
  . "or if some groupings are totally different from the rest. "
  unless ( defined $introduction_str );
$introduction_text->AddText($introduction_str);

$introduction_text->AddText('The sample goupings that have been used for this analysis are descibed in the section \'Sample Groupings\' \ref{app::desc::groups} on page \pageref{app::desc::groups}.

A word describing the figures: Grouped comparisons (\href{http://udel.edu/~mcdonald/statsignedrank.html}{Wilcoxon signed-rank} or 
\href{http://udel.edu/~mcdonald/statkruskalwallis.html}{Kruskal Wallis} tests) are shown as \href{https://en.wikipedia.org/wiki/Box_plot}{Box Plot}, 
linear correlation (\href{http://udel.edu/~mcdonald/statspearman.html}{Spearman signed rank}) are shown as X-Y plot. i
The line is calculated using a pearson test and does NOT represent the results of the Spearman analysis. I have added it to highlught whether 
there is a positive or negative corelation. 
Each plot shows the p value in the upper right corner, the Spearman plots also show the
 \href{https://en.wikipedia.org/wiki/Spearman\%27s_rank_correlation_coefficient}{Spearman rho}.
All tests were calculated using the R implementation of the test (\href{http://stat.ethz.ch/R-manual/R-patched/library/stats/html/cor.test.html}{spearman},
 \href{http://stat.ethz.ch/R-manual/R-patched/library/stats/html/wilcox.test.html}{Wiklcoxon Signed Rank} and 
 \href{http://stat.ethz.ch/R-manual/R-devel/library/stats/html/kruskal.test.html}{Kruskal Wallis}).
');

my ( $gene_description, $kegg_genes, $rs_info, $actual_genes_info, $really_All_Gene_Names, @the_datasets );
$gene_description = gene_description->new( variable_table->getDBH() );
$kegg_genes       = kegg_genes->new( $gene_description->{'dbh'} );
my $all_gene_all_models = data_table->new();
$all_gene_all_models->Add_header_Array(
	[ 'Gene Symbol', 'Probe Set ID', 'model', 'p value', 'q value' ] );

foreach my $infile (@infiles) {

	@file      = split( "/", $infile );
	$table_obj = $file[ @file - 1 ];
	@file      = split( /\./, $table_obj );

	if ( $infile =~ m/.tar$/ ) {
		## OK a new data file! DAMN IT
		## 1. untar the stuff - the real filename will always be named 'purged_results.xls'
		system("tar -xf $infile --directory $outpath purged_results.xls");
		$table_obj = $stat_results->read_file("$outpath/purged_results.xls");
		unlink("$outpath/purged_results.xls");
	}
	else {
		$table_obj = $stat_results->read_file($infile);
	}
	my $array;
	my $temp;
	my $gene_symbol_column =  $table_obj -> Header_Position ( "Gene Symbol" ) ;
	for ( my $i = 0; $i < $table_obj->Lines(); $i++ ){
		$array = @{$table_obj->{'data'}} [ $i ];
		if ( @$array[$gene_symbol_column] =~m/(\d\d?). Mrz/ ){
			$temp = $1 if ( $1 =~m/0(\d)/);
			@$array[$gene_symbol_column] = "MARCH$1";
		}
		elsif ( @$array[$gene_symbol_column] =~m/\w \w/ ){
			warn "we have another crap gene symbol here: @$array[$gene_symbol_column]\n";
		}
	}
	$table_obj = $table_obj -> select_where( 'p-value', sub { return 1 if ( $_[0] =~m/\d/); return 0;} );
	$table_obj = $table_obj -> select_where( 'Gene Symbol', sub { return 0 if ( $_[0] =~m/---/); return 1;} );
	warn "we got a data object of the class " . ref($table_obj) . "\n";
	if ( defined $genes[0] ) {
		$table_obj->select_where( 'Gene Symbol',
			sub { return 1 if ( $genes_to_select->{ $_[0] } ); return 0 } );
	}
	$temp = $table_obj->_copy_without_data();
	$table_obj =
	  $table_obj->select_where( 'Gene Symbol',
		sub { return 0 if ( $_[0] =~ m/\-\-\-/ ); return 1 } );
	## save the best gene for the summary data
	$all_results->Add_2_Header( $file[0] );
	for ( my $i = 0 ; $i < @{ $table_obj->{'data'} } ; $i++ ) {
		@{ @{ $table_obj->{'data'} }[$i] }[1] = $1
		  if ( @{ @{ $table_obj->{'data'} }[$i] }[1] =~ m/^ *(.*) *$/ );
		$all_results->AddDataset(
			{
				'Probe Set ID' => @{ @{ $table_obj->{'data'} }[$i] }[0],
				'Gene Symbol'  => @{ @{ $table_obj->{'data'} }[$i] }[1],
				$file[0]       => @{ @{ $table_obj->{'data'} }[$i] }[2]
			}
		);
	}
	push( @data_columns, $file[0] );
	$table_obj = $table_obj->Sort_by( [ [ 'p-value', 'numeric' ] ] );

	## add all results to the results section
	my $i = 0;
	$result_section = $results->Section( $file[0], 'res::' . $file[0] );
	$temp           = $table_obj->get_line_asHash(0);
	$text           = $result_section->AddText(
		"I have taken the correlation results from '$file[0]'. 
	In total we got "
		  . scalar( @{ $table_obj->{'data'} } )
		  . " genes into this analysis."
		  . " The best p_value was "
		  . $temp->{'p-value'}
		  . " for the gene "
		  . $temp->{'Gene Symbol'} . "."
	);
	$temp-> {'q_value (BH)'} = 'n.d.' unless ( defined $temp->{'q_value (BH)'});
	$data_table->AddDataset(
		{
			'group name'    => $file[0],
			'affected gene' => $temp->{'Gene Symbol'},
			'p value'       => $temp->{'p-value'},
			'q value'       => $temp-> {'q_value (BH)'},
		}
	);
	$table_obj =
	  $table_obj->select_where( 'p-value',
		sub { $i++; return 1 if ( $i < $number_of_genes ); return 0; } );
	## describe all genes, that we still have in the model
	$actual_genes = {};
	$actual_genes_info = data_table->new();
	foreach ( 'Gene Symbol', 'Probe Set ID', 'model', 'p value', 'q value'){
		$actual_genes_info -> Add_2_Header($_)
	}
	for ( my $i = 0 ; $i < @{ $table_obj->{'data'} } ; $i++ ) {
		$temp = $table_obj->get_line_asHash($i);
		unless ( defined $temp -> {'q_value (BH)'}){
			warn "DAMN! I do not have a q_value column\n";
		}
		$temp -> {'q_value (BH)'} = 'n.d.' unless ( defined $temp -> {'q_value (BH)'});
		$really_All_Gene_Names -> {$temp->{'Gene Symbol'}} = 1;
		$all_gene_all_models->AddDataset(
			{
				'Gene Symbol'  => $temp->{'Gene Symbol'},
				'Probe Set ID' => $temp->{'Probe Set ID'},
				'model'        => $file[0],
				'p value'      => $temp->{'p-value'},
				'q value'      => $temp -> {'q_value (BH)'},
			}
		);
		$actual_genes_info ->AddDataset(
			{
				'Gene Symbol'  => $temp->{'Gene Symbol'},
				'Probe Set ID' => $temp->{'Probe Set ID'},
				'model'        => $file[0],
				'p value'      => $temp->{'p-value'},
				'q value'      => $temp -> {'q_value (BH)'},
			}
		); 
		$temp->{'Gene Symbol'} = $temp->{'Probe Set ID'}
		  unless ( $temp->{'Gene Symbol'} =~ m/\w/ );
		$genes_2_describe->{ $temp->{'Gene Symbol'} } = 0
		  unless ( defined $genes_2_describe->{ $temp->{'Gene Symbol'} } );
		$genes_2_describe->{ $temp->{'Gene Symbol'} }++;
		$actual_genes->{ $temp->{'Gene Symbol'} } = 1;
	}
	$text -> AddText( "The following table shows all statistic results for the here visulaized genes:");
	$text -> AddTable ( $actual_genes_info );
	## plot the figures for all genes
	mkdir( $outpath . "/" . $file[0] ) unless ( -d $outpath . "/" . $file[0] );
	$table_obj->write_file( $outpath . "/$file[0]_plotted_data.xls" );
	my $figure_files =
	  $table_obj->plot( $outpath . "/" . $file[0], $bar_graph );
	## create the figure in the report PDF
	$figure = $text->Add_Figure();

	#print $table_obj->AsString();
	$genes = $table_obj->GeneNames();

	$figure->AddPicture(
		{
			'files' => [ ( @$figure_files[ 0 .. 8 ] ) ],
			'caption' =>
			  'Shown is the change in gene expression in the different grous defined for '
			  . " grouping $file[0]. The 9 genes genes abased on p\_value are shown.",
			'subfigure_captions' =>
			  [ map( '\\nameref{' . root->Latex_Label($_) . '}', @$genes ) ],
			'label' => 'fig::' . $figure_id++
		}
	);
	$text->AddText(
		" The data for the 9 best genes based on p\_value are shown in figure \\ref{"
		  . $figure->Label()
		  . "}." );
	$text->AddText(
"The genes, that were selected have been matched against the KEGG pathways. The matching pathways and patizipating genes are shown in the following table."
	  )->Add_Table(
		$kegg_genes->__gene_hits_for_each_KEGG_pathway(
			$kegg_genes->__get_table_for_gene_list( [ keys %$actual_genes ] )
		)
	  );
	## focus on those genes that pass the hard cut off!
	$selected_results =
	  $table_obj->select_where( 'p-value',
		sub { return 1 if ( $_[0] <= $quantil_cutoff ); return 0 } );
	next;
	my $genes_left_over->AddDataset(
		{
			'group name'       => $file[0],
			'p <= 0.05'        => scalar( @{ $table_obj->{'data'} } ),
			'p <= new cut off' => scalar( @{ $selected_results->{'data'} } )
		}
	);
	next if ( scalar( @{ $selected_results->{'data'} } ) == 0 );
	next unless ( defined $restricted_results );
	$restricted_results_section =
	  $restricted_results->Section( $file[0], 'res::rest::' . $file[0] );
	$text = $restricted_results_section->AddText(
		    " Once we apply the estimate p value cut off of "
		  . sprintf( '%.1e', $quantil_cutoff )
		  . " we have only "
		  . scalar( @{ $selected_results->{'data'} } )
		  . " genes left. " );
	$figure = $text->Add_Figure();
	$genes  = $selected_results->getAsArray('Gene Symbol');
	$text->AddText(
		"The genes " . join( ", ", @$genes ) . " did pass the cut off." );
	$temp = '';

	if ( @$genes < 5 ) {
		$temp = 0.66;
	}
	if ( @$genes < 2 ) {
		$temp = 0.33;
	}
	$figure->AddPicture(
		{
			'files' => [ ( @$figure_files[ 0 .. ( scalar(@$genes) - 1 ) ] ) ],
			'caption' =>
			  'Shown is the change in gene expression due to grouping'
			  . " $file[0] for these genes that passed the p value cut off "
			  . sprintf( '%.1e', $quantil_cutoff )
			  . "(BACK:\\ref{"
			  . 'res::rest::'
			  . $file[0] . "})",
			'subfigure_captions' =>
			  [ map ( "\\nameref{" . root->Latex_Label($_) . "}", @$genes ) ],
			'placement' => 'tbp',
			'width'     => $temp,
			'label'     => 'fig::' . $figure_id++
		}
	);
	$text->AddText( " The data for these genes is shown in figure \\ref{"
		  . $figure->Label()
		  . "}." );
}

## Now I want to get a small description of the genes that we did identify using the trans approach!
open ( GENES ,">$outpath/selected_genes.txt") or die "I could not craete the file '$outpath/selected_genes.txt'\n$!\n";
print GENES join(" ", sort keys %$really_All_Gene_Names );
close ( GENES );

if ( $infiles[0] =~ m/_(\w+_rs\d+)/ ) {
	$rs_info = $1;
}
elsif ( $infiles[0] =~ m/_(rs\d+)/ ) {
	$rs_info = $1;
}
else {
	$rs_info = 'not known';
}

print "we try to describe the genes "
  . join( "; ", keys %$genes_2_describe ) . "\n";
$kegg_genes->Min_Genes_Per_Pathway(1);
mkdir("$outpath/temp") unless ( -d "$outpath/temp" );
warn
  "Sorry - but no gene description of KEGG pathways available at the moment!\n";

#$kegg_genes->add_LaTeX_section_for_Gene_List(
#	{
#		'LaTeX_object'           => $Latex_Document,
#		'genes'                  => [ keys %$genes_2_describe ],
#		'phenotype'              => $rs_info,
#		'kegg_reference_geneset' => $kegg_reference_geneset,
#		'temp_path'              => "$outpath/temp"
#	}
#);

foreach my $infile (@infiles) {

	@file      = split( "/", $infile );
	$table_obj = $file[ @file - 1 ];
	@file      = split( /\./, $table_obj );

	if ( $infile =~ m/.tar$/ ) {
		## OK a new data file! DAMN IT
		## 1. untar the stuff - the real filename will always be named 'purged_results.xls'
		system("tar -xf $infile --directory $outpath purged_results.xls");
		$table_obj = $stat_results->read_file("$outpath/purged_results.xls");
		unlink("$outpath/purged_results.xls");
	}
	else {
		$table_obj = $stat_results->read_file($infile);
	}
	$table_obj -> {'genes_2_describe'} = $genes_2_describe;

	$table_obj = $table_obj -> select_where( 'Gene Symbol', sub { return $genes_2_describe->{$_[0]} ; } );
	push ( @the_datasets, $table_obj->copy());
	$the_datasets[@the_datasets-1] ->  Name($file[0]);
	warn "I added the group '$file[0]' to the plottable data\n";
	#Carp::confess ("Yust a tag in case I forget to delete this killer\n". $table_obj->AsString())
}
$gene_description->add_LaTeX_section_for_Gene_List(
	{
		'LaTeX_object' => $Latex_Document,
		'genes'        => [ keys %$genes_2_describe ],
		'otherDatasets' => \@the_datasets,
	}
);

## Now I can add the $all_gene_all_models table as Appendix
$Latex_Document->Section( 'APPENDIX', 'app' )
  ->Section('Description for all analyzed genes')
  ->AddText(
'The table does show the p_value for each of the top 9 genes in every model.'
  )->Add_Table($all_gene_all_models);

## Create the max p_value distribution for the dataset
my $intro_figure;
if ( scalar( @{ $data_table->getAsArray('p value') } ) > 1 ) {
	$intro_figure = $introduction_text->Add_Figure();
	my $new_histogram = new_histogram->new();
	my @temp;
	foreach ( @{ $data_table->getAsArray('p value') } ) {
		push( @temp, -&log10($_) );
	}
	unless ( scalar(@temp) > 0 ) {
		die "OH we do not have any p values in this table:\n"
		  . $data_table->AsString();
	}
	$new_histogram->CreateHistogram( \@temp, undef, 30 );
	$new_histogram->Title('the best p value for all SNPs [-log10]');

## create the max p value distruibution for the random data (if we got any!)
	$temp = '';

	#'SNPs < 0.05' 'SNPs < 0.01' 'SNPs < 0.001' 'SNPs < 0.0001'
	my @temp2 = undef;

	if ( scalar( @{ $randomData->{'data'} } ) > 100 ) {
		foreach ( @{ $randomData->getAsArray('p value') } ) {
			push( @temp2, -&log10($_) );
		}
		shift(@temp2) unless ( defined $temp2[0] );
		$other_histogram = new_histogram->new();
		$other_histogram->CreateHistogram( \@temp2, undef, 30 );
		print "we add the random SNPs to the histogram_container\n";
		$histogram_container->AddDataArray( 'The random and T2D SNPs',
			[ @temp2, @temp ] );
		print "we add the T2D SNPs to the histogram_container\n";
		$histogram_container->AddDataArray( 'The T2D SNPs', \@temp );
		print "done with the data adding - now we go on to scaleSum21\n";
		$histogram_container->scaleSum21();
		print "and now we plot\n";
		$histogram_container->plot(
			$outpath . "/p_value_overlay_rescaled.svg" );
		$other_histogram->Title('man p value distribution for the random SNPs');
		$quantil_cutoff = root->quantilCutoff( \@temp2, 95 );
		$other_histogram->Mark_position( $quantil_cutoff, 'red' );
		$histogram_container->Mark_position( $quantil_cutoff, 'red' );
		$temp =
		  $appendix->AddText( 'The best correlated genes for a set of '
			  . scalar(@temp2)
			  . ' random SNPs.' . "\n"
			  . 'After the analysis of this dataset you might want to apply a p_value cut off of '
			  . ( 10**-$quantil_cutoff )
			  . " to the data ($quantil_cutoff)." );
		$randomData->write_file(
			"$outpath/random_SNPs_best_correlating_gene.txt");
		$temp->Add_Table($randomData);
		$new_histogram->Mark_position( $quantil_cutoff, 'red' );
	}
## plot the distribution
	$new_histogram->plot(
		{
			'x_title'      => 'p_value [-log10]',
			'y_title'      => 'total number of group names',
			'x_resolution' => 500,
			'y_resolution' => 400,
			'outfile'      => $outpath . "/p_value_histogram.svg"
		}

	);
}
## plot the control distribution
if ( defined $other_histogram ) {
	$other_histogram->plot(
		{
			'x_title'      => 'p_value [-log10]',
			'y_title'      => 'total number of group names',
			'x_resolution' => 500,
			'y_resolution' => 400,
			'outfile'      => $outpath . "/p_value_random_SNP_histogram.svg"
		}
	);
	$intro_figure->AddPicture(
		{
			'files' => [
				$outpath . "/p_value_histogram.svg",
				$outpath . "/p_value_random_SNP_histogram.svg",
				$outpath . "/p_value_overlay_rescaled.svg"
			],
			'caption' =>
			  "The distribution of the p value for the best correlating gene 
		for each of the SNPs. The propsed P value cut off is marked by a red bar. ",
			'subfigure_captions' => [
				'the distribution for the T2D SNPs.',
				'the distribotion for the '
				  . scalar( @{ $randomData->{'data'} } )
				  . ' random SNPs. The data can be found in section \\ref{'
				  . $appendix->Lable() . '}.',
				'Overlay of the other two figures as probability distributions.'
			]
		}
	);
}
elsif ( defined $intro_figure ) {
	$intro_figure->AddPicture(
		{
			'files' => [ $outpath . "/p_value_histogram.svg" ],
			'caption' =>
			  "The distribution of the p value for the best correlating gene 
		for each of the SNPs.",
			'width' => '0.4',
		}
	);
}

my $tex_file = $Latex_Document->write_tex_file('the_9_best_correlating_genes');
#$all_results->define_subset( 'analysis_data', \@data_columns );
#$all_results->calculate_on_columns(
#	{
#		'function' => sub {
#			my $good_05   = 0;
#			my $good_01   = 0;
#			my $good_001  = 0;
#			my $good_0001 = 0;
#			for ( my $i = 0 ; $i < @_ ; $i++ ) {
#				if ( defined $_[$i] ) {
#					$_[$i] =~ s/,/./g;
#					$good_05++;
#					if ( $_[$i] <= 0.01 ) {
#						$good_01++;
#					}
#					if ( $_[$i] <= 0.001 ) {
#						$good_001++;
#					}
#					if ( $_[$i] <= 0.0001 ) {
#						$good_0001++;
#					}
#				}
#			}
#			$! = undef;
#			return join( ";", ( $good_05, $good_01, $good_001, $good_0001 ) );
#		},
#		'data_column'   => 'analysis_data',
#		'target_column' => 'significant_SNPs'
#	}
#);
#$all_results->Add_2_Description( 'we have a total of ',
#	scalar(@data_columns) . "SNPs analyzed" );
#
#my $data_table = data_table->new();
#$data_table->Add_2_Header('p_value cutoff');
#$data_table->Add_2_Header('significant_SNPs');
#$data_table->Add_2_Header('not_significant_SNPs');
#$data_table->Add_2_Header('identified genes');
#
#my ( $hash, @line, @cutoffs, $cutoff );
#@cutoffs = ( '0.05', '0.01', '0.001', '0.0001' );
#foreach (@cutoffs) {
#	$hash->{$_} = {};
#}
#
#foreach ( @{ $all_results->getAsArray("significant_SNPs") } ) {
#	@line = split( ";", $_ );
#	for ( $cutoff = 0 ; $cutoff < 4 ; $cutoff++ ) {
#		$hash->{ $cutoffs[$cutoff] }->{ $line[$cutoff] } = 0
#		  unless ( defined $hash->{ $cutoffs[$cutoff] }->{ $line[$cutoff] } );
#		$hash->{ $cutoffs[$cutoff] }->{ $line[$cutoff] }++;
#	}
#}
#
#foreach $cutoff ( sort { $a <=> $b } keys %$hash ) {
#	foreach ( sort { $b <=> $a } keys %{ $hash->{$cutoff} } ) {
#		$data_table->AddDataset(
#			{
#				'p_value cutoff'       => $cutoff,
#				'significant_SNPs'     => $_,
#				'not_significant_SNPs' => scalar(@data_columns) - $_,
#				'identified genes'     => $hash->{$cutoff}->{$_}
#			}
#		);
#	}
#}
#
#$data_table->write_file(
#	$outpath . "/summary_over_all_results_crude_first_analysis.txt" );
#$all_results->write_file( $outpath . "/summary_over_all_results.txt" );
print "to get a quick overview compile the tex file $tex_file\n";

sub log10 {
	my ($value) = @_;
	Carp::confess("You must not give me a value <= 0 to take the log from\n")
	  unless ( $value > 0 );
	return log($value) / log(10);
}
