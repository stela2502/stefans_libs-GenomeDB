package gene_description;

#  Copyright (C) 2008 Stefan Lang

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

use strict;
use warnings;
use stefans_libs::database::genomeDB::gene_description::gene_aliases;
use WWW::Mechanize;
use stefans_libs::database::genomeDB::gene_description::genes_of_importance;
use stefans_libs::database::variable_table;
use HTML::TreeBuilder;
use stefans_libs::Latex_Document;
use base ('variable_table');
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);

sub new {

	my ( $class, $dbh, $debug ) = @_;

	unless ( ref($dbh) eq "DBI::db" ) {
		$dbh = variable_table->getDBH();
	}

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug,
		'DEBUG' =>
		  0,    ## set this variable manually to debug the web page parsing!
		'mech' => WWW::Mechanize->new( 'stack_depth' => 0 ),
		'__do_not_connect_2_www___' => 0,
		'qualification_hashes'      => {
			'T2D' => {
				'wnt'                            => 1,
				'gaba'                           => 10,
				'gad'                            => 10,
				'endocyto'                       => 1,
				'exocyto'                        => 1,
				'mitochondria'                   => 10,
				'endoplasmatic'                  => 1,
				'golgy'                          => 1,
				'vesicle'                        => 1,
				'zymogen'                        => 1,
				'glucose'                        => 10,
				'metabolism'                     => 10,
				'channel'                        => 10,
				'diabetes'                       => 100,
				'calcium'                        => 10,
				'potassium'                      => 10,
				'membrane potential'             => 10,
				'exocytosis'                     => 10,
				'insulin'                        => 10,
				'fat '                           => 10,
				'fatty acid'                     => 10,
				'carbohydrat'                    => 10,
				'glycolysis'                     => 10,
				'apoptos'                        => 1,
				'cancer'                         => 1,
				'cancers'                        => 1,
				'chromatin'                      => 1,
				'transcription factor'           => 3,
				'transport'                      => 1,
				'atp'                            => 1,
				'syndrome'                       => 10,
				'neuro'                          => 1,
				'golgi'                          => 1,
				'endoplasmatic reticulum'        => 1,
				'actin'                          => 1,
				'microtubu'                      => 1,
				'coa'                            => 1,
				'cell cycle'                     => 1,
				'cytoskeleton'                   => 1,
				'nf-kappa-b'                     => 1,
				'beta-cell'                      => 10,
				'paxillin'                       => 1,
				'focal adhesions'                => 1,
				'no information *no information' => 1

			}
		}
	};

	bless $self, $class if ( $class eq "gene_description" );

	$self->init_tableStructure();

	return $self;

}

=head2 get_Latex_Gene_description

arguments:
{ 
	'header_level' => (one of 0 = section; 1= subsection, ...),
	'genes' => [ 'gene_symbol_1', 'gene_symbol_2', ...],
	'desease' => 'T2D' ## has to be defined as 'qualification_hash' - see source code....
	'otherDatasets' => [ list of data_table objects that contain correlation results] 
}

=cut

sub get_Latex_Gene_summary {
	my ( $self, $hash, $label ) = @_;

	my ( $result, $latex_summary, $section_str, $temp, $latex_description );
	$hash->{'header_level'} = 0 unless ( defined $hash->{'header_level'} );
	$section_str = 'section';
	for ( my $i = 0 ; $i < $hash->{'header_level'} ; $i++ ) {
		$section_str = "sub$section_str";
	}
	$latex_summary .=
	  "\\" . $section_str . "{Estimating the importance of the genes}\n";
	$latex_summary .= "\\label{" . root->Latex_Label($label) . "}\n"
	  if ( defined $label );
	$result = $self->_get_summary_datastructure($hash);

	if ( defined $result->{'summary'} ) {

		$latex_summary .=
"\nAs you have requested to estimate the influence of each of the genes on the desease $hash->{desease},\n"
		  . "the genes could be grouped into certain groups:\n";
		$latex_summary .= "\\begin{itemize}\n";
		foreach my $tag ( sort keys %{ $result->{'summary'} } ) {
			$temp = '';
			foreach ( keys %{ $result->{'summary'}->{$tag} } ) {
				$temp .= "\\nameref{" . root->Latex_Label($_) . "}, ";
			}
			$temp =~ s/, $/\n/;
			if ( $temp =~ m/\w/ ) {

				#$temp = substr( $temp, 2,length($temp) -2 );
			}
			else {
				$temp = '';
			}
			$latex_summary .= "\\item $tag \n\n" . "Genes: $temp\n";
		}
		$latex_summary .= "\\end{itemize}\n\n";
	}
	return $latex_summary;
}

