package kegg_genes;

#  Copyright (C) 2010 Stefan Lang

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

use stefans_libs::database::variable_table;
use base variable_table;

use stefans_libs::database::pathways::kegg::kegg_pathway;
use GD;
##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug                   => $debug,
		'genes_to_be_described' => {},
		dbh                     => $dbh
	};

	bless $self, $class if ( $class eq "kegg_genes" );
	$self->init_tableStructure();

	$self->{'pathway_setting_2_genes'} = data_table->new();
	foreach ( 'phenoytpe', 'sub_type', 'pathway', 'gene' ) {
		$self->{'pathway_setting_2_genes'}->Add_2_Header($_);
	}
	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "KEGG_GENES";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'KEGG_gene_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the KEGG gene id',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'Gene_Symbol',
			'type'        => 'VARCHAR (30)',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'pathway_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'kegg_pathway'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'mark_type',
			'type'        => 'VARCHAR(6)',
			'NULL'        => '0',
			'description' =>
'either a rect or a circle describing the type of the mark on the picture',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'x_coord_1',
			'type'        => 'INTEGER',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'y_coord_1',
			'type'        => 'INTEGER',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'x_coord_2',
			'type'        => 'INTEGER',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'y_coord_2',
			'type'        => 'INTEGER',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'UNIQUES'} },
		[ 'Gene_Symbol', 'pathway_id', 'x_coord_1' ]
	);

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = [ 'Gene_Symbol', 'pathway_id', 'x_coord_1' ];

	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.
	$self->{'data_handler'}->{'kegg_pathway'} =
	  kegg_pathway->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub get_reference_dataset_names {
	my $self = shift;
	return $self->{'data_handler'}->{'kegg_pathway'}->{'data_handler'}->{'hypergeometric_max_hits'}-> reference_dataset_names ();
}

=head2 add_LaTeX_section_for_Gene_List ( {
	'genes' => [@genes],
	'kegg_reference_geneset' => <string>,
	'only_significant' => 1,
	'LaTeX_object' => stefans_libs::Latex_Documents::Section object,
	'temp_path' => 'a path to store the original figures in'
})

This function will check the gene list against the KEGG pathways asuming, that the 'kegg_reference_geneset'
has been matched against the KEGG pathways to create the values needed for the statistics.
If you specify 'only_significant' you will get only the sigificant KEGG pathways as a description.

We will add create a subsection names 'KEGG pathways' to this 'LaTeX_object' and one subsection for each KEGG pathway.
Each KEGG pathway will have a figure with it so the 'temp_path' is really crucial!

In return you get a summary table, that gives a small overview over the described KEGG pathways.
This table id a data_table object containing the columns 'kegg_pathway.id', 'matched genes', 'pathway_name' and 'Gene Symbols'.

=cut

