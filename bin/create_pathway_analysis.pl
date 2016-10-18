#! /usr/bin/perl -w

#  Copyright (C) 2013-07-23 Stefan Lang

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

=head1 create_pathway_analysis.pl

Create a light wight pathway analysis based on GSEA gtm files and a Gene Symbol list.

To get further help use 'create_pathway_analysis.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::Latex_Document;
use stefans_libs::database::genomeDB::gene_description;
use stefans_libs::file_readers::GSEA_Pathways;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,          $debug,            $database, @pathways,
	@genes,         $gene_description, $outfile,  $upper_case,
	$no_gene_descr, $filemap,          $homology_file, $background_list
);

Getopt::Long::GetOptions(
	"-pathways=s{,}"      => \@pathways,
	"-genes=s{,}"         => \@genes,
	"-outfile=s"          => \$outfile,
	"-gene_description=s" => \$gene_description,
	"-background_list=s"  => \$background_list,
	"-upper_case"         => \$upper_case,
	"-no_gene_descr"      => \$no_gene_descr,
	"-homology_file=s"    => \$homology_file,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $pathways[0] ) {
	$error .= "the cmd line switch -pathways is undefined!\n";
}
unless ( defined $genes[0] ) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
else {
	$filemap = root->filemap($outfile);
	unless ( -d $filemap->{'path'} ) {
		system("mkdir -p $filemap->{'path'}");
	}
}
unless ( defined $gene_description ) {
	$error .= "the cmd line switch -gene_description is undefined!\n";
}
unless ( -f $background_list ) {
	$error .= "the cmd line switch -background_list not a file!\n";
}
if ( $upper_case ) {
	if ( ! -f $homology_file ){
		$homology_file = "/home/slang/Documents/Projekte/Pathways/Homology_DB/HMD_HumanPhenotype.rpt"
	}
	open ( IN, "<$homology_file" ) or die "You obviousely try to convert mouse to human gene symbols. But I can not find the homology table '$homology_file'\n";
	my (@line);
	$homology_file = {};
	while ( <IN> ){
		chomp($_);
		@line = split("\t",$_);
		$homology_file->{$line[3]} = $line[0];
	}
	close ( IN );
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
 command line switches for create_pathway_analysis.pl

   -pathways         :a list of pathway definition files like the GSEA program uses (Gene Symbol based)
   -genes            :a list of genes you want to check for pathway association
   -outfile          :the outfile you want to produce
   -gene_description :a detailed description of how you got this gene list
   -background_list  :a list of all possible genes
   -upper_case       :in case you have mouse data, but want to analyse also Hunam pathways use this option
   -no_gene_descr    :do not fetch description for the egnes from GeneCards.org

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/create_pathway_analysis.pl';
$task_description .= ' -pathways ' . join( ' ', @pathways )
  if ( defined $pathways[0] );

$task_description .= " -background_list $background_list"
  if ( defined $background_list );
$task_description .= " -upper_case"
  if ($upper_case);
$task_description .= " -no_gene_descr"
  if ($no_gene_descr);

if ( -f $genes[0] ) {
	open( IN, "<$genes[0]" ) or die $_;
	my ( $hash, $gene_list, @temp, $extension, @path, $filename, $cmp );
	$gene_list = 0;
	while (<IN>) {
		next if ($_ =~m/^#/);
		if ( $_ =~ m/^gene_lists$/ ) {

			#	die "I am going to give you some more inforamtion.\n";
			## oh oh - you have given me a summary gene file, that contains the overview over a list of statistic results.
			## I am going to start multiple versions this script!
			$gene_list = 1;
			@path      = split( "/", $outfile );
			$filename  = pop(@path);
			open( LOG, ">$filemap->{'path'}/create_pathway_analysis.log" )
			  or die "I could not create the log file!\n$!\n";
			print LOG $task_description
			  . " -gene_description '$gene_description'"
			  . " -outfile $outfile"
			  . ' -genes "'
			  . join( '" "', @genes ) . '"' . "\n";
			close(LOG);
			open ( MAKE, ">$filemap->{'path'}/Makefile");
			print MAKE "all:\n";
			next;
		}
		chomp($_);
		if ($gene_list) {
			## each line contains a marker on $temp[0] and a list of genes on all other temps
			@temp = split( /\s+/, $_ );
			if ( @temp > 1 && @temp < 10001 ) {
				print "For statistic test $temp[0] I analyze "
				  . ( scalar(@temp) - 2 )
				  . " genes.\n";
				$cmp = shift(@temp);
				$genes[0] = join( "/",
					$filemap->{'path'}, $cmp,
					$cmp . "_" . $filemap->{'filename_core'} );
				mkdir (join( "/",$filemap->{'path'}, $cmp ));
				open (GENES ,">".join( "/",$filemap->{'path'}, $cmp, 'Genes.txt' ) );
				print GENES "#$cmp; ".scalar(@temp). " genes:\n".join(" ", @temp);
				close ( GENES);
				open (CALL ,">".join( "/",$filemap->{'path'}, $cmp,'program_call.sh'));
				print CALL $task_description
					  . " -outfile $genes[0] -genes "
					  . join( "/",$filemap->{'path'}, $cmp, 'Genes.txt' ) 
					  . " -gene_description '$gene_description This analysis is focused on the results for the comparison $cmp.'\n";
				close ( CALL );
				system( $task_description
					  . " -outfile $genes[0] -genes "
					  . join( "/",$filemap->{'path'}, $cmp, 'Genes.txt' ) 
					  . " -gene_description '$gene_description This analysis is focused on the results for the comparison $cmp.'  > /dev/null 2> /dev/null"
				);
				print MAKE "\tmake all -C ".join( "/",$filemap->{'path'}, $cmp)."\n";
				print "Done - data in $genes[0]\n";
			}
			else {
				print
"Less than 4 genes or more than 10 000 for analysis $temp[0] - no pathway analysis (n=".scalar(@temp).").\n";
			}
		}
		else {
			foreach ( split( /[\s,;]+/, $_ ) ) {
				$hash->{$_} = 1 if ( $_ =~ m/\w/ );
			}
		}

	}
	close(IN);
	if ( $gene_list ){
		close ( MAKE );
		die "I have analysed all data\n\nYou should run the make script in path $filemap->{'path'}\n"."make all -C $filemap->{'path'}\n";
	}
	
	@genes = ( sort( keys %$hash ) );
}
for ( my $i = 0 ; $i < @genes ; $i++ ) {
	$genes[$i] = $1 if ( $genes[$i] =~ m/I?L?M?N?_?\d+_([\w\d\.\/\@\-]+)/ );
}


$task_description .= " -gene_description '$gene_description'"
  if ( defined $gene_description );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= ' -genes "' . join( '" "', @genes ) . '"'
  if ( defined $genes[0] );

print $task_description."\n";
die "Sorry I did not get any gene to analyse!\n" unless ( defined $genes[0] );

open( LOG, ">$outfile.PERL.log" )
  or die "I could not create the log file!\n$!\n";
print LOG $task_description . "\n";
close(LOG);
print $$. $task_description . "\n";

my $Latex_Document = stefans_libs::Latex_Document->new();
$Latex_Document->Title("Pathways analysis of a user defined list of genes.");
$Latex_Document->Author("Stefan Lang (Lang Bioinformatics AB)");

$Latex_Document->Section('Materials');
$Latex_Document->Section('Results');
$Latex_Document->Section('Materials')->Section('Genes')
  ->AddText( $gene_description
	  . "\n\nThe genes are defined in more deatail in the appendix.\n" );
$Latex_Document->Section('Materials')->Section('Genes')
  ->AddText(
"WARNING!\n\nThe gene symbols were transformed to upper case for this analysis!\n\nWARNING!"
  ) if ($upper_case);
$Latex_Document->Section('Appendix')->Section('Program call')
  ->AddText($task_description);

if ($upper_case) {
	for ( my $i = 0 ; $i < @genes ; $i++ ) {
		unless ( defined $homology_file->{$genes[$i]}){
			warn "gene $genes[$i] has no homology!\n";
			next;
		}
		$genes[$i] = $homology_file->{$genes[$i]};
	}
}
my ( $p_value, @temp );
foreach my $pathway_list (@pathways) {
	my $Pathways =
	  stefans_libs::file_readers::GSEA_Pathways->new($pathway_list);
	@temp = split( "/", $pathway_list );
	$pathway_list = pop(@temp);
	$Pathways->load_background($background_list);
	my $data_table = $Pathways->analyse_genes( \@genes );
	##'max_count' 'bad_entries' 'matched genes' 'pathway_name' 'gene list'
	$data_table->make_column_LaTeX_p_type( 'pathway_name', '3cm' );
	$data_table->make_column_LaTeX_p_type( 'gene list',    '4cm' );
	my $temp = $data_table->Header_Position('gene list');

	#my $temp1 = $data_table->Header_Position('pathway_name');
	for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
		@{ @{ $data_table->{'data'} }[$i] }[$temp] = "\\nameref{"
		  . join( "} \$^*\$ \\nameref{",
			@{ @{ @{ $data_table->{'data'} }[$i] }[$temp] } )
		  . "} \$^*\$";
	}
	$data_table =
	  $data_table->Sort_by( [ [ 'hypergeometric p value', 'numeric' ] ] );
	$data_table = $data_table->select_where( 'hypergeometric p value',
		sub { return $_[0] != 1.2 } );
	$data_table->define_subset( 'html',
		[ 'pathway_name', 'hypergeometric p value', 'gene list' ] );
	$data_table->define_subset(
		'app',
		[
			'pathway_name',  'hypergeometric p value',
			'matched genes', 'max_count',
			'bad_entries',
		]
	);
	my $app_table = $data_table->GetAsObject('app');
	$app_table->make_column_LaTeX_p_type( 'pathway_name', '3cm' );
	$data_table = $data_table->GetAsObject('html');
	$p_value = 0.05 / $data_table->Lines() if ( $data_table->Lines() > 0 );
	my $significant = $data_table->select_where( 'hypergeometric p value',
		sub { return $_[0] < $p_value } );

	$significant->make_column_LaTeX_p_type( 'pathway_name', '3cm' );
	$significant->make_column_LaTeX_p_type( 'gene list',    '7cm' );
	$data_table->make_column_LaTeX_p_type( 'pathway_name', '3cm' );
	$data_table->make_column_LaTeX_p_type( 'gene list',    '7cm' );
	if ( $significant->Lines()) {
	$Latex_Document->Section('Results')->Section($pathway_list)
	  ->AddText(
		"You have used the pathways from the file $pathway_list and obtained "
		  . $significant->Lines()
		  . " significant results (p less than "
		  . sprintf( "%.1E", $p_value )
		  . "; Bonferroni corrected 0.05 significance level).\n"
		  . "I used a hypergeometric test implemented in Perl to access significances.\n"
		  . "The significant results are shown in the following table, all results as well as the variables for the statistic test can be found in the Appendix.\n"
	  )->AddTable($significant);
	}
	else {
		my $significant = $data_table->select_where( 'hypergeometric p value',
		sub { return $_[0] <= 0.01 } );
		$significant->make_column_LaTeX_p_type( 'pathway_name', '3cm' );
		$significant->make_column_LaTeX_p_type( 'gene list',    '7cm' );
		$Latex_Document->Section('Results')->Section($pathway_list)
	  ->AddText(
		"You have used the pathways from the file $pathway_list and obtained "
		  . $significant->Lines()
		  . " significant results (p less than 0.01"
		  . "; NOMINAL not corrected p value).\n"
		  . "This relaxed p value cutoff has been used as not a single pathway passed the "
		  . sprintf( "%.1E", $p_value ). " Bonferroni corrected 0.05 significance level.\n"
		  . "I used a hypergeometric test implemented in Perl to access significances.\n"
		  . "The significant results are shown in the following table, all results as well as the variables for the statistic test can be found in the Appendix.\n"
	  )->AddTable($significant);
	}
	$Latex_Document->Section('Appendix')
	  ->Section("All results for Pathways in file $pathway_list")
	  ->AddText(
		"You have used the pathways from the file $pathway_list and obtained "
		  . $data_table->Lines()
		  . " nominaly significant results (p less than 0.05).\n\n"
		  . "This is the documentation the Perl library has generated: "
		  . $Pathways->{'description'}
		  . "\n\nThe whole table is not shown here." );
	  #->AddTable($data_table);

	#$Latex_Document->Section('Appendix')->Section("All results for Pathways in file $pathway_list")->Section('Statistics Values') ->AddText('The statistic values')->AddTable($app_table)
}

my $gene_description_obj = gene_description->new( variable_table->getDBH() );
$gene_description_obj->DoNotConnect2WWW($no_gene_descr);
$gene_description_obj->add_LaTeX_section_for_Gene_List(
	{
		'LaTeX_object' => $Latex_Document->Section('Appendix'),
		'genes'        => \@genes,
	}
);

$Latex_Document->write_tex_file($outfile);