sub __get_section_string {
	my ( $self, $hash ) = @_;
	$hash->{'header_level'} = 0 unless ( defined $hash->{'header_level'} );
	my $section_str = 'section';
	for ( my $i = 0 ; $i < $hash->{'header_level'} ; $i++ ) {
		$section_str = "sub$section_str";
	}
	return $section_str;
}

=head2 add_LaTeX_section_for_Gene_List ( {
	'LaTeX_object' => stefans_libs::Latex_Document::Section,
	'genes' =>   [@genes],
	'otherDatasets' => <an array of stat results>
})

I will take the gene list and create populate a subsection in the LaTeX object with the gene information. 
The subsection will be called 'Gene Descriptions' and will contain one subsubsection for each gene.

=cut

sub __get_new_data_table {
	my ($self) = @_;
	my $data_table = data_table->new();
	foreach ( 'Correlating dataset', 'Probe Set ID', 'p value', 'rho',
		'fold change' )
	{
		$data_table->Add_2_Header($_);
	}
	return $data_table;
}

sub add_LaTeX_section_for_Gene_List {
	my ( $self, $hash ) = @_;

	my ( $result, $latex_summary, $section_str, $temp, $gene_section,
		$data_hash );

	$result = $self->_get_summary_datastructure($hash)
	  ;    ## that will process only the genes part!
	delete( $result->{'summary'} );
	my $section =
	  $hash->{'LaTeX_object'}
	  ->Section( 'Gene descriptions', 'geneDescription' );

	foreach my $gene ( sort keys %$result ) {
		$gene_section = $section->Section( $gene, root->Latex_Label($gene) );
		if (   defined $result->{$gene}->{'matchingStrings'}
			&& defined $hash->{desease} )
		{
			$temp =
			  "The genes has an arbitray $hash->{desease} score of "
			  . $result->{$gene}->{'score'} . "."
			  if ( defined $result->{$gene}->{'score'} );
			if ( $result->{$gene}->{'score'} > 0 ) {
				$temp .=
"The score was calculated by matching these strings to the description of the gene: "
				  . $result->{$gene}->{'matchingStrings'} . "\n";
			}
			$gene_section->AddText($temp);
		}

		$temp =
		    "We recovered this description from \\href{"
		  . $self->get_href_for_gene($gene)
		  . "}{GeneCards:$gene} :\\\\\n";
		$result->{$gene}->{'summary'} =~ s/\%/\\\%/g;
		$result->{$gene}->{'summary'} =~ s/ \& / \\\& /g;
		$result->{$gene}->{'summary'} =~ s/_/\_/g;
		$temp .= "$result->{$gene}->{'summary'}.\n\n";

		$temp =~ s/\&quot;framework\&quot;//g;
		$temp =~ s/\&quot;//g;
		$temp =~ s/\&lt;//g;
		$temp =~ s/\&gt;//g;

		$gene_section->AddText($temp);

		my $data;
		if ( ref( $hash->{'otherDatasets'} ) eq "ARRAY" ) {
			my $data_table = $self->__get_new_data_table();
			foreach my $dataSet ( @{ $hash->{otherDatasets} } ) {
				$data_hash = {};
				foreach my $row_number (
					$dataSet->get_rowNumbers_4_columnName_and_Entry(
						'Gene Symbol', $gene
					)
				  )
				{
					$data = $dataSet->get_line_asHash($row_number);
					$data_hash->{'p value'} = $data->{'p-value'};
					$data_hash->{'p value'} = $data->{'p value'}
					  if ( defined $data->{'p value'} );

					#$data_hash->{'p value'}= sprintf( "%.3f", $data->{'rho'} );
					unless ( defined $data->{'rho'} ) {
						$data->{'rho'} = '';
					}
					elsif ( $data->{'rho'} =~ m/\d/ ) {
						$data->{'rho'} = sprintf( "%.3f", $data->{'rho'} );
					}

					unless ( defined $data->{'fold change'} ) {
						$data->{'fold change'} = '';
					}
					elsif ( $data->{'fold change'} =~ m/\d/ ) {
						$data->{'fold change'} =
						  sprintf( "%.3f", $data->{'fold change'} );
					}
					$data->{'Probe Set ID'} = '--'
					  unless ( defined $data->{'Probe Set ID'} );
					$data_hash->{'Probe Set ID'} = $data->{'Probe Set ID'};
					$data_hash->{'rho'}          = $data->{'rho'};
					$data_hash->{'fold change'}  = $data->{'fold change'};
					$data_hash->{'Correlating dataset'} = $dataSet->Name();
					$data_table->Add_Dataset($data_hash);
					print root::get_hashEntries_as_string (
						$data_hash, 3,
						"I have added the values here to the data table:"
					);
				}
			}
			if ( $data_table->Lines > 0 ) {
				$gene_section->AddText( "As we have some correlation datasets, "
					  . "we have the possibility to add the correlation results for these:\n"
				)->Add_Table($data_table);
			}
		}
		my ($filename);
	}
	return $section;
}