sub add_LaTeX_section_for_Gene_List {
	my ( $self, $hash ) = @_;
	## the initial table with all the genes
	my ( $summary_table, $significant_table );
	
	mkdir( $hash->{'temp_path'} ) unless ( -d $hash->{'temp_path'} );
	print "You have asked me to get information for the genes ".join(", ", @{$hash->{'genes'}})."\n";
	$hash->{'LaTeX_object'}->Section('KEGG pathways');
	$hash->{'LaTeX_object'}->Section('KEGG pathways')
	  ->Section( 'Pathway sumary', 'main::intro' );
	 for( my $i = 0; $i < @{$hash->{'genes'}}; $i ++ ) {
	 	@{$hash->{'genes'}}[$i] = $1 if ( @{$hash->{'genes'}}[$i] =~m/I?L?M?N?_?\d+_([\w\d\.\/\@\-]+)/ ); 
	 }
	my $table =
	  $self->__get_table_for_gene_list( $hash->{'genes'},
		$hash->{'kegg_reference_geneset'} );

	#Carp::confess ( "Do I get results for all genes??". $table->AsString() );
	unless ( ref( $table->get_line_asHash(0) ) eq "HASH" ) {
		warn
"Sorry, but I could not find any KEGG pathway that described any of these genes:\n"
		  . join( "; ", @{ $hash->{'genes'} } ) . "\n"
		  . "using the sql search $self->{'complex_search'}\n";
		$hash->{'LaTeX_object'}->Section('KEGG pathways')
		  ->AddText(
			"Sorry, but none of the genes matched to any KEGG pathway!");
		return $table;
	}
	elsif ( $self->{'debug'} ) {
		print
		  "we got ".$table->Lines()." result lines for the sql search\n$self->{'complex_search'}\n";
		print "The column names in the data table are: ".join(", ", @{$table->{'header'}})."\n";
	}
	## We now could remove any Pathways with less than $self->Min_Genes_Per_Pathway() genes
	$table->createIndex('Gene_Symbol');
	my $initial_genes = scalar( $table->getIndex_Keys('Gene_Symbol') );
	$hash->{'LaTeX_object'}->Section('KEGG pathways')
	  ->AddText( "For this setting, we got a list of "
		  . scalar( @{ $hash->{'genes'} } )
		  . " genes from which $initial_genes did match to at least one KEGG pathway. The genes are associated with the phenotype $hash->{'phenotype'} / "
		  . $hash->{'LaTeX_object'}->Title()
		  . ".\n" );

	($table, $summary_table) = $self->__resrict_results_table($table);

	print "I have got the result ".$table->AsTestString()." from the __resrict_results_table function.\n" if ( $self->{'debug'} );
	## OK now we need to identify the significant KEGG pathways!
	( $table, $summary_table, $significant_table ) =
	  $self->identify_significant_KEGG_pathways(
		$table,$summary_table,
		$hash->{'kegg_reference_geneset'},
		$hash->{'only_significant'},
		$initial_genes
	  );
	$self->{'summary_table'} = $summary_table;

    print "And after identify_significant_KEGG_pathways() this is my summary_table:\n".$summary_table->AsString() if ( $self->{'debug'});
    
	if ( $summary_table->Lines() == 0 ) {
		$hash->{'LaTeX_object'}->Section('KEGG pathways')
		  ->Section('Pathway sumary')
		  ->AddText(
			"Sorry, but we did not get ANY pathways with this setting!\n");
		return $significant_table;
	}
	my $temp_text =
	  $hash->{'LaTeX_object'}->Section('KEGG pathways')
	  ->Section('Pathway sumary')
	  ->AddText(
		join( " ", @{ $summary_table->Description() } )
		  . " The table describes all identified KEGG pathways for this list of $initial_genes gene."
	  );
	$temp_text->Add_Table( $summary_table->GetAsObject('plottable') );

	## And now we need to set up the plotting part - that will be damn complex!
	my $labels = $self->add_KEGG_figure_part_4_table( $hash->{'LaTeX_object'},
		$table, $hash->{'temp_path'}, $hash->{'phenotype'},
		$hash->{'LaTeX_document'} );
	$significant_table->Add_2_Header('Figure Lable');
	$significant_table->createIndex('pathway_name');
	foreach my $pathway ( keys %$labels ) {
		$significant_table->AddDataset(
			{
				'pathway_name' => $pathway,
				'Figure Lable' => $labels->{$pathway}
			}
		);
	}
	return $significant_table;
}


=head2 Get_KEGG_Summary_Table ( {
	'genes' => [@genes],
	'kegg_reference_geneset' => <string>,
	'only_significant' => 1,
})

This function will check the gene list against the KEGG pathways asuming, that the 'kegg_reference_geneset'
has been matched against the KEGG pathways to create the values needed for the statistics.
If you specify 'only_significant' you will get only the sigificant KEGG pathways as a description.

In return you get a summary table, that gives a small overview over the described KEGG pathways.
This table is a data_table object containing the columns 'kegg_pathway.id', 'matched genes', 'pathway_name' and 'Gene Symbols'.

!! You get an undefined value if we did not match to any KEGFG pathway or there were no significant ones!!

