package gbFilesTable;

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
use stefans_libs::database::genomeDB::chromosomesTable;
use stefans_libs::gbFile;
use stefans_libs::database::genomeDB::ROI_table;
use stefans_libs::database::variable_table;
use stefans_libs::database::external_files;
use stefans_libs::database::system_tables::configuration;

use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

class to access and create the gbFiles tables in the NCBI genomes database

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class gbFilesTable.
And now we do a cvs check ... ;-(

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	my ($self);

	die "we need the dbh at $class new \n" unless ( defined $dbh );
	my $config = configuration->new($dbh);
	$self = {
		debug    => $debug,
		dbh      => $dbh,
		tempPath => $config->GetConfigurationValue_for_tag('web_temp_path'),
		myServed_gbFiles => {},
		selectID         => "select id from database where acc = ?;",
		selectID_for_acc => "select id from database where acc = ?;",
		'exists_id'      => 'select id from database where id = ?',
	};

	## select substr  select substr(t1.seq,t2.start,t2.end), t2.name from  H_sapiens_36_3_gbFeaturesTable as t2, H_sapiens_36_3_gbFilesTable as t1 where t1.id = t2.gbFile_id and t2.tag= 'gene' and t2.name = 'RAG1';

	bless $self, $class if ( $class eq "gbFilesTable" );
	$self->init_tableStructure();
	$self->{_propagateTableName_to} =
	  [ $self->{'data_handler'}->{'chromosomesTable'} ];
	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

sub makeMaster {
	my ( $self, $gbFeatureTable_obj ) = @_;
	foreach ( @{ $gbFeatureTable_obj->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq "gbFile_id" ) {
			$_->{'data_handler'} = undef;
		}
	}
	$gbFeatureTable_obj->{'data_handler'}->{'gbFileTable'} = undef;

	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq "id" ) {
			$_ = undef;
		}
	}
	push(
		@{ $self->{'table_definition'}->{'variables'} },
		{
			'name'           => 'id',
			'type'           => 'INTEGER UNSIGNED',
			'NULL'           => 0,
			'description'    => '',
			'data_handler'   => 'gbFeatureTable_obj',
			'link_to'        => 'gbFile_id',
			'NOT_AddDataset' => 1
		}
	);
	$self->{'data_handler'}->{'gbFeatureTable_obj'} = $gbFeatureTable_obj;
	$self->{'genomeID'}                   = $gbFeatureTable_obj->{'genomeID'};
	$self->{'linkage_info'}               = undef;
	$gbFeatureTable_obj->{'linkage_info'} = undef;

#print "We set the \$self->{'genomeID'} to $self->{'genomeID'} using self ".ref($self)."\n";
	return $self;
}

sub get_rooted_to {
	my ( $self, $root_str ) = @_;
	if ( $root_str eq "gbFilesTable" ) {
		return $self;
	}
	elsif ( $root_str eq "gbFeaturesTable" ) {
		return $self->{'data_handler'}->{'gbFeatureTable_obj'}
		  ->makeMaster($self);
	}
	elsif ( $root_str eq "ROI_table" ) {
		my $interface = ROI_table->new( $self->Database(), $self->{'debug'} );
		$interface->setTableBaseName( $self->TableBaseName() );
		return $interface->makeMaster($self);

	}
	else {
		Carp::confess(
			ref($self)
			  . ":get_rooted_to -> I cant root to \$root_str '$root_str'\n" );
	}
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}   = [];
	$hash->{'UNIQUES'}   = [ ['acc'] ];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'acc',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'header',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'seq_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'needed'       => '',
			'data_handler' => 'external_files',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'masked_seq_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'needed'       => '',
			'data_handler' => 'external_files',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'chromosome_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the chromosomes table',
			'data_handler' => 'chromosomesTable',
			'needed'       => ''
		}
	);
	$hash->{'ENGINE'}           = 'MyISAM';
	$hash->{'CHARACTER_SET'}    = 'latin1';
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['acc']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'data_handler'}->{'chromosomesTable'} =
	  chromosomesTable->new( $self->{dbh}, $self->{debug} );
	$self->{'data_handler'}->{'external_files'} =
	  external_files->new( $self->{'dbh'} );
	$self->{'_propagateTableName_to'} =
	  [ $self->{'data_handler'}->{'chromosomesTable'} ];
	return $dataset;
}