sub get_Latex_Gene_description {
	my ( $self, $hash ) = @_;
	my $LaTeX_object = stefans_libs::Latex_Document->new();
	$hash->{'header_level'} = 0 unless ( defined $hash->{'header_level'} );
	return $self->add_LaTeX_section_for_Gene_List(
		{
			'LaTeX_object'  => $LaTeX_object,
			'genes'         => $hash->{'genes'},
			'otherDatasets' => $hash->{'otherDatasets'}
		}
	)->AsString( $hash->{'header_level'} );
}

sub _get_summary_datastructure {
	my ( $self, $hash ) = @_;
	my ($result);
	foreach my $gene ( @{ $hash->{genes} } ) {
		$result->{$gene} = {};
		(
			$result->{$gene}->{'summary'},
			$result->{$gene}->{'score'},
			$result->{$gene}->{'matchingStrings'}
		  )
		  = $self->determineInfluence_of_gene_on_desease( $gene,
			$hash->{'desease'} );
		if ( defined( $hash->{'desease'} )
			&& !( defined $result->{$gene}->{'score'} ) )
		{
			Carp::confess(
				    ref($self)
				  . "we did not get the arbitrary influence on the desease $hash->{'desease'} - please check that!\n"
				  . "$result->{$gene}->{'summary'}\n$result->{$gene}->{'matchingStrings'}\n"
			);
		}
		if ( defined $result->{$gene}->{'matchingStrings'} ) {
			$result->{'summary'} = {} unless ( defined $result->{'summary'} );
			$result->{'summary'}->{ $result->{$gene}->{'matchingStrings'} } = {}
			  unless (
				defined $result->{'summary'}
				->{ $result->{$gene}->{'matchingStrings'} } );
			$result->{'summary'}->{ $result->{$gene}->{'matchingStrings'} }
			  ->{$gene} = 1;
		}
	}
	return $result;
}