=cut
sub Get_KEGG_Summary_Table {
	my ( $self, $hash ) = @_;
	my $table =
	  $self->__get_table_for_gene_list( $hash->{'genes'},
		$hash->{'kegg_reference_geneset'} );
	unless ( ref( $table->get_line_asHash(0) ) eq "HASH" ) {
		##No match against any KEGG pathway :-(
		return undef;
	}
	my ($summary_table, $significant_table, $initial_genes);
	$table->createIndex('Gene_Symbol');
	$initial_genes = scalar( $table->getIndex_Keys('Gene_Symbol') );
	($table, $summary_table) = $self->__resrict_results_table($table);
	( $table, $summary_table, $significant_table ) =
	  $self->identify_significant_KEGG_pathways(
		$table,$summary_table,
		$hash->{'kegg_reference_geneset'},
		$hash->{'only_significant'},
		$initial_genes
	  );
	if ( $summary_table->Lines() == 0 ) {
		return undef;
	}
	$summary_table->define_subset ( 'latex', [ 'pathway_name', 'Gene Symbols', 'hypergeometric p value', 'matched genes']);
	$summary_table = $summary_table->GetAsObject('latex');
	$summary_table->make_column_LaTeX_p_type( 'pathway_name', '5cm' );
	$summary_table->make_column_LaTeX_p_type( 'hypergeometric p value', '2.5cm' );
	$summary_table->make_column_LaTeX_p_type( 'Gene Symbols', '5cm' );
	return $summary_table;
}

=head2 add_KEGG_figure_part_4_table (  $LaTeX_obj, $table, $outpath )

This function will add a section named 'The KEGG Pathways' with one level of subsections to the LaTeX_obj.
These sections will each contain one figure, that highlights all the interesting genes in one KEGG pathway.

=cut

