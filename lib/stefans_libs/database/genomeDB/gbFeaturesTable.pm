package gbFeaturesTable;

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
use stefans_libs::gbFile::gbFeature;
use stefans_libs::database::genomeDB::gbFilesTable;
use stefans_libs::database::genomeDB::db_xref_table;
use stefans_libs::database::variable_table;

#use stefans_libs::database::genomeDB::gbFilesTable;
use stefans_libs::database::fulfilledTask::fulfilledTask_handler;

use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

class to access and create the gbFeatures tables in the NCBI genomes database

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class gbFeaturesTable.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh,
		'select_gbString_for_gbID_tag_start_end' =>
'select gbString from database where gbFile_id = ? && tag = ? && start >= ? && end <= ?',
		selectID_NTS =>
"select id from database where  tag = ? && name = ? && start = ? && end = ?",
		selectIDs_by_gbFile => "select id from database where gbFile_id = ?;",
		select_gbStrings =>
"select gbString from database where id IN ( theSearchIDs ) order by start",
		select_all_for_feature_tag_and_name =>
		  "select gbFile_id, gbString from database where tag = ? && name = ?",
		'select_gbString_for_gbID_tag_name_start_end' =>
"select gbString from database where  gbFile_id = ? && tag = ? && name = ? && start >= ? && end <= ?",
		'delete_from_gbFeatures' =>
		  "delete from database where tag = ? && name = ? && gbFile_id = ?;"
	};

	bless $self, $class if ( $class eq "gbFeaturesTable" );
	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'dbh';

	#return "not a database interface";
	#return "database_name";
}

sub get_promoter_regions_4_genes {
	my ( $self, $genes, $start, $end ) = @_;
	$start = 2000 unless ( defined $start );
	$end   = 2000 unless ( defined $end );
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'gbFile_id', 'gbString' ],
			'where' =>
			  [ [ 'name', '=', 'my_value' ], [ 'tag', '=', 'my_value' ] ],
		},
		$genes, 'gene'
	);
	## OK now I have all mRNA gbStrings, the gbFile_id and that should be enough to create a bed file!
#	print "I got the data table:\n".$data_table->AsString(). " using the search '$self->{'complex_search'}'\n";
<<<<<<< HEAD
	my $bedfile = stefans_libs::file_readers::bed_file->new();
	my $gbFeature = gbFeature->new('nix', '1..2' );
	my ($startP, $endP, @return, $hash );
	for (my $i = 0; $i < $data_table->Lines; $i ++ ) {
		$gbFeature -> parseFromString ( @{@{$data_table->{'data'}}[$i]}[1] );
		($startP, $endP) = $gbFeature -> getPromoterRegion( $start, $end );
=======
	my $bedfile = stefans_libs_file_readers_bed_file->new();
	my $gbFeature = gbFeature->new( 'nix', '1..2' );
	my ( $startP, $endP, @return, $hash );
	for ( my $i = 0 ; $i < $data_table->Lines ; $i++ ) {
		$gbFeature->parseFromString( @{ @{ $data_table->{'data'} }[$i] }[1] );
		( $startP, $endP ) = $gbFeature->getPromoterRegion( $start, $end );
>>>>>>> fc83dc65db03e3ecb1e1e1e6a655834e2cbc798f
		##Now I need to translate the gbFile_ID start end into a chromosomal position
		@return = $self->get_chr_calculator->gbFile_2_chromosome(
			@{ @{ $data_table->{'data'} }[$i] }[0],
			$startP, $endP );
		$hash = {
			'chromosome' => $return[0],
			'start'      => $return[1],
			'end'        => $return[2],
			'name'       => $gbFeature->Name()
		};
		$hash->{'name'} .= " (rev)" if ( $gbFeature->IsComplement() );
		$bedfile->AddDataset($hash);
	}
	return $bedfile;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'} = [ ['tag'], ['name'], ['start'], ['end'] ];
	$hash->{'UNIQUES'} = [ ['md5_sum'] ];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'gbFile_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'gbFileTable',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'tag',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (50)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'end',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gbString',
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
			'type'        => 'CHAR (32)',
			'NULL'        => '0',
			'description' => 'A unique entry - md5_hash of the gbString',
			'needed'      => ''
		}
	);
	$hash->{'ENGINE'}           = 'MyISAM';
	$hash->{'CHARACTER_SET'}    = 'latin1';
	$self->{'table_definition'} = $hash;

	$self->{'Group_to_MD5_hash'} = ['gbString'];

	$self->{'UNIQUE_KEY'} = ['md5_sum']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	$self->{'data_handler'}->{'gbFileTable'} =
	  gbFilesTable->new( $self->{dbh}, $self->{debug} );
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'_propagateTableName_to'} =
	  [ $self->{'data_handler'}->{'gbFileTable'} ];
	return $dataset;
}

sub get_chr_calculator {
	my ($self) = @_;
	return $self->{'data_handler'}->{'gbFileTable'}
	  ->get_chr_calculator( $self->{'debug'} );
}