sub digest_description {
	my ( $self, $description ) = @_;
	return $self->{'digested'} unless ( defined $description );
	my $md5_sum = md5_hex($description);
	my $word;
	return $self->{'digested'} if ( defined $self->{'processed'}->{$md5_sum} );
	$description =~ s/[\.,;\-]/ /g;
	foreach $word ( split( " ", $description ) ) {
		$word = lc($word);
		$self->{'digested'}->{$word} = 0
		  unless ( defined $self->{'digested'}->{$word} );
		$self->{'digested'}->{$word}++;
	}
	$self->{'processed'}->{$md5_sum} = 1;
	return $self->{'digested'};
}

sub describe_Desease_Hash {
	my ( $self, $desease ) = @_;
	return '' unless ( defined $self->{'qualification_hashes'}->{$desease} );
	my $desc = "\n\\begin{longtable}{|c|c|}\n";

#$desc .= "\\caption{The values, that will be added to a arbitrary $desease score \n"
#. "if the gene description matches to any of these query strings.}\n";
	$desc .=
	  "\\hline\nquery string & score\\\\\n" . "\\hline\n\\hline\n\\endhead\n";
	$desc .=
"\\hline \\multicolumn{2}{|r|}{{Continued on next page}} \\\\ \\hline\n\\endfoot\n";
	$desc .= "\\hline \\hline\n\\endlastfoot\n";
	foreach my $key (
		sort {
			$self->{'qualification_hashes'}->{$desease}
			  ->{$a} <=> $self->{'qualification_hashes'}->{$desease}->{$b}
		} keys %{ $self->{'qualification_hashes'}->{$desease} }
	  )
	{
		$desc .=
		  " $key & $self->{'qualification_hashes'}->{$desease}->{$key}\\\\ \n";
	}
	$desc .= "\\end{longtable}\n\n";
	return $desc;
}

sub expected_dbh_type {
	return 'dbh';
}

=head2 DoNotConnect2WWW ( 1/0 ) 

Make the lib refuce to connect to the WWW - that destroys most of the usability,
but speeds the thing up if you only want to test a thing!

=cut

sub DoNotConnect2WWW {
	my ( $self, $do ) = @_;

	#return 1;
	if ( defined $do ) {
		$self->{'__do_not_connect_2_www___'} = $do;
	}
	return $self->{'__do_not_connect_2_www___'};
}

=head2 determineInfluence_of_gene_on_desease

This function needs two arguments, the gene name yu want to get information for and an optional desease name.
If the desease name is given, we try to estimate the importance of that gene to the desease. 
In order to work, we need an (hard coded) hash $self->{qualification_hashes}->{<desease>},
that defines a number of important strings and there importance as an integer.

We will try to get the gene description from the genecards web page www.genecards.org,
extract the 'EntrezGene summary' fro that gene.
If we did not get an desease, the 'EntrezGene summary' will be returned.
If we have an desease name, summary is matched against all 
'important strings' for that desease and the importance is summed up for all found strings.
The 'summary importance' will be returned.

=cut