sub get_chr_calculator {
	my ($self) = @_;
	return $self->{'data_handler'}->{'chromosomesTable'}
	  ->get_chr_calculator( $self->{'debug'} );
}

sub get_SNP_Table_interface {
	my ($self) = @_;
	use stefans_libs::database::genomeDB::SNP_table;
	my $SNP_table = SNP_table->new( $self->{'dbh'}, $self->{'debug'} );
	$SNP_table->TableName( $self->TableBaseName() );
	$SNP_table->{'data_handler'}->{'gbFiles_Table'} = $self;
	return $SNP_table;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	unless ( ref( $dataset->{'gbFile'} ) eq "gbFile" ) {
		$self->{'error'} .= ref($self)
		  . ":DO_ADDITIONAL_DATASET_CHECKS -> the gbFile is no gbFile!";
	}
	else {
		$dataset->{'acc'} = $dataset->{'gbFile'}->Version();
		$dataset->{'seq'} = {
			'filename' => $dataset->{'sequence_file'},
			'filetype' => 'data_file',
			'mode'     => 'text'
		};    #$dataset->{'gbFile'}->Sequence();
		$dataset->{'header'} = $dataset->{'gbFile'}->{'header'}->getAsGB();
	}
	return $dataset;
}

sub Add_2_result_ROIs {
	my ( $self, $database_name, $dataArray ) = @_;
	my ($dataset);
	## OK - first we have to get us a new result_region_of_interest object
	$self->Connect_2_result_ROI_table($database_name);
	foreach $dataset (@$dataArray) {
		print
"we add the dataset $dataset->{'gbString'} to $self->{'data_handler'}->{'ROI_table'} \n";
		$self->{'data_handler'}->{'ROI_table'}->AddDataset($dataset);
	}
	return 1;
}

sub Connect_2_result_ROI_table {
	my ($self) = @_;
	return $self->{'data_handler'}->{'ROI_table'}
	  if ( ref( $self->{'data_handler'}->{'ROI_table'} ) eq "ROI_table" );
	$self->{'data_handler'}->{'ROI_table'} =
	  ROI_table->new( $self->{'dbh'}, $self->{'debug'} );
	print ref($self)
	  . "::Connect_2_result_ROI_table -> we try to add a ROI_table table using the table base name "
	  . $self->TableBaseName() . "\n"
	  if ( $self->{'debug'} );
	$self->{'data_handler'}->{'ROI_table'}
	  ->setTableBaseName( $self->TableBaseName() );
	push(
		@{ $self->{'table_definition'}->{'variables'} },
		{
			'name'           => 'id',
			'type'           => 'INTEGER UNSIGNED',
			'NULL'           => 0,
			'description'    => '',
			'data_handler'   => 'ROI_table',
			'link_to'        => 'gbFile_id',
			'NOT_AddDataset' => 1
		}
	);
	return $self->{'data_handler'}->{'ROI_table'};
}

sub Connect_2_REPEAT_ROI_table {
	my ($self) = @_;
	return $self->{'data_handler'}->{'REPEAT_table'}
	  if ( ref( $self->{'data_handler'}->{'REPEAT_table'} ) eq "ROI_table" );
	$self->{'data_handler'}->{'REPEAT_table'} =
	  ROI_table->new( $self->{'dbh'}, $self->{'debug'} );
	print ref($self)
	  . "::Connect_2_result_REPEAT_table -> we try to add a ROI_table table using the table base name "
	  . $self->TableBaseName()
	  . "_repeat" . "\n"
	  if ( $self->{'debug'} );
	$self->{'data_handler'}->{'REPEAT_table'}
	  ->setTableBaseName( $self->TableBaseName() . "_repeat" );
	return $self->{'data_handler'}->{'REPEAT_table'};
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;

	if (
		ref( $self->{'data_handler'}->{'gbFeatureTable_obj'} ) eq
		"gbFeaturesTable" )
	{
		foreach my $gbFeature ( @{ $dataset->{'gbFile'}->Features() } ) {
			$self->{'data_handler'}->{'gbFeatureTable_obj'}->AddDataset(
				{
					'gbFeature' => $gbFeature,
					'gbFile_id' => $id,
					'gbFile'    => { 'id' => $id }
				}
			);
		}
	}
	else {
		warn ref($self)
		  . ":we can not add the Features for this gbFile, as we have no gbFeatiresTable!\n";
	}
	return 1;
}