sub unlink_gbFilesTable {
	my ($self) = @_;
	## OK, that is a harsh step!
	$self->{'data_handler'}->{'chromosomesTable'} =
	  chromosomesTable->new( $self->{'dbh'}, $self->{'debug'} )
	  unless ( defined $self->{'data_handler'}->{'chromosomesTable'} );
	$self->{'data_handler'}->{'chromosomesTable'}
	  ->TableBaseName( $self->TableBaseName() );
	foreach my $vardef ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $vardef->{'name'} eq "gbFile_id" ) {
			$vardef->{'data_handler'} = 'chromosomesTable';
		}
	}
	return 1;
}

sub relink_gbFilesTable {
	my ($self) = @_;
	## OK, that is a harsh step!
	foreach my $vardef ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $vardef->{'name'} eq "gbFile_id" ) {
			$vardef->{'data_handler'} = 'gbFileTable';
		}
	}
	return 1;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	unless ( ref( $dataset->{'gbFeature'} ) eq "gbFeature" ) {
		$self->{'error'} .=
		    ref($self)
		  . ":DO_ADDITIONAL_DATASET_CHECKS -> you can not add a db_entry to table "
		  . $self->TableName()
		  . " that is not of type gbFeature ($dataset->{'gbFeature'})\n";
	}
	else {
		$dataset->{'tag'}      = $dataset->{gbFeature}->Tag();
		$dataset->{'name'}     = $dataset->{gbFeature}->Name();
		$dataset->{'gbString'} = $dataset->{gbFeature}->getAsGB();
		$dataset->{'start'}    = $dataset->{gbFeature}->Start();
		$dataset->{'end'}      = $dataset->{gbFeature}->End();
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub get_gbFile_for_acc {
	my ( $self, $gbFile_acc ) = @_;
	my $gbFile =
	  $self->{'data_handler'}->{'gbFileTable'}
	  ->getGbfile_obj_for_acc($gbFile_acc);
	$gbFile->Features(
		$self->get_gbFeatures(
			{
				'gbFile_id' => $self->{'data_handler'}->{'gbFileTable'}
				  ->ID_for_ACC($gbFile_acc)
			}
		)
	);
	return $gbFile;
}

=head3 get_rooted_to ( "gbFilesTable" )

This function is implemented in all genomeDB interface classes and allows to switch interfaces.
That might be needed to reformat the perl objects to link to special downstream tables.

You might get a several db_objects if you use this function:

=over

=item 
'gbFeaturesTable'

=item 
'gbFilesTable'

=item 
'ROI_table'

=item 
'SNP_table'

=back

=cut

sub get_rooted_to {
	my ( $self, $root_str ) = @_;
	if ( $root_str eq "gbFeaturesTable" ) {
		return $self;
	}
	elsif ( $root_str eq "gbFilesTable" ) {
		return $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self);
	}
	elsif ( $root_str eq "ROI_table" ) {
		my $interface =
		  $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self);
		$interface->get_rooted_to("ROI_table");
	}
	elsif ( $root_str eq "SNP_table" ) {
		return $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self)
		  ->get_SNP_Table_interface();
	}
	else {
		Carp::confess(
			ref($self)
			  . ":get_rooted_to -> I cant root to \$root_str '$root_str'\n" );
	}
}

sub makeMaster {
	my ( $self, $gbFilesTable_obj ) = @_;
	foreach ( @{ $gbFilesTable_obj->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq "id" ) {
			$_ = undef;
		}
	}
	$gbFilesTable_obj->{'data_handler'}->{'gbFeatureTable_obj'} = undef;

	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq "gbFile_id" ) {
			$_->{'data_hanlder'} = 'gbFileTable';
		}
	}
	$self->{'linkage_info'}                  = undef;
	$gbFilesTable_obj->{'linkage_info'}      = undef;
	$self->{'data_handler'}->{'gbFileTable'} = $gbFilesTable_obj;
	$self->{'genomeID'}                      = $gbFilesTable_obj->{'genomeID'};
	return $self;
}

sub getNucleosomePositioning_Table {
	my ($self) = @_;
	use stefans_libs::database::genomeDB::nucleosomePositioning;
	unless (
		ref( $self->{'nucleosomePositioning'} ) eq 'nucleosomePositioning' )
	{
		$self->{'nucleosomePositioning'} =
		  nucleosomePositioning->new( $self->{dbh}, $self->{debug} );
		$self->{'nucleosomePositioning'}->{'data_handler'}->{'gbFilesTable'} =
		  $self->{'data_handler'}->{'gbFileTable'}->makeMaster($self);
		$self->{'nucleosomePositioning'}->TableName( $self->TableBaseName() );
		$self->{'nucleosomePositioning'}->create()
		  unless (
			$self->tableExists( $self->{'nucleosomePositioning'}->TableName ) );
	}
	return $self->{'nucleosomePositioning'};
}

sub get_gbFile_for_gbFile_id {
	my ( $self, $gbFile_id ) = @_;
	my $gbFile =
	  $self->{'data_handler'}->{'gbFileTable'}
	  ->getGbfile_obj_for_id($gbFile_id);
	Carp::confess(
		ref($self)
		  . ":get_gbFile_for_gbFile_id -> we will die here as the gbFileID $gbFile_id is not defined in the databse!\n"
	) unless ( defined $gbFile );

	$gbFile->Features( $self->get_gbFeatures( { 'gbFile_id' => $gbFile_id } ) );
	return $gbFile;
}