sub determineInfluence_of_gene_on_desease {
	my ( $self, $gene, $desease ) = @_;
	$self->{'error'} = '';
	$self->{'error'} =
	  ref($self)
	  . "::determineInfluence_of_gene_on_desease -> we did not get a gene!"
	  unless ( defined $gene );
	if ( $gene =~ m/ / ) {
		$gene =~ s/^\s*//;
		$gene =~ s/\s*$//;
	}
	$gene = $1 if ( $gene =~ m/I?L?M?N?_?\d+_([\w\d\.\/\@\-]+)/ ); 
	$self->{'error'} =
	  ref($self)
	  . "::determineInfluence_of_gene_on_desease -> we can not handle the gene name '$gene' \n"
	  if ( $gene =~ m/ / );
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	my ( @temp, $temp, $data, @matched_strings );
	$gene = $1 if ( $gene =~ m/^ *([\w\d-]+) *$/ );
	@temp    = split( " ", $gene );
	$gene    = $temp[0];
	$desease = 'none' unless ( defined $desease );

	return $self->{'save'}->{ $gene . " " . $desease }
	  if ( defined $self->{'save'}->{$gene} );
	$data = $self->getArray_of_Array_for_search(
		{
			'search_columns' =>
			  [ ref($self) . ".RefSeq_desc", ref($self) . ".Swiss_Prot_desc" ],
			'where' => [
				[
					ref( $self->{'data_handler'}->{'gene_aliases'} )
					  . ".gene_name",
					'=',
					'my_value'
				]
			],
		},
		$gene
	);

	unless ( ref( @$data[0] ) eq "ARRAY" ) {
		warn "we got no data for the search \n$self->{'complex_search'}\n";
		if ( $self->DoNotConnect2WWW() ) {
			$temp->{'RefSeq_desc'}     = "no www connection";
			$temp->{'Swiss_Prot_desc'} = "";
		}
		else {
			$temp = $self->_get_gene_description_from_genecards($gene);
		}
		$data = $temp->{'RefSeq_desc'} . " " . $temp->{'Swiss_Prot_desc'};
	}
	else {
		$data = @{ @$data[0] }[0] . " " . @{ @$data[0] }[1];
	}
	my $rv = 0;
	Carp::confess(
"I need help! I can not resolve the gene $gene - please go to http://www.genecards.org/cgi-bin/carddisp.pl?gene=$gene and try to determine the real name for the gene.\n"
		  . "You can add the gene by using get_GeneDescription.pl -genes <the right name>\nWe only got $data as gene description!\n"
	) unless ( $data =~ m/\w+ \w+/ );
	if ( !$desease eq "none" ) {
		$self->{'error'} =
		  ref($self)
		  . "::determineInfluence_of_gene_on_desease -> we did not get a gene!"
		  unless (
			ref( $self->{'qualification_hashes'}->{$desease} ) eq "HASH" );
		Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	}
	else {
		$self->{'save'}->{ $gene . " " . $desease } = $data;
		return $data unless ( defined $desease );
	}
	foreach my $gene_OI ( keys %{ $self->_getlink_to_desease($desease) } ) {
		$rv += 100 if ( $gene eq $gene_OI );
		push( @matched_strings, $gene_OI );
	}
	while ( my ( $name, $influence ) =
		each %{ $self->{'qualification_hashes'}->{$desease} } )
	{
		if ( lc($data) =~ m/$name/ ) {
			$rv += $influence;
			push( @matched_strings, $name );
		}
	}
	$self->{'save'}->{ $gene . " " . $desease } = $rv;
	return $data, $rv, join( ", ", sort (@matched_strings) );
}

sub _getlink_to_desease {
	my ( $self, $desease ) = @_;
	return $self->{'linked_genes'}->{$desease}
	  if ( defined $self->{'linked_genes'}->{$desease} );
	$self->{'genes_of_importance'} =
	  genes_of_importance->new( $self->{'dbh'}, $self->{'debug'} )
	  unless ( ref( $self->{'genes_of_importance'} ) eq 'genes_of_importance' );
	my $data = $self->{'genes_of_importance'}->getArray_of_Array_for_search(
		{
			'search_columns' => ['genes_of_importance.gene_name'],
			'where' => [ [ "genes_of_importance.linked_to", '=', 'my_value' ] ]
		},
		$desease
	);
	$self->{'linked_genes'}->{$desease} = {};
	foreach my $gene_array (@$data) {
		$self->{'linked_genes'}->{$desease}->{ @$gene_array[0] } = 1;
	}
	return $self->{'linked_genes'}->{$desease};
}

sub get_href_for_gene {
	my ( $self, @genes ) = @_;
	return map{"http://www.genecards.org/cgi-bin/carddisp.pl?gene=$_"} @genes;
}
sub get_LaTeX_href_4_genes {
	my ( $self, @genes ) = @_;
	return map{ '\href{http://www.genecards.org/cgi-bin/carddisp.pl?gene='.$_.'}{'.$_.'}' } @genes;
}