sub _check_gbFeature_add {
	my ( $self, $dataset ) = @_;
	$self->{error} = '';
	$self->{error} .=
	  ref($self) . ":_check_gbFeature_add -> we need the gbFile_id\n"
	  unless ( defined $dataset->{'gbFile_id'} );
	$self->{error} .= ref($self)
	  . ":_check_gbFeature_add -> we need the gbFeature\n"
	  unless (
		(
			defined $dataset->{'gbFeature'}
			&& $dataset->{'gbFeature'}->isa("gbFeature")
		)
	  );
	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub Add_gbFeature {
	my ( $self, $dataset ) = @_;
	die $self->{error} unless ( $self->_check_gbFeature_add($dataset) );
	$dataset->{'baseName'} = $self->{'_tableName'}
	  unless ( defined $dataset->{'baseName'} );
	return $self->{'gbFeatures'}->AddDataset(
		$dataset->{'baseName'},
		$dataset->{'gbFile_id'},
		$dataset->{'gbFeature'}
	);
}

sub delete_gbFeatures_by_tag_name {
	my ( $self, $dataset ) = @_;
	return $self->{'gbFeatures'}->delete_gbFeatures_by_tag_name($dataset);
}

sub get_featureList_for_gbID_start_end {
	my ( $self, $dataset ) = @_;
	$self->{error} = $self->{warning} = '';
	$self->{error} .=
	  ref($self)
	  . ":get_featureList_for_gbID_start_end -> we need a table base name ('baseName')\n"
	  unless ( defined $self->TableName( $dataset->{'baseName'} ) );
	$self->{error} .=
	  ref($self)
	  . ":get_featureList_for_gbID_start_end -> we need the gbFile ID ('gbFile_id')\n"
	  unless ( defined $dataset->{'gbFile_id'} );

	$self->{error} .=
	  ref($self)
	  . ":get_featureList_for_gbID_start_end -> we need the end in bp on the chromosome ('end')\n"
	  unless ( defined $dataset->{'end'} );
	unless ( defined $dataset->{'tag'} ) {
		$self->{warning} .= ref($self)
		  . ":get_featureList_for_gbID_start_end -> we set search for 'gene' as you have not told us anything else ('tag')\n";
		$dataset->{'tag'} = 'gene';
	}
	unless ( defined $dataset->{'start'} ) {
		$self->{warning} .= ref($self)
		  . ":get_featureList_for_gbID_start_end -> we set the search to start at bp 0 ('start')\n";
		$dataset->{'start'} = 0;
	}
	unless ( defined $dataset->{'end'} ) {
		$self->{warning} .= ref($self)
		  . ":get_featureList_for_gbID_start_end -> we set the search to start at bp <max> ('end')\n";
		$dataset->{'end'} = 10**9;
	}
	unless ( $self->_exists( $dataset->{'gbFile_id'} ) ) {
		$self->{error} .= ref($self)
		  . ":get_featureList_for_gbID_start_end -> sorry, but we do not have that gbFile!\n";
		return undef;
	}
	my $return;

	if ( defined $dataset->{'name'} ) {
		$return =
		  $self->{'gbFeatures'}
		  ->_get_gbFeatures_for_gbFileID_tag_name($dataset);
	}
	else {
		$return =
		  $self->{'gbFeatures'}->_get_gbFeatures_for_gbFileID_tag($dataset);
	}

	$self->{error}   .= $self->{'gbFeatures'}->{error};
	$self->{warning} .= $self->{'gbFeatures'}->{warning};
	return $return;
}

sub _exists {
	my ( $self, $id ) = @_;
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'exists_id' } );
	my $value = $sth->execute($id);
	if ( $value == 1 ) {
		return 1;
	}
	else {
		return 0;
	}
	return undef;
}