sub get_genes_in_chromosomal_region_as_bedFile {
	my ( $self, $chr, $start, $end ) = @_;

	my ( $data, $data_table, $chr_chr );
<<<<<<< HEAD
	my $bed_file = stefans_libs::file_readers::bed_file->new();
	$chr_chr = $chr; 
	$chr_chr = "chr$chr" unless ( $chr =~ m/chr/);
=======
	my $bed_file = stefans_libs_file_readers_bed_file->new();
	$chr_chr = $chr;
	$chr_chr = "chr$chr" unless ( $chr =~ m/chr/ );
>>>>>>> fc83dc65db03e3ecb1e1e1e6a655834e2cbc798f
	foreach (
		$self->get_chr_calculator()->Chromosome_2_gbFile( $chr, $start, $end ) )
	{
		## now I need to get the chromosomal coordinates for this gbFile
		$data =
		  [ $self->get_chr_calculator()->gbFile_2_chromosome( @$_[0], 1, ) ];
		## and now I need to add the @$data[1] - @$_[1] to each gbFeature in order to scale them right (to the chromosomal dimension)
		$data_table = $self->get_data_table_4_search(
			{
				'search_columns' => [
					ref($self) . '.start',
					ref($self) . '.end',
					ref($self) . ".name"
				],
				'where' => [
					[ ref($self) . '.gbFile_id', '=', 'my_value' ],
					[ ref($self) . '.tag',       '=', 'my value' ]
				],
			},
			@$_[0],
			'gene'
		);
		print "I got "
		  . $data_table->Lines()
		  . " genes for the gbFile id @$_[0]\n";
		print "And I have to add "
		  . (
			$self->get_chr_calculator()->{'gbFile_id_2_chr_start'}->{ @$_[0] } -
			  1 )
		  . "bp to each ogf them.\n";
		foreach my $array ( @{ $data_table->{'data'} } ) {
			@$array[0] +=
			  $self->get_chr_calculator()->{'gbFile_id_2_chr_start'}
			  ->{ @$_[0] } - 1;
			@$array[1] +=
			  $self->get_chr_calculator()->{'gbFile_id_2_chr_start'}
			  ->{ @$_[0] } - 1;
			unshift( @$array, $chr_chr );
		}
		push( @{ $bed_file->{'data'} }, @{ $data_table->{'data'} } );
	}
	return $bed_file;
}

sub get_chromosomal_region {
	my ( $self, $chr, $start, $end ) = @_;
	my $gbFile = gbFile->new();
	$gbFile->{'header'} = gbHeader->new(
		[
			(
				"LOCUS       $chr:$start..$end       "
				  . ( $end - $start + 1 )
				  . " bp  DNA    linear",
				"DEFINITION  the chromosomal region $chr:$start..$end",
				"ACCESSION   $chr:$start..$end",
				"FEATURES             Location/Qualifiers"
			)
		]
	);
	$gbFile->{'SEQ_offset'} = -$start + 1;
	my ( $seq, $last_end, $data, $temp_gbFile );
	foreach (
		$self->get_chr_calculator()->Chromosome_2_gbFile( $chr, $start, $end ) )
	{
		## now I need to get the chromosomal coordinates for this gbFile
		$data =
		  [ $self->get_chr_calculator()->gbFile_2_chromosome( @$_[0], 1, ) ];
		if ( defined $last_end ) {
			print "I add from bp $last_end to bp @$data[1] "
			  . ( @$data[1] - 2 - $last_end )
			  . " 'N's\n";
			for ( my $i = $last_end ; $i < @$data[1] - 2 ; $i++ ) {
				$seq .= 'N';    ## add the gap amount of N's
			}
		}
		## and now I need to add the @$data[1] - @$_[1] to each gbFeature in order to scale them right (to the chromosomal dimension)
		$temp_gbFile = $self->get_gbFile_for_gbFile_id( @$_[0] );
		$seq .= $temp_gbFile->Get_SubSeq( @$_[1], @$_[2] );
		$temp_gbFile->ChangeRegion_Add(
			$self->get_chr_calculator()->{'gbFile_id_2_chr_start'}->{ @$_[0] } -
			  1 );
		print "after gbFile @$_[0] I have gathered "
		  . scalar( @{ $gbFile->Features( $temp_gbFile->Features() ) } )
		  . " Features\n";
		$last_end = @$data[2];

		#print "I have set last_end to $last_end\n";
	}
	$gbFile->Sequence($seq);
	$gbFile->drop_features_that_do_not_match_to( $start, $end );
	return $gbFile;
}

