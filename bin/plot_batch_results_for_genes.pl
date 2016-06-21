#! /usr/bin/perl -w

#  Copyright (C) 2010-11-18 Stefan Lang

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

=head1 plot_batch_results_for_genes.pl

A tool to plot the graphics for a list of genes.

To get further help use 'plot_batch_results_for_genes.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::stat_results;
use stefans_libs::Latex_Document;
use stefans_libs::array_analysis::table_based_statistics::group_information;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,       $debug,            $database,
	@infiles,    $outpath,          $kegg_reference_geneset,
	$shift_axes, $introduction_str, $grouping_file, $latex_title,
	$bar_graph,  @genes, $force
);

Getopt::Long::GetOptions(
	"-infiles=s{,}"             => \@infiles,
	"-outpath=s"                => \$outpath,
	"-genes=s{,}"               => \@genes,
	"-bar_graph"                => \$bar_graph,
	"-latex_title=s"            => \$latex_title,
	"-introduction=s"           => \$introduction_str,
	"-shift_axes"               => \$shift_axes,
	"-kegg_reference_geneset=s" => \$kegg_reference_geneset,
	"-help"                     => \$help,
	"-force"                    => \$force,
	"-grouping_file=s"            => \$grouping_file,
	"-debug"                    => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infiles[0] ) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $genes[0] ) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
elsif ( -f $genes[0] ) {
	open( IN, "<$genes[0]" ) or die "could not open genes file $genes[0]\n";
	my @temp;
	while (<IN>) {
		chomp($_);
		push( @temp, split( /\s/, $_ ) );
	}
	shift(@temp) unless ( defined $temp[0] );
	close(IN);
	@genes = @temp;
}

unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( !-d $outpath ) {
	mkdir($outpath) or die "I could not create the outpath $outpath\n$!\n";
}