sub add_KEGG_figure_part_4_table {
	my ( $self, $LaTeX_obj, $table, $outpath, $phenotype, $LaTeX_Document ) =
	  @_;
	Carp::confess( "my LaTeX_Document has to be a base class object, not '"
		  . ref($LaTeX_Document)
		  . "'!" )
	  unless ( ref($LaTeX_Document) eq "stefans_libs::Latex_Document" );
	$phenotype = '' unless ( defined $phenotype );
	$LaTeX_obj->Section('KEGG pathways');
	my (
		$external_files, $image,      @lines,  $red,
		$this_genes,     $geneGroups, $lineID, $data,
		@temp,           @geneGroups, $temp,   $figure,
		$labels,         $white
	);
	$external_files = external_files->new( $self->{'dbh'} );

	#print "We have this data left:\n".$table->AsString()."\n";
	$table->createIndex('external_files.id');
	foreach my $picture ( $table->getIndex_Keys('external_files.id') ) {
		print
		  "we try to create a figure for the external_files.id '$picture'\n";
		$image =
		  GD::Image->new(
			$external_files->get_fileHandle( { 'id' => $picture } ) );
		@lines =
		  $table->get_rowNumbers_4_columnName_and_Entry( 'external_files.id',
			$picture );

		$red   = $image->colorAllocate( 255, 0,   0 );
		$white = $image->colorAllocate( 255, 255, 255 );
		$this_genes = {};
		$geneGroups = {};
		foreach $lineID (@lines) {
			$data = $table->get_line_asHash($lineID);
			$data->{'pathway_name'} =~ s/&/\\&/g;
			$data->{'pathway_name'} =~ s/#/\\&/g;
			$data->{'description'}  =~ s/&/\\&/g;
			$data->{'description'}  =~ s/#/\\&/g;
			$geneGroups->{"$data->{'x_coord_2'} $data->{'y_coord_2'}"} = {
				'genes' => {},
				'x'     => $data->{'x_coord_2'},
				'y'     => $data->{'y_coord_2'}
			  }
			  unless (
				defined $geneGroups->{
					"$data->{'x_coord_2'} $data->{'y_coord_2'}"} );
			$geneGroups->{"$data->{'x_coord_2'} $data->{'y_coord_2'}"}
			  ->{'genes'}->{ $data->{'Gene_Symbol'} } = 1;
			$image->rectangle(
				$data->{'x_coord_1'}, $data->{'y_coord_1'},
				$data->{'x_coord_2'}, $data->{'y_coord_2'},
				$red
			);
			$this_genes->{ $data->{'Gene_Symbol'} } = 1
			  if ( $data->{'Gene_Symbol'} =~ m/\w/ );
		}
		@temp = (
			sort {
				scalar( keys %{ $geneGroups->{$b}->{'genes}'} } ) <=>
				  scalar( keys %{ $geneGroups->{$a}->{'genes}'} } )
			  } keys %$geneGroups
		);

		@geneGroups = ();
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			$temp = "(" . ( $i + 1 ) . ") ";
			foreach ( sort keys %{ $geneGroups->{ $temp[$i] }->{'genes'} } ) {
				$self->{'pathway_setting_2_genes'}->AddDataset(
					{
						'phenoytpe' => $phenotype,
						'sub_type'  => $LaTeX_obj->Title(),
						'pathway'   => $data->{'pathway_name'},
						'gene'      => $_
					}
				);
				$temp .= "\\nameref{$_}, ";
				$self->{'genes_to_be_described'}->{$_} = 1;
			}
			chop($temp);
			chop($temp);
			push( @geneGroups, $temp );
			$image->filledRectangle(
				$geneGroups->{ $temp[$i] }->{'x'} + 2,
				$geneGroups->{ $temp[$i] }->{'y'} - 13,
				$geneGroups->{ $temp[$i] }->{'x'} + 10,
				$geneGroups->{ $temp[$i] }->{'y'} - 3,
				$white
			);
			$image->string( gdSmallFont,
				$geneGroups->{ $temp[$i] }->{'x'} + 2,
				$geneGroups->{ $temp[$i] }->{'y'} - 3,
				$i + 1, $red
			);
		}
		open( OUT, ">$outpath/$data->{'kegg_pw_id'}.png" )
		  or die
"could not craete new image file '$outpath/$data->{'kegg_pw_id'}.png'\n";
		print OUT $image->png();
		close(OUT);
		$LaTeX_Document->Additional_tar_files(
			"$outpath/$data->{'kegg_pw_id'}.png");
		$temp =
		  $LaTeX_obj->Section('KEGG pathways')
		  ->Section( $data->{'pathway_name'} );
		$temp   = $temp->AddText( $data->{'description'} );
		$figure = $temp->Add_Figure();
		$figure->AddPicture(
			{
				'placement' => 'tbp',
				'files'     => ["$outpath/$data->{'kegg_pw_id'}.png"],
				'caption'   => 'The '
				  . $data->{pathway_name}
				  . ' pathway ('
				  . $phenotype . ' '
				  . $LaTeX_obj->Title()
				  . '). Red rectangles mark the genes, that you wanted to get pathway information for. The red number at the rectangles is a substitute for a list of genes: '
				  . join( "; ", @geneGroups )
				  . ". (Go back to results section \\ref{"
				  . $LaTeX_obj->Section('KEGG pathways')
				  ->Section( $data->{'pathway_name'} )->Lable()
				  . "}; back to summary table \\ref{main::intro})"
			}
		);
		$temp->AddText(
			    "The pathway in a graphical view is depicted in figure \\ref{"
			  . $figure->Label()
			  . "}." );
		$labels->{ $data->{pathway_name} } = $figure->Label();
	}
	return $labels;
}

=head2 identify_significant_KEGG_pathways ( $table, $kegg_reference_geneset )

=cut