sub get_masked_gbFile_for_gbFile_id {
	my ( $self, $gbFile_id ) = @_;
	my $ROI_table =
	  $self->{'data_handler'}->{'gbFileTable'}->Connect_2_REPEAT_ROI_table();
	my $gbFile = $self->get_gbFile_for_gbFile_id($gbFile_id);
	## now I need the Repeat information!
	my $repeats = $ROI_table->get_ROI_as_gbFeature(
		{ 'tag' => 'repeat', 'gbFile_id' => $gbFile_id } );
	## and now I need to replace the sequences and store the replaced seq in the feature
	my ( $str, $N );
	foreach my $gbFeature (@$repeats) {
		$str = $gbFile->Get_SubSeq( $gbFeature->Start(), $gbFeature->End() );

#print "I got a ".length($str)."gb long fragment for the region $gbFeature->Start() to $gbFeature->End() (".($gbFeature->End()-$gbFeature->Start())."gb long)\n";
		$N = '';
		for ( my $i = 0 ; $i < length($str) ; $i++ ) {
			$N .= 'N';
		}

#print "I got the feature\n".$gbFeature->getAsGB()." and therefore I will substitute the sequence \n$str with \n$N\n";
		$gbFile->{'seq'} =~ s/$str/$N/;
		$gbFeature->AddInfo( 'sequence', $str );
	}
	$gbFile->Features($repeats);

	return $gbFile;
}

sub ID {
	my ( $self, $tableName, $chromosome, $start, $end ) = @_;
	return $self->get_Columns( { 'search_columns' => ['gbFile_id'] },
		{ 'start' => $start, 'end' => $end, 'chromosome' => $chromosome } );
	my ($id) = @{
		$self->getArray_of_Array_for_search(
			{
				'search_columns' => ['gbFile_id'],
				'where'          => [
					[ 'chr_start',  '<', 'my value' ],
					[ 'chr_stop',   '>', 'my value' ],
					[ 'chromosome', '=', 'my value' ]
				]
			},
			( $end, $start, $chromosome )
		)
	  };
	return $id;
}

sub init_getNext_gbFile {
	my ($self) = @_;
	$self->{'__lastGBfile_position'} = undef;
}

sub getNext_gbFile {
	my ($self) = @_;
	unless ( defined $self->{'__lastGBfile_position'} ) {
		$self->{'__lastGBfile_position'} = 0;
		my @result = @{
			$self->getArray_of_Array_for_search(
				{ 'search_columns' => ['gbFilesTable.id'], 'where' => [] }
			)
		  };
		$self->{'gbFile_ids'} = [];
		foreach (@result) {
			push( @{ $self->{'gbFile_ids'} }, @$_[0] );
		}
		print ref($self)
		  . ":getNext_gbFile -> we executed '$self->{'complex_search'};'\n"
		  if ( $self->{'debug'} );
	}
	return undef
	  unless (
		defined $self->{'gbFile_ids'}[ $self->{'__lastGBfile_position'} ] );
	my $gbFile =
	  $self->get_gbFile_for_gbFile_id(
		$self->{'gbFile_ids'}[ $self->{'__lastGBfile_position'}++ ] );
	return $gbFile;
}

sub _get_genomeSearchResult_object {
	die "not implemented!\n";
}

sub Connect_2_result_ROI_table {
	my ($self) = @_;
	return $self->{'data_handler'}->{'gbFileTable'}
	  ->Connect_2_result_ROI_table();
}

sub get_features_in_chr_region_by_type {
	my ( $self, $dataset ) = @_;
	$self->{error} = $self->{warning} = '';
	$self->{error} .= ref($self)
	  . ":get_features_in_chr_region_by_type -> we need a table base name ('
						  baseName ')\n"
	  unless ( defined defined $self->TableName( $dataset->{'baseName'} ) );
	my $where        = [];
	my $search_array = [];
	unless ( defined defined $dataset->{'tag'} ) {
		$self->{warning} .= ref($self)
		  . ":get_features_in_chr_region_by_type -> we set search for 'gene' as you have not told us anything else ('tag')\n";
		$dataset->{'tag'} = 'gene';
	}
	foreach ( 'tag', 'start', 'end' ) {
		if ( defined $dataset->{$_} ) {
			push( @$where, [ $_, '=', 'my_value' ] );
			push( @$search_array, $dataset->{$_} );
		}
	}
	if ( defined $dataset->{'chr'} ) {
		my $helper = $self->get_chr_calculator();
		my @data =
		  $helper->Chromosome_2_gbFile( $dataset->{'chr'}, $dataset->{'start'},
			$dataset->{'end'} );
		my @gbFile_IDs;
		foreach (@data) {
			last unless ( ref($_) eq "ARRAY" );
			push( @gbFile_IDs, @$_[0] );
		}
	}
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' => ['gbString'],
			'where'          => $where,
		},
		@$search_array
	);
	Carp::confess("This function does not do what it should do!");

}

sub Get_Nulcl_prob_overall_for_region {
	my ( $self, $dataset ) = @_;

	my $nulPos = $self->getNucleosomePositioning_Table();
	return $nulPos->Get_prob_overall_for_region($dataset);
}