sub _get_gene_description_from_genecards {
	my ( $self, $g ) = @_;

	my ( $url, $err, $results );
	$err = '';
	$url = $self->get_href_for_gene($g);
	( $results, $err ) = $self->__get_hash_4_genecards_url( $g, $url );

	if ( $results->{$g}->{'RefSeq_desc'} eq $results->{$g}->{'Swiss_Prot_desc'}
		&& $results->{$g}->{'Swiss_Prot_desc'} eq 'no information' )
	{
		$url = 'http://www.google.com/search?q=' . $g . '+genecards';
		( $results, $err ) = $self->__get_hash_4_genecards_url( $g, $url );
	}

	unshift( @{ $results->{$g}->{'aliases'} }, $g );
	my $id = $self->AddDataset( $results->{$g} );
	Carp::confess( "we did not get an ID for this dataset:\naliases: "
		  . join( ";", @{ $results->{$g}->{'aliases'} } ) . "\n"
		  . "RefSeq_desc: $results->{$g}->{'RefSeq_desc'}\nSwiss_Prot_desc: $results->{$g}->{'Swiss_Prot_desc'}\n"
	) unless ( $id > 0 );
	return $results->{$g};
}

sub __score_line {
	my ( $self, $line, $gene_name ) = @_;
	my @score = ();
	my $score = 0;
	return $score unless ( $line =~ m/\w/ );
	foreach ( 'http://', 'href', 'onmouseover', 'border', 'myArray', 'tmp', 'span:' ) {
		foreach ( $line =~ m/$_/g ) {
			push( @score, $_ );
			$score -= 10;
		}

	}
	$line = $self->__drop_HTML($line);
	return $score unless (length($line) > 20 );
	foreach ( 'Google Search', 'href=' ) {
		return $score if ( $line =~m/$_/ );
	}
	foreach (
		qw(is was in The the also be of can has contains published a binding cluster )
	  )
	{
		foreach ( $line =~ m/ $_ /g ) {
			push( @score, $_ );
			$score++;
		}

	}
	$score +=10 if ( $line =~ m/The encoded protein/);
	$score += int(length($line)/1000);
	$score +=(100 - length($1)) if ( $line =~ m/^(.*)Function/);
	$score +=(100 - length($1)) if ( $line =~ m/^(.*)$gene_name\s*:/);
	$score -= 100 if ( $line =~m/GIFtS/ );
	return $score,$line, @score if ( $self->{'DEBUG'} );
	return $score,$line;
}

sub __drop_HTML {
	my ( $self, $str ) = @_;
	$str =~ s/^\s*//;
	$str =~ s/^onClick\="doFocus\('aaa'\)"\>//g;
	$str =~ s/&nbsp;//g;
	my $new_str = '';
	my $not     = 0;
	foreach ( split( "", $str ) ) {

		if ( $_ eq "<" ) {
			$new_str .= " ";
			$not = 1;
		}
		$new_str .= $_ unless ($not);
		$not = 0 if ( $_ eq ">" );
	}
	$new_str =~ s/ +/ /g;
	return encode_utf8($new_str);
}