sub identify_significant_KEGG_pathways {
	my ( $self,$table, $summary_table , $kegg_reference_geneset, $only_significants,
		$available_genes )
	  = @_;
	my ( $hypergeometric_max_hits, $reference_dataset,
		$gene_count, $temp );

	print "I got the PATHWAY summary table: \n".$summary_table->AsTestString() if ( $self->{'debug'});
	$gene_count    = scalar( @{ $self->Genes() } );

#$gene_count =  $available_genes; #scalar( $table->getIndex_Keys('Gene_Symbol') );
	print "We use a total of $gene_count draws in the test instead of "
	  . scalar( @{ $self->Genes() } ) . "\n";

#Carp::confess ( "Do you think that is better? used: $gene_count vs.".scalar( @{ $self->Genes() } )."\n");
	$summary_table->createIndex('kegg_pathway.id');
	## get the pre_calculated max values

	unless ( scalar( @{ $summary_table->{'data'} } ) > 0 ) {
		warn
"oh we did not get any results for the actual kegg reference set - cool\n";
		return ( $table, $summary_table, $summary_table->_copy_without_data() );
	}

#print "Probably we do not have any 'kegg_pathway.id'?\n".$summary_table->AsString();
	if ( defined $kegg_reference_geneset ) {
		$hypergeometric_max_hits =
		  hypergeometric_max_hits->new( $self->{'dbh'}, $self->{debug} );
		$reference_dataset = $hypergeometric_max_hits->get_data_table_4_search(
			{
				'search_columns' => [ 'kegg_id', 'max_count', 'bad_entries' ],
				'where' => [ [ 'kegg_id', '=', 'my_value' ], [ 'reference_dataset', '=', 'my_value'] ]
			},
			[ $summary_table->getIndex_Keys('kegg_pathway.id') ] , $kegg_reference_geneset
		);
		## merge the tables
		$reference_dataset->Rename_Column( 'kegg_id', 'kegg_pathway.id' );
		$summary_table->merge_with_data_table($reference_dataset);

		## calculate the hypergeometric test
		$summary_table->define_subset( 'data',
			[ 'max_count', 'bad_entries', 'matched genes', 'pathway_name' ] );
		$summary_table->calculate_on_columns(
			{
				'function' => sub {

#					print "hypergeom ( $_[0], $_[1], $gene_count, $_[2] ) = ".sprintf( '%.1E',
#						&hypergeom( $_[0], $_[1], $gene_count, $_[2] ) )."\n";
					return sprintf(
						'%.1E',
						&more_hypergeom(
							$_[0], $_[1], $gene_count, $_[2], $_[3]
						)
					);
				},
				'data_column'   => 'data',
				'target_column' => 'hypergeometric p value'
			}
		);
		$summary_table =
		  $summary_table->Sort_by(
			[ [ 'hypergeometric p value', 'numeric' ] ] );
		$summary_table->define_subset( 'plottable',
			[ 'pathway_name', 'matched genes', 'hypergeometric p value' ] );
		$summary_table->Add_2_Description(
			    "We identified a total of "
			  . scalar( @{ $summary_table->{'data'} } )
			  . " pathways translating in the corrected p_values \n  0.05="
			  . sprintf( '%.1E',
				( 0.05 / scalar( @{ $summary_table->{'data'} } ) ) )
			  . "\n  0.01="
			  . sprintf( '%.1E',
				( 0.01 / scalar( @{ $summary_table->{'data'} } ) ) )
		);
		$temp = $summary_table->select_where(
			'hypergeometric p value',
			sub {
				return 1
				  if ( $_[0] <=
					( 0.05 / scalar( @{ $summary_table->{'data'} } ) ) );

				#			0.05 );
				return 0;
			}
		);
		$summary_table->Add_2_Description( "Hence only the first "
			  . scalar( @{ $temp->{'data'} } )
			  . " rows can be considered as being significant." );
		## if we want to show only the signififcant pathways we need to remove some results from the analysis!
		if ($only_significants) {
			print
			  "from now on we will only process the significant pathways!\n";
			my $select;
			foreach ( @{ $temp->getAsArray('pathway_name') } ) {
				$select->{$_} = 1;
			}
			$table =
			  $table->select_where( 'pathway_name',
				sub { return 1 if ( $select->{ $_[0] } ); return 0; } );
		}
	}
	return ( $table, $summary_table, $temp );
}

=head2 __get_table_for_gene_list ( [ genes ], kegg_reference_geneset)

You will get a table object, that you can process with all my XY($table) functions.

=cut