sub delete_gbFeatures_by_tag_name {
	my ( $self, $dataset ) = @_;
	## we need the tag, the name and the gbFile_id
	$self->{error} = "";
	unless ( defined $dataset->{'tag'} ) {
		$self->{error} .= ref($self)
		  . ":delete_gbFeatures_by_tag_name -> we do not know what to delete!(tag)\n";
	}
	unless ( defined $dataset->{'name'} ) {
		$self->{error} .= ref($self)
		  . ":delete_gbFeatures_by_tag_name -> we do not know what to delete!(name)\n";
	}
	unless ( defined $dataset->{'gbFile_id'} ) {
		$self->{error} .= ref($self)
		  . ":delete_gbFeatures_by_tag_name -> we do not know what to delete!(gbFile_id)\n";
	}
	return 0 if ( $self->{error} =~ m/\w/ );
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'delete_from_gbFeatures' } );
	unless (
		$sth->execute(
			$dataset->{'tag'}, $dataset->{'name'}, $dataset->{'gbFile_id'}
		)
	  )
	{
		die ref($self),
":delete_gbFeatures_by_tag_name -> we got a database error for query '",
		  $self->_getSearchString(
			'delete_from_gbFeatures', $dataset->{'tag'},
			$dataset->{'name'},       $dataset->{'gbFile_id'}
		  ),
		  ";'\n", $self->{dbh}->errstr();
	}
	return 1;
}

sub connect_to_db_xref {
	my ($self) = @_;
	push(
		@{ $self->{'table_definition'}->{'variables'} },
		{
			'name'         => 'id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'link to the db_xrf table',
			'data_handler' => 'db_xref_table'
		}
	);
	$self->{'data_handler'}->{'db_xref_table'} =
	  db_xref_table->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'db_xref_table'}
	  ->TableName( $self->TableBaseName() );
	return 1;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;

	unless ( defined $self->{'data_handler'}->{'db_xref_table'} ) {
		$self->{'data_handler'}->{'db_xref_table'} =
		  db_xref_table->new( $self->{'dbh'}, $self->{'debug'} );
		$self->{'data_handler'}->{'db_xref_table'}
		  ->TableName( $self->TableBaseName() );
	}

	$self->{'error'} .= '';
	my @data = $dataset->{gbFeature}->Info_for_Tag('db_xref');
	my @info;
	if ( defined $data[0] ) {
		$dataset->{'db_xref'} = [];
		foreach my $info (@data) {
			@$info[0] = $1 if ( @$info[0] =~ m/"(.*)"/ );
			@info = split( ":", @$info[0] );
			unless ( scalar(@info) == 2 ) {
				warn ref($self)
				  . "::post_INSERT_INTO_DOWNSTREAM_TABLES -> db_xref data '@$info[0]' could not be parsed!";
				next;
			}

#			print
#"we try to insert into db_xref_table gbFile_id = $id; db_name = $info[0]; db_id = $info[1]\n";
			$self->{'data_handler'}->{'db_xref_table'}->AddDataset(
				{
					'gbFeature_id' => $id,
					'db_name'      => $info[0],
					'db_id'        => $info[1]
				}
			);
		}
	}
	return 1;
}

=head2 get_gbFeatures

This functions internally calls the function get_gbStrings to get the gbStings out of the database.
Afterwards it converts the gbStrings into the gbFeatures and returns the referece to that gbFeature array.
Therefore for this function the same resctrictions and possibilities as for the function get_gbStrings apply.

=cut

sub get_gbFeatures {
	my ( $self, $dataset ) = @_;
	my ( $gbStrings, @gbFeatures );
	$gbStrings =
	  $self->get_Columns( { 'search_columns' => ['gbString'] }, $dataset );
	foreach (@$gbStrings) {
		my $gbFeature = gbFeature->new( "nix", "1..100" );
		$gbFeature->parseFromString($_);
		push( @gbFeatures, $gbFeature );
	}

	#	print "I got ".scalar(@gbFeatures)." gbfeatures here.\n";
	return \@gbFeatures;
}

=head2 get_as_bed_file ({
	'gbFile_id' => [], #a optional list of gbFile_id's
	'tag' => [], #  an optional list of gbFeature tags
	'name' => [], # an optional list of gbFeatures names
	's_start' => 5000, #an optional amount of sequence to add at the ExprStart
	's_end'   => 1000, #an optional value to remove from the ExprStart
	'e_start' => 5000, #an optional amount of sequence to add at the ExprEnd
	'e_end'   => 1000, #an optional value to remove from the ExprEnd
	## if any of the [es]_start or [es]_end values are given you will only get a list of regions touching the ExprStart or end.
})

This function can be used to recieve a (named) bed_file containing all promotors, the transcribed region or a transcription end points.
This function might be horrible slow...

=cut