unless ( defined $kegg_reference_geneset ) {
	$error .= "the cmd line switch -kegg_reference_geneset has to be given!\n";
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
 command line switches for plot_batch_results_for_genes.pl

   -infiles       :a list of batch result files
   -outpath       :where to plot the figures to
   -bar_graph     :if you set that option you will not get whisker plots, 
                   but bar graphs with std
   -genes         :the list of genes you want to have described
   -latex_title   :the title of the latex file
   -introduction  :a short introduction of what we have analyzed here
   -shift_axes    :use that option without value if you want 
                   the expression for XY plot on the x instead of the y axis 
                   
   -kegg_reference_geneset :if you want to add a KEGG statistics part I need a
                            reference gene list that you previously did match
                            to the KEGG pathways (e.g. 'HUGene_v1')
                            
   -grouping_file :The file that you used to for the statistics analysis using either
                   batchStatistics.pl or the second version of that file
   
   -force :re-create all figure files (very time consuming and useless 
           if you use the same settings)
                   
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/plot_batch_results_for_genes.pl';
$task_description .= ' -infiles ' . join( ' ', @infiles )
  if ( defined $infiles[0] );
$task_description .= " -outpath $outpath" if ( defined $outpath );
$task_description .= " -bar_graph" if ($bar_graph);
$task_description .= " -genes " . join( " ", @genes ) if ( defined $genes[0] );
$task_description .= " -latex_tile '$latex_title'" if ( defined $latex_title );
$task_description .= " -introduction '$introduction_str'"
  if ( defined $introduction_str );
$task_description .= " -kegg_reference_geneset '$kegg_reference_geneset'"
  if ( defined $kegg_reference_geneset );
$task_description .= " -shift_axes" if ($shift_axes);
$task_description .= " -grouping_file $grouping_file"
  if ( defined $grouping_file );
  $task_description .= " -force" if ( $force );
  
print "$task_description\n";
## Do whatever you want!

open ( LOG , ">$outpath/plot_batch_results_for_genes.creation.log") or die "Sorry, but I could not create the log file '$outpath/plot_batch_results_for_genes.creation.log'\n$!\n";
print LOG $task_description."\n";
close ( LOG );
my (
	$infile,       $table_obj,      @file,     $temp,
	$stat_results, $Latex_Document, $genes,    $figure_files,
	$results_sec,  $temp_sec,       $into_sec, $figure_obj,
	$text,         $temp_width,     @not_good, $line_Hash
);

foreach (@genes) {
	$genes->{$_} = 1;
}

my $data_table = data_table->new();
foreach ( 'correlating Data', 'affected gene', 'p value' ) {
	$data_table->Add_2_Header($_);
}

$Latex_Document = stefans_libs::Latex_Document->new();
$Latex_Document->Outpath($outpath);
$latex_title =
  'Analysing the Influence of the T2D SNPs in for ' . scalar(@genes) . " genes"
  unless ( defined $latex_title );
$latex_title =~ s/_/ /g;
$Latex_Document->Title($latex_title);
$Latex_Document->Author('Stefan Lang');
$into_sec = $Latex_Document->Section('Introduction');

$introduction_str =
    "There was a special interest in the genes "
  . join( ", ", @genes )
  . ". Therefore we analyzed the trans effect of all the SNPs mentioned in the results section on the expression of these genes."
  unless ( defined $introduction_str );

$into_sec->AddText( $introduction_str
	  . "The here shown table is a summay for the best correlating gene for each phenotype. A phenotype could be a SNP or any clinical measurement."
)->Add_Table($data_table);


#$into_sec->AddText($introduction_str ) if ( defined $introduction_str);

my ( $gene_description, $kegg_genes, $rs_info );
$gene_description = gene_description->new( variable_table->getDBH() );
$kegg_genes       = kegg_genes->new( $gene_description->{'dbh'} );


$results_sec = $Latex_Document->Section('Results');
my $figure_id = 1;
$stat_results = stat_results->new();
my ($actual_genes, $table);
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
	
	$temp =
	  $table_obj->select_where( 'Gene Symbol',
		sub { return 1 if ( $genes->{ $_[0] } ); return 0 } ) ->Sort_by( [ ['p-value', 'numeric']]);
	$temp_sec = $results_sec->Section( $file[0] );
	if ( scalar( @{ $temp->{'data'} } ) == 0 ) {
		push( @not_good, $file[0] );
		next;
	}
	$text =
	  $temp_sec->AddText( "For the SNP comparison we could identify "
		  . scalar( @{ $temp->{'data'} } )
		  . " genes out of the "
		  . scalar(@genes)
		  . " you were intersted in to pass a p_value of 0.05." );
	if ( ref($temp) =~ /Spearman_result/ ) {
		$temp->Shift_Axes($shift_axes);
		$figure_files = $temp->plot( $outpath . "/" . $file[0], $file[0] ) ;
	}
	else  {
		$figure_files = $temp->plot( $outpath . "/" . $file[0], $file[0], $bar_graph ) ;
	}


	$temp_width = '';
	if ( scalar( @{ $temp->{'data'} } ) < 5 ) {
		$temp_width = 0.66;
	}
	if ( scalar( @{ $temp->{'data'} } ) < 2 ) {
		$temp_width = 0.33;
	}
	$actual_genes = {};
	for ( my $a = 0 ; $a < @{ $temp->{'data'} } ; $a++ ) {
		$line_Hash = $temp->get_line_asHash($a);
		$data_table->AddDataset(
			{
				'correlating Data' => $file[0],
				'affected gene'    => $line_Hash->{'Gene Symbol'},
				'p value'          => $line_Hash->{'p-value'}
			}
		);
		$actual_genes -> {$line_Hash->{'Gene Symbol'}} = 1;
	}

	$figure_obj = $text->Add_Figure();
	$figure_obj->AddPicture(
		{
			'placement' => 'tbp',
			'files'     => $figure_files,
			'caption' =>
"The gene expression of thise genes, that show a significant influence from the correlating dataset $file[0].",
			'subfigure_captions' => $temp->getAsArray('Gene Symbol'),
			'label'              => 'fig::' . $figure_id++,
			'width'              => $temp_width
		}
	);
	$text->AddText( " The data for the genes is shown in figure \\ref{"
		  . $figure_obj->Label()
		  . "}." );
	$table = $kegg_genes->__gene_hits_for_each_KEGG_pathway(
			$kegg_genes->__get_table_for_gene_list( [ keys %$actual_genes],$kegg_reference_geneset ) 
		);
	
	$text->AddText(
"The genes, that were selected have been matched against the KEGG pathways. The matching pathways and patizipating genes are shown in the following table."
	  )->Add_Table( $table );
}

$into_sec->AddText(
	    scalar(@not_good)
	  . " SNPs from the initial set of "
	  . scalar(@infiles)
	  . " SNPs did not show a significant correlateion to any of the genes you were intersted in."
	  . " For all other SNPs I have sumed up the results in the results section! "
	  . "The following SNPs did not infulence any of your genes of interest: \n\n"
	  . join( "\n\n ", @not_good )
	  . "\n" )
  if ( scalar(@not_good) > 0 );

$kegg_genes->Min_Genes_Per_Pathway(1);
mkdir("$outpath/temp") unless ( -d "$outpath/temp" );
$rs_info = "uselessInfo";
$kegg_genes->add_LaTeX_section_for_Gene_List(
	{
		'LaTeX_document'           => $Latex_Document,
		'LaTeX_object' =>
			  $Latex_Document->Section( 'KEGG analysis'),
		'genes'                  => [ @genes ],
		'phenotype'              => $rs_info,
		'kegg_reference_geneset' => $kegg_reference_geneset,
		'temp_path'              => "$outpath/temp"
	}
);
$gene_description->add_LaTeX_section_for_Gene_List(
	{
		'LaTeX_object' => $Latex_Document,
		'genes'        => [ @genes ]
	}
);
if ( defined $grouping_file ) {
	$into_sec->AddText(
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


$Latex_Document->write_tex_file(
	$outpath . "/Genes_Of_Interest_T2D_SNP_Influence" );