sub __get_table_for_gene_list {
	my ( $self, $genes, $kegg_reference_geneset ) = @_;
	$self->Genes($genes);
	Carp::confess(
"Lib change!\n__get_table_for_gene_list now does need a kegg_reference_geneset as second argument!"
	  )
	  unless ( defined $kegg_reference_geneset );
	my $return = $self->get_data_table_4_search(
		{
			'search_columns' => [
				'Gene_Symbol',       'pathway_id',
				'pathway_name',      'description',
				'external_files.id', 'x_coord_1',
				'y_coord_1',         'x_coord_2',
				'y_coord_2',         'kegg_pw_id',
				'kegg_pathway.id'
			],
			'where' => [
				[ 'Gene_Symbol',       '=', 'my_value' ],
				[ 'reference_dataset', '=', 'my_value' ]
			],
			'order_by' => ['pathway_name']
		},
		$genes,
		$kegg_reference_geneset
	);
	#$return -> define_subset ( 'print', ['Gene_Symbol','pathway_name', 'external_files.id', 'kegg_pathway.id']);
	#Carp::confess ( "I have exectuted the search '$self->{'complex_search'}'\n and got the result:".$return->AsString('print') );
	return $return;
}

sub Genes {
	my ( $self, $genes ) = @_;
	if ( ref($genes) eq "ARRAY" ) {
		my $temp;
		foreach (@$genes) {
			$temp->{$_} = 1;
		}
		$self->{'__genes__'} = [ sort keys %$temp ];
	}
	Carp::confess("We have no genes array\n")
	  unless ( ref( $self->{'__genes__'} ) eq "ARRAY" );
	warn "We have no genes in the  genes array\n"
	  unless ( scalar( @{ $self->{'__genes__'} } ) > 0 );
	return $self->{'__genes__'};
}

=head2 __resrict_results_table ( $table )

This function will remove genes from a results table, 
that are not part of a pathway that shows at least 
$self->Min_Genes_Per_Pathway() gene hits.

You will get a new table object, that cntains this information!

=cut

sub __resrict_results_table {
	my ( $self, $table ) = @_;
	$table->define_subset( 'hyper_data', [ 'Gene_Symbol', 'pathway_name' ] );
	my $summary_table = $self->__gene_hits_for_each_KEGG_pathway($table);

# Carp::confess ( "Probably you would like to get this table?\n".$summary_table->AsString());
	my $info = $summary_table->getAsHash( 'pathway_name', 'matched genes' );
	my $select = {};
	foreach ( keys %$info ) {
		$select->{$_} = 1
		  if ( $info->{$_} >= $self->Min_Genes_Per_Pathway() );
	}
	return $table->select_where( 'pathway_name',
		sub { return 1 if ( $select->{ $_[0] } ); return 0; } ) , $summary_table->select_where(  'pathway_name',
		sub { return 1 if ( $select->{ $_[0] } ); return 0; } );
}

=head2 __gene_hits_for_each_KEGG_pathway ( $table )

This function will create a summary table from one of our table objects
that will contain the columns 'kegg_pathway.id', 'matched genes', 'pathway_name' and 'Gene Symbols'.
 
=cut