sub get_as_bed_file {
	my ( $self, $dataset, $outfile ) = @_;
	my ( $s_start, $s_end, $e_start, $e_end ) = (
		$dataset->{'s_start'}, $dataset->{'s_end'},
		$dataset->{'e_start'}, $dataset->{'e_end'}
	);
	my ( $bed_file, $helper, $data_table, $where, $search );
	if ( defined $s_start ) {
		$s_end = 0 unless ( defined $s_end );
	}
	elsif ( defined $s_end ) {
		$s_start = 0;
	}
	if ( defined $e_start ) {
		$e_end = 0 unless ( defined $e_end );
	}
	elsif ( defined $e_end ) {
		$e_start = 0;
	}

	$bed_file = stefans_libs::file_readers::bed_file->new();
	$helper   = 0;
	$where    = [];
	$search   = [];
	foreach (qw(gbFile_id tag name)) {
		next unless ( defined $dataset->{$_} );
		@$search[$helper] = $dataset->{$_};
		@$where[ $helper++ ] = [ $_, '=', 'my_value' ];
	}
	$data_table = $self->get_data_table_4_search(
		{
			'search_columns' => [
				map { "gbFeaturesTable.$_" } 'gbFile_id',
				'start', 'end', 'name', 'gbString'
			],
			'where' => $where,
		},
		@$search
	);
	my $calc = $self->get_chr_calculator();    # chr start end name
	## I will just translate the features from gbFile_id to chromosome name
	my ( $gbFeature, @a, @r );
	for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
		@a         = @{ @{ $data_table->{'data'} }[$i] };
		$gbFeature = $self->str_to_gbFeature( $a[4] );
		if ( $dataset->{'all_exons'} ) {
			
			foreach ( @{ $gbFeature->{'region'}->{'regions'} } ) {
				push(
					@{ $bed_file->{'data'} },
					[
						$calc->gbFile_2_chromosome(
							$a[0],
							$_->{start},
							$_->{end}
						),
						$a[3],
						join( ";",
							@{ $gbFeature->INFORMATION('db_xref') },
							@{ $gbFeature->INFORMATION('transcript_id') } )
					]
				);
			}
		}
		if ( $dataset->{'first_exon'} ) {
			@r = $gbFeature->{'region'}->{'regions'};
			if ( $gbFeature->IsComplement() ) {
				$r[0] = $r[$#r];
			}
			push(
				@{ $bed_file->{'data'} },
				[
					$calc->gbFile_2_chromosome(
						$a[0],
						@{ $r[0] }[0]->{start},
						@{ $r[0] }[0]->{end}
					),
					$a[3],
					join( ";",
						@{ $gbFeature->INFORMATION('db_xref') },
						@{ $gbFeature->INFORMATION('transcript_id') } )
				]
			);
		}
		if ( $dataset->{'promoter'} ) {
			if ( $gbFeature->IsComplement() ) {
				push(
					@{ $bed_file->{'data'} },
					[
						$calc->gbFile_2_chromosome(
							$a[0], $a[2], $a[2] + 3000
						),
						$a[3],
						join( ";",
							@{ $gbFeature->INFORMATION('db_xref') },
							@{ $gbFeature->INFORMATION('transcript_id') } )
					]
				);
			}
			else {
				push(
					@{ $bed_file->{'data'} },
					[
						$calc->gbFile_2_chromosome(
							$a[0], $a[1] - 3000, $a[1]
						),
						$a[3],
						join( ";",
							@{ $gbFeature->INFORMATION('db_xref') },
							@{ $gbFeature->INFORMATION('transcript_id') } )
					]
				);
			}
		}
		else {
			push(
				@{ $bed_file->{'data'} },
				[
					$calc->gbFile_2_chromosome( @a[ 0 .. 2 ] ),
					$a[3],
					join( ";",
						@{ $gbFeature->INFORMATION('db_xref') },
						@{ $gbFeature->INFORMATION('transcript_id') } )
				]
			);
		}
	}

	return $bed_file;
}

sub str_to_gbFeature {
	my ( $self, $str ) = @_;
	my $t = gbFeature->new( 't', '1..2' );
	$t->parseFromString($str);
	return $t;
}

sub __return_bed_array {
	my ( $self, $gbFeature, $where, $start, $end ) = @_;
	if ( $gbFeature->IsComplement() ) {
		return [ $where - $start, $where + $end ];
	}
	else {
		return ( $where - $end, $where + $start );
	}
}

sub __process_gbFeatures_4_bed_file {
	my ( $self, $s_start, $s_end, $e_start, $e_end, $data_table, $bed_file ) =
	  @_;
	my $search = gbFeature->new( 'nix', '1..2' );
	if ( defined $e_start && $s_start ) {
		for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
			$search->parseFromString( @{ @{ $data_table->{'data'} }[$i] }[1] );
			@{ $bed_file->{'data'} }[ $bed_file->Lines() ] = [
				$self->get_chr_calculator()->gbFile_2_chromosome(
					@{ @{ $data_table->{'data'} }[$i] }[0],
					$self->__return_bed_array(
						$search->ExprEnd(), $e_start, $e_end
					),
				),
				$search->Name() . "_mRNA_stop"
			];
		}
	}
	elsif ( defined $s_start ) {
		for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
			$search->parseFromString( @{ @{ $data_table->{'data'} }[$i] }[1] );
			if ( $search->IsComplement() ) {
				@{ $bed_file->{'data'} }[ $bed_file->Lines() ] = [
					$self->get_chr_calculator()->gbFile_2_chromosome(
						@{ @{ $data_table->{'data'} }[$i] }[0],
						$search->ExprStart() - $s_end,
						$search->ExprStart() + $s_start
					),
					$search->Name() . "_promotor"
				];
			}
			else {
				@{ $bed_file->{'data'} }[ $bed_file->Lines() ] = [
					$self->get_chr_calculator()->gbFile_2_chromosome(
						@{ @{ $data_table->{'data'} }[$i] }[0],
						$search->ExprStart() - $s_start,
						$search->ExprStart() + $s_end
					),
					$search->Name() . "_promotor"
				];
			}
		}
	}
	else {
		for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
			$search->parseFromString( @{ @{ $data_table->{'data'} }[$i] }[1] );
			@{ $bed_file->{'data'} }[ $bed_file->Lines() ] = [
				$self->get_chr_calculator()->gbFile_2_chromosome(
					@{ @{ $data_table->{'data'} }[$i] }[0], $search->Start(),
					$search->End()
				),
				$search->Name()
			];
		}
	}
}