sub getGbFiles_for_Gene_Name {
	my ( $self, $tag, $name, $upstream, $downstream ) = @_;
	my ( @gbFiles, $regions );
	## that will be quite complex stuff!
	## -check for the name part - not NULL or something that will give thousands of results!

	## 1. select all ids for the tag / name combination
	my $IDs = $self->{gbFeatures}->all_for_feature_tag_and_name( $tag, $name );

	## 2. it will get horrible if the infos are spread over more that one gbFile!
	foreach my $hashRef (@$IDs) {
		## first we have to get the gbFile_id and the gbFeature of that entry!!
	  #warn "got a search result $hashRef->{gbFile_id} $hashRef->{gbFeature}\n";
		$self->getGbfile_obj_for_id( $hashRef->{gbFile_id} )
		  ;    ## will be stored anyways...
		unless ( defined $regions->{ $hashRef->{gbFile_id} } ) {
			$regions->{ $hashRef->{gbFile_id} } = {
				start => $hashRef->{gbFeature}->Start - $upstream,
				end   => $hashRef->{gbFeature}->End + $downstream
			};
		}
		else {
			$regions->{ $hashRef->{gbFile_id} }->{end} =
			  $hashRef->{gbFeature}->End + $downstream;
		}
	}
	my $i = 1;
	foreach my $id ( keys %$regions ) {

		#warn "got a ID $id\n";
		$self->getGbfile_obj_for_id($id)->WriteAsGB_toFile(
			"$self->{tempPath}/$tag-$name.gbk",
			$regions->{$id}->{start},
			$regions->{$id}->{end},
			"cut to region $regions->{$id}->{start}..$regions->{$id}->{end}"
		);
		push( @gbFiles, gbFile->new("$self->{tempPath}/$tag-$name.gbk") );
	}
	return \@gbFiles;
}

sub getGbfile_obj_for_acc {
	my ( $self, $acc ) = @_;
	return $self->getGbfile_obj_for_id( $self->ID_for_ACC($acc) );
}

sub getGbfile_obj_for_id {
	my ( $self, $id ) = @_;
	unless ( defined $id ) {
		warn ref($self),
		  ":getGbfile_obj_for_id -> no gbFile for no ID! (basename = "
		  . $self->TableBaseName() . ")\n";
		return undef;
	}
	my $gbFile = gbFile->new();
	my ( $headerStr, $seq ) = $self->getHeader_and_seq_String_for_gbFileID($id);
	## In case I am linked to a repeat table I would like to give the user repeat masked sequences
	return undef unless ( defined $headerStr );
	$headerStr =~ s/\\'/'/g;
	$gbFile->Header( undef, $headerStr );
	$gbFile->Name();
	$gbFile->Sequence($seq);
	return $gbFile;
}