sub __get_hash_4_genecards_url {
	my ( $self, $g, $url ) = @_;

	my ( $data, $results, $read_tag, @data, $temp, $err );
	$err = '';
	my @error = eval {
		$self->{'mech'}->get($url);
		$data = $self->{'mech'}->content();
	};
	unless ( defined $data =~ m/\w/ ) {
		Carp::confess( "we did not get any result!" . join( "; ", @error ) );
		return undef, "we did not get any result! for the web_page $url";
	}
	my ( $value, $error );

	$results->{$g}->{'aliases'} = $self->readAliases($g);

	$data =~ s/\<\/dd\>\<dd\>/ \<\/dd\>\<dd\>/g;
	## lets_try to get the data without the tree builder - that is way too complex!
	## you can set the DEBUG flag in this object - then I will try to give you some hints on what we could do here.
	if ( $self->{'DEBUG'} ) {
	}
	my $i     = 1;
	my $print = 0;
	my @temp;
	my $data_table = data_table->new();
	foreach ( 'score', 'line nr', 'str' ) {
		$data_table->Add_2_Header($_);
	}
	foreach ( split( "\n", $data ) ) {
		$print = 1;
		if ($print) {
			## now I can create a score!
			@temp = $self->__score_line($_, $g);	
			$data_table->AddDataset(
				{
					'score'   => $temp[0],
					'line nr' => $i,
					'str'     => $temp[1],#$self->__drop_HTML($_)
				}
			) unless ( $temp[0] < 1);
			$print = 0;
		}
		$i++;
	}
	$data_table = $data_table->Sort_by( [ [ 'score', 'antiNumeric' ] ] );
	print $data_table->AsString() if ( $self->{'DEBUG'});
	my $new_table = $data_table->_copy_without_data();
	my $hash;
	for ( my $i = 0 ; $i < 5 ; $i++ ) {
		$hash = $data_table->get_line_asHash($i);
		next unless ( defined $hash );
		next unless ( $hash->{'score'} >= 5 );
		$new_table->AddDataset($hash);
	}
	$data_table = $new_table;
	unless ( $data_table->Lines > 0 ) {
		warn "You get crap here:\n" . $data_table->AsString();
	}
	else {
		$data_table = $data_table->Sort_by( [ [ 'line nr', 'numeric' ] ] );
		$results->{$g}->{'RefSeq_desc'} =
		  join( "\n", @{ $data_table->getAsArray('str') } );
		$results->{$g}->{'Swiss_Prot_desc'} = '';
	}

	$results->{$g}->{'RefSeq_desc'} = $results->{$g}->{'Swiss_Prot_desc'} =
	  'no information'
	  unless ( $results->{$g}->{'RefSeq_desc'} =~ m/\w/ );
	$results->{$g}->{'RefSeq_desc'} = $results->{$g}->{'Swiss_Prot_desc'} =
	  'no information'
	  if ( $results->{$g}->{'RefSeq_desc'} eq "--" );
	return $results, $err;
}

sub readAliases {
	my ( $self, $gene ) = @_;
	my ( $treebuilder, $data, $i, $genes, $value );

	$treebuilder = HTML::TreeBuilder->new();
	eval {
		$self->{mech}->get( $self->get_href_for_gene($gene) );
		$data = $self->{mech}->content();
	};
	return [] unless ( $data =~ m/\w/ );

	$data =~ s/\<\/dd\>\<dd\>/ \<\/dd\>\<dd\>/g;
	$treebuilder->parse($data);
	$treebuilder->eof();
	$i = 0;
	foreach $value ( $treebuilder->look_down( '_tag', 'body' ) ) {

		if ( ref($value) ) {
			##go on
			my @values = $value->look_down( '_tag', 'table' );
			unless ( ref( $values[0] ) ) {
				die "OOPS - I expected to find a table object!\n";
			}
			else {

				foreach $value (@values) {
					foreach my $table_entry ( $value->content_list() ) {
						if ( $table_entry->as_text() =~
							m/Aliases . Descriptionsfor.*According to/ )
						{
							$table_entry->as_text() =~
							  m/Aliases & Description(.*)External Ids/;
							my $str = $1 || '';
							while ( $str =~ m/Aliases & Description(.*)/ ) {
								$str = $1;
							}
							if ( $str =~ m/\w/ ) {
								foreach ( split( / +/, $str ) ) {
									next if ( length($_) <= 1 );
									next unless ( $_ eq uc($_) );
									next unless ( $_ =~ m/^[\w\d\-\@]+$/ );
									next if ( $_ =~ m/^\d+$/ );
									next unless ( $_ =~ /\d\d(.*)[1234]/ );
									$genes->{$1} = 1;
								}
							}

						}
					}
				}
				$genes->{$gene} = 1;
			}
		}
		else {
			die "we could not get the body of the page!\n";
		}

	}
	$treebuilder->delete();
	return [ keys %$genes ];
}