=head2 get_Columns

This is a very powerfull function!
You have to specify which columns you want to get in return. If you specify only one columns you will get an list of these column entries.
If you specify more that one column, you will get an array or arrays containing the columns in the order you wanted them.

=head3 The first hash

The first hash should contain an array of column names you want to select. You can of cause select from the whole spectrum of columns we have in the table set.
But take care to name the table from whaere you want to select the column if the anme of the column is not unique!

In this hash we need:
over 1

=item 'search_columns' The name of the columns you want to select

=item 'complex_select' The complex_select string to get some more advanced SQL queries.

=back

The values for both keys are described for the variables_table::getArray_of_Array_for_search function, that is called internally.

=head3 The second hash

You can specify 'start', 'end', 'gbFile_id', 'gbFile_acc', 'chromosome', 'name' and 'tag'.

The searches depend on the values you have specified:

=over 1
=item - 'start', 'end', 'gbFile_id' or 'gbFile_acc', 'name' and 'tag'

You get all gbFeatures with the tag and name that overlapp the region between start and end on the named gbFile

=item -  'start', 'end', 'chromosome', 'name' and 'tag'

You get all gbFeatures with the tag and name that overlapp the region between start and end on the named chromosome

=item - 'gbFile_id' or 'gbFile_acc' , 'name' and 'tag'

You get all gbFeatures with the tag and name on the named gbFile

=item - 'chromosome' , 'name' and 'tag'

You get all gbFeatures with the tag and name on the named chromosome

=back

If either 'name' or 'tag' or both are not defined, you get all column entries, not only those that would match the 'name', 'tag' or both.

=cut

sub get_Columns {
	my ( $self, $hash, $dataset ) = @_;

	$hash->{'complex_select'} = "NIX"
	  unless ( defined $hash->{'complex_select'} );
	my ( $data, @columns );
	Carp::confess(
		ref($self)
		  . ":get_Columns -> we need a hash with the keys 'search_columns' and (optional) 'complex_select'\n"
	) unless defined( ref( $hash->{'search_columns'} ) eq "ARRAY" );
	@columns = @{ $hash->{'search_columns'} };

	return $self->__get_Columns_by_name( $hash, $dataset )
	  unless ( defined $dataset->{'tag'} );
	return $self->__get_Columns_by_tag( $hash, $dataset )
	  unless ( defined $dataset->{'name'} );

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFeaturesTable.tag',  '=', 'my value' ],
					[ 'gbFilesTable.id',      '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFeaturesTable.tag',  '=', 'my value' ],
					[ 'gbFilesTable.acc',     '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{

		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',       '=',  'my value' ],
					[ 'gbFeaturesTable.tag',        '=',  'my value' ],
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',        '=', 'my value' ],
					[ 'gbFeaturesTable.tag',         '=', 'my value' ],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'name'} && defined $dataset->{'tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFeaturesTable.tag',  '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'tag'}
		);
	}
	else {
		Carp::confess(
			    ref($self)
			  . "_get_gbStrings_for_gbFileID_tag_name: we could not get gbStrongs without information what to get\n"
			  . root::get_hashEntries_as_string(
				$dataset, 3, "the unsufficient dataset:"
			  )
		);
	}

	unless ( defined @$data[0] ) {
		warn
"we did not get any results for the query '$self->{'complex_search'};'\n";
	}
	else {
		print "we executed '$self->{'complex_search'};' and got ",
		  scalar(@$data), " results\n";
	}
	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

sub __get_Columns_by_name {
	my ( $self, $hash, $dataset ) = @_;

	my ( $data, @columns );
	@columns = @{ $hash->{'search_columns'} };

	return $self->__get_Columns( $hash, $dataset )
	  unless ( defined $dataset->{'name'} );

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',  '=',  'my value' ],
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFilesTable.id',      '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name', '=', 'my value' ],
					[ 'gbFilesTable.acc',     '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',       '=',  'my value' ],
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.name',        '=', 'my value' ],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'name'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where' => [ [ 'gbFeaturesTable.name', '=', 'my value' ], ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'name'},
		);
	}
	else {
		Carp::confess(
			    ref($self)
			  . "_get_gbStrings_for_gbFileID_tag_name: we could not get gbStrongs without information what to get\n"
			  . root::get_hashEntries_as_string(
				$dataset, 3, "the unsufficient dataset:"
			  )
		);
	}

	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