sub __gene_hits_for_each_KEGG_pathway {
	my ( $self, $table ) = @_;
	foreach ( 'Gene_Symbol', 'pathway_name', 'kegg_pathway.id') {
		Carp::confess ( "I have a format mismatch!\nThe table should contain the column $_, but it does not contain that column!\n".$table->AsTestString() ) unless ( defined $table->Header_Position($_) );
	}
	Carp::cluck('Who has called me - the first or second time?') if ( $self->{'debug'});
	$table->define_subset( 'hyper_data', [ 'Gene_Symbol', 'pathway_name' ] );
	if ( $self->{'debug'}) {
		print "I check the __gene_hits_for_each_KEGG_pathway function:\n".
		"I got the variables: \n";
		$table ->define_subset ('print', [ 'kegg_pathway.id', 'Gene_Symbol', 'pathway_name' ] );
		print $table->AsTestString('print')."\nThe whole table has the column names ".join(", ",@{$table->{'header'}}).".\nAnd I try to sum up the genes per pathway!\n";
	}
	$table->createIndex( 'kegg_pathway.id' );
	my $return = $table->pivot_table(
		{
			'grouping_column'    => 'kegg_pathway.id',
			'Sum_data_column'    => 'hyper_data',
			'Sum_target_columns' =>
			  [ 'matched genes', 'pathway_name', 'Gene Symbols' ],
			'Suming_function' => sub {
				my $count        = 0;
				my $genes        = '';
				my $already_used = {};
				## print "I got these values for the one pathway: ".join(", ",@_ )."\n" ;
				for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
					next if ( defined $already_used->{ $_[$i] } );
					$already_used->{ $_[$i] } = 1;
					$count++;
					$genes .= $_[$i] . " ";
				}
				chop($genes);
				return $count, $_[1], $genes;
			  }
		}
	);
	if ( $self->{'debug'} ) {
		print "And I got the results:". $return -> AsTestString();
	}
	return $return;
}

=head2 Min_Genes_Per_Pathway

Change the minimal number of genes, that have to match to a KEGG pathway in 
order to considder it in the analysis from 5 to some other number.

=cut

sub Min_Genes_Per_Pathway {
	my ( $self, $number ) = @_;
	if ( defined $number ) {
		$self->{'___min_genes_per_pathway___'} = int($number)
		  if ( $number >= 0 );
	}
	$self->{'___min_genes_per_pathway___'} = 5
	  unless ( defined $self->{'___min_genes_per_pathway___'} );
	return $self->{'___min_genes_per_pathway___'};
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}



sub more_hypergeom {
	my ( $n, $m, $N, $i, $pathway ) = @_;
	return 1 unless ( defined $n );
	if ( $i >= $n ) {
		## This is normaly a deadly problem!
		Carp::confess(
"You must not draw more than the possible amount of things from your urn! $i > $n!!"
		);
		warn "You claim to have gotten $i hits to a pathway having a max_hit_count of $n.\nI do not belive you and therefore set the result to 2\n";
		return 2;
	}
	Carp::confess("You have an error in the script as $m + $n - $N is below 0!")
	  if ( $m + $n - $N < 0 );
	my $p1 = &hypergeom( $n, $m, $N, $i );
	unless ( $i + 2 > $N || $i + 2 > $n ) {
		my $p2 = &hypergeom( $n, $m, $N, $i + 2 );
		return $p1     if ( $p1 > 0.1 );
		return 1 - $p1 if ( $p1 < $p2 );
	}
	return $p1 / 2;
}

sub logfact {
	return gammln( shift(@_) + 1.0 );
}

sub hypergeom {

	# There are m "bad" and n "good" balls in an urn.
	# Pick N of them. The probability of i or more successful selection +s:
	# (m!n!N!(m+n-N)!)/(i!(n-i)!(m+i-N)!(N-i)!(m+n)!)
	my ( $n, $m, $N, $i ) = @_;

	my $loghyp1 =
	  logfact($m) + logfact($n) + logfact($N) + logfact( $m + $n - $N );
	my $loghyp2 =
	  logfact($i) + logfact( $n - $i ) + logfact( $m + $i - $N ) +
	  logfact( $N - $i ) + logfact( $m + $n );
	return exp( $loghyp1 - $loghyp2 );
}

sub gammln {
	my $xx  = shift;
	my @cof = (
		76.18009172947146,   -86.50532032941677,
		24.01409824083091,   -1.231739572450155,
		0.12086509738661e-2, -0.5395239384953e-5
	);
	my $y = my $x = $xx;
	my $tmp = $x + 5.5;
	$tmp -= ( $x + .5 ) * log($tmp);
	my $ser = 1.000000000190015;
	for my $j ( 0 .. 5 ) {
		$ser += $cof[$j] / ++$y;
	}
	Carp::confess("Hej we must not have a $x of 0!\n") if ( $x == 0 );
	-$tmp + log( 2.5066282746310005 * $ser / $x );
}

1;