sub identifyReadTag {
	my ( $line, $results ) = @_;
	if ( $line =~ m/EntrezGene summary for/ ) {

	  #print "Hey, this line contains a 'EntrezGene summary for' tag!\n$line\n";
		return undef if ( defined $results->{'RefSeq_desc'} );
		return 'RefSeq_desc';
	}

	if ( $line =~ m/UniProtKB\/Swiss-Prot: / ) {

	  #print "Hey, this line contains a 'UniProtKB/Swiss-Prot: ' tag!\n$line\n";
		return undef if ( defined $results->{'Swiss_Prot_desc'} );
		return 'Swiss_Prot_desc';
	}
	return undef;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	my $temp;
	Carp::confess(
		root::get_hashEntries_as_string( $dataset, 3,
			"we did not get a id from AddDataset! id = '$id'" )
		  . $self->{'complex_search'} . "\n"
	) unless ( defined $id );
	return 1 unless ( ref( $dataset->{'aliases'} ) eq "ARRAY" );
	foreach my $alias ( @{ $dataset->{'aliases'} } ) {

		#print "we insert a gene alias $alias for id $id\n";
		$temp =
		  $self->{'data_handler'}->{'gene_aliases'}
		  ->AddDataset( { 'gene_name' => $alias, 'description_id' => $id } );

		#print "and we got a id $temp\n";
		$self->{'error'} .=
		  $self->{'data_handler'}->{'gene_aliases'}->{'error'};
	}
	$self->{'UNIQUE_KEY'} =
	  [ $self->{'data_handler'}->{'gene_aliases'}->TableName() . ".gene_name" ];
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );

	#return 0 if ( $self->{'error'} =~ m/\w/ );
	#return 1;
}

sub changes_after_check_dataset {
	my ( $self, $dataset ) = @_;
	## we 'only' need to adjust the unique_search so that we so not have athe link to the other table at this moment.
	## rather we do not want to get anything here....
	$self->{'UNIQUE_KEY'}       = ['timestamp'];
	$self->{'select_unique_id'} = undef;

#warn ref($self). "::changes_after_check_dataset ->we created a unique search \n".$self->_create_unique_search(['id'])."\n";
	return 1;
}

sub _get_unique_search_array {
	my ( $self, $dataset ) = @_;
	## we have the problem, that we want to get am entry, that depends on another tables entry.
	if ( @{ $self->{'UNIQUE_KEY'} }[0] eq "timestamp" ) {

#print "we return the timestamp ($dataset->{'timestamp'}) as the unique key!\n";
		return [ $dataset->{'timestamp'} ];
	}
	return [ $dataset->{'aliases'} ];
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "gene_descriptions";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'RefSeq_desc',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'Swiss_Prot_desc',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR (32)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'INDICES'} }, ['md5_sum'] );
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'timestamp',
			'type'        => 'TIMESTAMP',
			'NULL'        => 0,
			'default'     => "'".$self->NOW()."'",
			'description' => ''
		}
	);
	$self->{'table_definition'} = $hash;

	$self->{'Group_to_MD5_hash'} = [ 'RefSeq_desc', 'Swiss_Prot_desc' ]
	  ;    # define which values should be grouped to get the 'md5_sum' entry
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => 0,
			'description' =>
			  "the id links to the gene_aliases table description_id",
			'link_to'        => 'description_id',
			'data_handler'   => 'gene_aliases',
			'NOT_AddDataset' => 1
		}
	);
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	$self->{'data_handler'}->{'gene_aliases'} =
	  gene_aliases->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'UNIQUE_KEY'} =
	  [ $self->{'data_handler'}->{'gene_aliases'}->TableName() . ".gene_name" ];
	; # add here the values you would take to select a single value from the databse
	return $dataset;
}

1;