sub Mask_sequence {
	my ( $self, $gbFile_id, $seq_id, $masked_seq_id ) = @_;
	my $mask_it = 0;
	if ( defined $self->{'data_handler'}->{'REPEAT_table'} ) {
		if ( $masked_seq_id > 0 ) {
			my $seq_file = $self->{'data_handler'}->{'external_files'}
			  ->get_fileHandle( { 'id' => $masked_seq_id } );
			my $seq = <$seq_file>;
			close($seq_file);
			return $seq;
		}
	}
	else {    ## the user want the normal seq file
		my $seq_file = $self->{'data_handler'}->{'external_files'}
		  ->get_fileHandle( { 'id' => $seq_id } );
		my $seq = <$seq_file>;
		close($seq_file);
		return $seq;
	}
	## If we come here the user want a masked genome, but we need to mask it first
	my $seq_file = $self->{'data_handler'}->{'external_files'}
	  ->get_fileHandle( { 'id' => $seq_id } );
	my $seq = <$seq_file>;
	close($seq_file);

	my $gb_data = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'acc', 'masked_seq_id' ],
			'where' => [ [ ref($self) . '.id', '=', 'my_value' ] ],
		},
		$gbFile_id
	);
	if ( @{ @{ $gb_data->{'data'} }[0] }[1] > 0 ) {
		## OK the repeat sequence has previousely been created - great!

	}
	## check whether we have data in the table
	if ( defined $self->{'repeats_checked'} ) {
		unless ( $self->{'repeats_checked'} ) {
			warn
"NO repeats for this genome in the database - please import them using the script import_repeat_summary_file.pl\n";
			return $seq;
		}
	}
	else {
		my $t =
		  $self->{'data_handler'}->{'REPEAT_table'}->get_data_table_4_search(
			{
				'search_columns' =>
				  [ ref( $self->{'data_handler'}->{'REPEAT_table'} ) . '.id' ],
				'where' => [],
				'limit' => 'limit 10'
			}
		  );
		if ( $t->Lines() == 0 ) {
			$self->{'repeats_checked'} = 0;
			return $seq;
		}
		$self->{'repeats_checked'} = 1;
	}
	my $repeats =
	  $self->{'data_handler'}->{'REPEAT_table'}->get_data_table_4_search(
		{
			'search_columns' => [ 'start', 'end' ],
			'where' => [ [ 'gbFile_id', '=', 'my_value' ] ],
		},
		$gbFile_id
	  );

	#   my $s = "The black cat climbed the green tree";
	#	my $z = substr $s, 14, 7, "jumped from"; # climbed
	#   #$s is now "The black cat jumped from the green tree"
	my ( $start, $length );
	print "I replace " . $repeats->Rows() . " regions with N's\n";
	for ( my $i = 0 ; $i < $repeats->Lines() ; $i++ ) {
		( $start, $length ) =
		  $self->start_and_length( @{ @{ $repeats->{'data'} }[$i] }[ 0, 1 ] );
		if ( $start + $length > length($seq) ) {
			print "Problem with gbFile id $gbFile_id\nlength of seq ("
			  . length($seq)
			  . ") is shorter than $start + $length\n";
			next if ( $start > length($seq) );
			$length = length($seq) - $start;
		}
		substr( $seq, $start, $length, 'N' x $length );
	}
	## Now I want to store the matched seq for later!
	## create a temp file
	my $filename =
"$self->{'tempPath'}/masked_seq_gbFile_$self->{'genomeID'}_$gbFile_id.seq";
	open( SEQ, ">$filename" )
	  or
	  Carp::confess("I could not create the maked seq file '$filename'\n$!\n")
	  ;
	print SEQ $seq;
	close(SEQ);

	$masked_seq_id = $self->{'data_handler'}->{'external_files'}->AddDataset(
		{
			'filename' => $filename,
			'filetype' => 'data_file',
			'mode'     => 'text'
		}
	);
	$self->UpdateDataset(
		{ 'id' => $gbFile_id, 'masked_seq_id' => $masked_seq_id } );
	unlink($filename) if ( -f $filename );
	return $seq;
}

sub start_and_length {
	my ( $self, $start, $end ) = @_;
	$start -= 1;
	return ( $start, $end - $start );
}

sub getHeader_and_seq_String_for_gbFileID {
	my ( $self, $id ) = @_;
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'header', 'seq_id', 'masked_seq_id' ],
			'where' => [ [ ref($self) . '.id', '=', 'my_value' ] ]
		},
		$id
	);
	$data_table->Remove_from_Column_Names( $self->TableName() . "." );
	my $hash = $data_table->get_line_asHash(0);
	my $seq =
	  $self->Mask_sequence( $id, $hash->{'seq_id'}, $hash->{'masked_seq_id'} );
	return $hash->{'header'}, $seq;
}

sub ID_for_ACC {
	my ( $self, $acc ) = @_;
	my $array = $self->GET_entries_for_UNIQUE( ['id'], { 'acc' => $acc } );
	return $array->{'id'};
}
1;