sub __get_Columns_by_tag {
	my ( $self, $hash, $dataset ) = @_;

	my ( $data, @columns );
	@columns = @{ $hash->{'search_columns'} };

	return $self->__get_Columns( $hash, $dataset )
	  unless ( defined $dataset->{'tag'} );

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',   '=',  'my value' ],
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag', '=', 'my value' ],
					[ 'gbFilesTable.id',     '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag', '=', 'my value' ],
					[ 'gbFilesTable.acc',    '=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',        '=',  'my value' ],
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [
					[ 'gbFeaturesTable.tag',         '=', 'my value' ],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where' => [ [ 'gbFeaturesTable.tag', '=', 'my value' ] ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'tag'}
		);
	}
	else {
		Carp::confess(
			    ref($self)
			  . "_get_gbStrings_for_gbFileID_tag_name: we could not get gbStrongs without information what to get\n"
			  . root::get_hashEntries_as_string(
				$dataset, 3, "the unsufficient dataset:"
			  )
		);
	}

	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

sub __get_Columns {
	my ( $self, $hash, $dataset ) = @_;

	my ( $data, @columns );
	@columns = @{ $hash->{'search_columns'} };

	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [
					[ 'gbFilesTable.id',       '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_id'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	if (   defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'gbFile_id'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [
					[ 'gbFilesTable.acc',      '=',  'my value' ],
					[ 'gbFeaturesTable.end',   '>=', 'my value' ],
					[ 'gbFeaturesTable.start', '<=', 'my value' ],
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_acc'},
			$dataset->{'start'},
			$dataset->{'end'}
		);
	}
	elsif ( defined $dataset->{'gbFile_id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [ [ 'gbFilesTable.id', '=', 'my value' ], ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_id'}
		);
	}
	elsif ( defined $dataset->{'gbFile_acc'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where' => [ [ 'gbFilesTable.acc', '=', 'my value' ], ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'gbFile_acc'}
		);
	}
	elsif (defined $dataset->{'start'}
		&& defined $dataset->{'end'}
		&& defined $dataset->{'chromosome'} )
	{
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => \@columns,
				'where'          => [
					[ 'chromosomesTable.chr_stop',  '>=', 'my value' ],
					[ 'chromosomesTable.chr_start', '<=', 'my value' ],
					[
						[
							'gbFeaturesTable.end', '+',
							'chromosomesTable.chr_start'
						],
						'>',
						'the overall start'
					],
					[
						[
							'gbFeaturesTable.start', '+',
							'chromosomesTable.chr_start'
						],
						'<',
						'the overall end'
					],
					[ 'chromosomesTable.chromosome', '=', 'my value' ]
				],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'start'},
			$dataset->{'end'},
			$dataset->{'chromosome'}
		);
	}
	elsif ( defined $dataset->{'chromosome'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where' =>
				  [ [ 'chromosomesTable.chromosome', '=', 'my value' ] ],
				'complex_select' => $hash->{'complex_select'}
			},
			$dataset->{'chromosome'}
		);
	}
	else {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [@columns],
				'where'          => [],
				'complex_select' => $hash->{'complex_select'}
			}
		);
	}

	if ( scalar(@columns) == 1 ) {
		my (@gbStrings);
		for ( my $i = 0 ; $i < @$data ; $i++ ) {
			push( @gbStrings, @{ @$data[$i] }[0] );
		}
		return \@gbStrings;
	}
	return $data;
}

#sub _get_gbFeatures_for_gbFileID_tag {
#	my ( $self, $dataset ) = @_;
#	my ( $gbStrings, @gbFeatures );
#	$self->{error} = $self->{warning} = '';
#	$gbStrings = $self->_get_gbStrings_for_gbFileID_tag($dataset);
#	foreach my $gbString (@$gbStrings) {
#
#		# warn "we got gbFile string $gbString";
#		my $gbFeature = gbFeature->new( "nix", "1..100" );
#		$gbFeature->parseFromString($gbString);
#		push( @gbFeatures, $gbFeature );
#	}
#	return \@gbFeatures;
#}
#
#sub _get_gbStrings_for_gbFileID_tag {
#	my ( $self, $dataset ) = @_;
#
#	my $sth = $self->_get_SearchHandle(
#		{
#			'baseName'    => $dataset->{'baseName'},
#			'search_name' => 'select_gbString_for_gbID_tag_start_end'
#		}
#	);
#	print "we try ",
#	  $self->_getSearchString(
#		'select_gbString_for_gbID_tag_start_end',
#		$dataset->{'gbFile_id'},
#		$dataset->{'tag'}, $dataset->{'start'}, $dataset->{'end'}
#	  ),
#	  "\n";
#	unless (
#		$sth->execute(
#			$dataset->{'gbFile_id'}, $dataset->{'tag'},
#			$dataset->{'start'},     $dataset->{'end'}
#		)
#	  )
#	{
#		warn ref($self),
#		  ":_get_gbStrings_for_gbFileID_tag -> we got no search results for '",
#		  $self->_getSearchString(
#			'select_gbString_for_gbID_tag_start_end',
#			$dataset->{'gbFile_id'},
#			$dataset->{'tag'}, $dataset->{'start'}, $dataset->{'end'}
#		  ),
#		  "\n", $self->{dbh}->errstr();
#	}
#	my ( $gbString, @gbStrings );
#	$sth->bind_columns( \$gbString );
#	while ( $sth->fetch() ) {
#		push( @gbStrings, $gbString );
#	}
#	return \@gbStrings;
#}

1;
