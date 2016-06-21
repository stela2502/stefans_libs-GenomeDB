package ROI_table;

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
use stefans_libs::database::variable_table;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::file_readers::bed_file;
use base 'variable_table';

sub new {
	my ( $class, $dbh, $debug ) = @_;

	my ($self);

	$dbh = variable_table->getDBH() unless ( ref($dbh) eq "DBI::db" );

	$self = {
		debug => $debug,
		dbh   => $dbh,
	};

	bless $self, $class
	  if ( $class eq "ROI_table" );

	$self->init_tableStructure();
	$self->{'dbh'}->do("SET SQL_MODE = 'NO_UNSIGNED_SUBTRACTION'");

	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

sub makeMaster {
	my ( $self, $gbFiles_obj ) = @_;
	Carp::confess(
		ref($self)
		  . "::makeMaster absolutely needs an gbFilesTable object to work - not $gbFiles_obj"
	  )
	  unless ( ref($gbFiles_obj) eq "gbFilesTable" );
	foreach my $variableDef ( @{ $self->{'table_definition'}->{'variables'} } )
	{
		if ( $variableDef->{'name'} eq 'gbFile_id' ) {
			$variableDef->{'data_handler'} = 'gbFilesTable';
		}
	}
	$self->{'data_handler'}->{'gbFilesTable'} = $gbFiles_obj;
	$self->{'linkage_info'} = undef;
	$gbFiles_obj -> {'linkage_info'} = undef;
	$self->{'master'}                         = 1;
	$self->{'genomeID'}                       = $gbFiles_obj->{'genomeID'};
	return $self;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'} = [ ['tag'], ['name'], ['start'], ['end'], [ 'gbFile_id'] ];
	$hash->{'UNIQUES'} = [ ['md5_sum'] ];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gbFile_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'tag',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (20)',
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

	$self->{'UNIQUE_KEY'} =
	  ['md5_sum']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $dataset;
}

sub getClosestGene_4_ROI_id {
	my ( $self, $id ) = @_;

	Carp::confess(
		    ref($self)
		  . "::getClosestGene_4_ROI_id should not be used, as it does not calculate right and is horrably slow. "
		  . "A better solution is to select the relevant gbFeatures from the right genome_interface and then do a 'manual' comparison"
		  . " as shown in getClosestGene_for_SNP_ID.pl\n" );

	Carp::confess(
		ref($self)
		  . "::getClosestGene_4_ROI_id we need to be the master table to do that"
	  )
	  unless ( $self->{'master'} );

	my $rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => ['gbFeaturesTable.gbString'],
			'where'          => [
				[
					[ 'gbFeaturesTable.start', '-', 'ROI_table.start' ], '<',
					'my_value'
				],
				[ 'gbFeaturesTable.tag', '=', 'my_value' ],
				[ 'ROI_table.id',        '=', 'my_value' ]

			],
			'order_by' => [
				[
					[ 'gbFeaturesTable.start', '-', 'ROI_table.start' ],
					'*',
					[ 'gbFeaturesTable.start', '-', 'ROI_table.start' ]
				]
			],
			'limit' => 'limit 1'
		},
		10000,
		'gene',
		$id
	);

	if ( defined @$rv[0] ) {
		my $gbFeature = gbFeature->new( 'gene', "1..2" );

		$gbFeature->parseFromString( @{ @$rv[0] }[0] );
		return $gbFeature;
	}
	else {
		return undef;
	}
	return undef;
}

=head2 get_ROI_obj_4_id

This function will return a gbFeature object describing the ROI and the gbFile_id or undef if the ROI id could not be found.

=cut

sub get_ROI_obj_4_id {
	my ( $self, $ROI_id ) = @_;
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ 'ROI_table.gbString', 'ROI_table.gbFile_id' ],
			'where' => [ [ 'ROI_table.id', '=', 'my_value' ] ],
		},
		$ROI_id
	);
	return undef unless ( ref( @$data[0] ) eq "ARRAY" );
	my $obj = gbFeature->new( 'nix', "1..2" );
	$obj->parseFromString( @{ @$data[0] }[0] );
	return $obj, @{ @$data[0] }[1];
}

=head2 get_ROI_as_gbFeature ( $dataset )

The dataset should contain some values from which I can select the features.
Options are 'name' (and or) 'tag'
or 'id'. All three or four combinations can also be combined with the gbFile_id option.

The return value is an array_ref containing the gbFeatures (in gbFile scale not in chromosomal scale!)

=cut

sub get_ROI_as_gbFeature {
	my ( $self, $dataset ) = @_;
	my $where        = [];
	my $search_array = [];
	foreach ( 'gbFile_id', 'tag', 'name', 'id' ) {
		if ( defined $dataset->{$_} ) {
			push( @$where, [ $_, '=', 'my_value' ] );
			push( @$search_array, $dataset->{$_} );
		}
	}
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' => ['gbString'],
			'where'          => $where,
		},
		@$search_array
	);
	my @return;
	for (my $i = 0; $i < $data_table->Lines();$i ++ ){
		$return[$i] = gbFeature->new('nix', '1..2' )-> parseFromString (@{@{$data_table->{'data'}}[$i]}[0]);
	}
	return \@return;
}

sub get_ROI_as_bed_file {
	my ( $self, $dataset ) = @_;
	my $where        = [];
	my $search_array = [];
	foreach ( 'gbFile_id', 'tag', 'name', 'id' ) {
		if ( defined $dataset->{$_} ) {
			push( @$where, [ $_, '=', 'my_value' ] );
			push( @$search_array, $dataset->{$_} );
		}
	}
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' => ['gbFile_id', 'start', 'end' ],
			'where'          => $where,
		},
		@$search_array
	);
	my $hash;
	my $return = stefans_libs_file_readers_bed_file->new();
	my $chr_table = chromosomesTable->new( $self->{'dbh'} );
	$hash = $self->TableBaseName ();
	$hash =~s/_repeat$//;
	$chr_table-> setTableBaseName( $hash );
	my $helper = $chr_table-> get_chr_calculator();
	for (my $i = 0; $i < $data_table->Lines();$i ++ ){
		$hash = $data_table-> get_line_asHash ( $i );
		($hash ->{'chr'}, $hash->{'start'}, $hash->{'end'} ) = $helper -> gbFile_2_chromosome ($hash ->{'gbFile_id'}, $hash->{'start'}, $hash->{'end'} );
		@{$return->{'data'}} [ $return->Lines()] =  [$hash ->{'chr'},$hash->{'start'} ,$hash->{'end'} ];
	}
	return $return;
}

sub select_RIO_ids_for_ROI_tag {
	my ( $self, $ROI_tag, $ROI_name ) = @_;
	my $error = 0;
	$error += 1 if ( defined $ROI_tag );
	$error += 1 if ( defined $ROI_name);
	return undef unless ( $error );
	my $data;
	if ( defined $ROI_name && defined $ROI_tag ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['ROI_table.id'],
				'where'          => [
					[ 'ROI_table.tag',  '=', 'my_value' ],
					[ 'ROI_table.name', '=', 'my_value' ]
				]
			},
			$ROI_tag, $ROI_name
		);
	}
	elsif ( defined $ROI_tag) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['ROI_table.id'],
				'where'          => [ [ 'ROI_table.tag', '=', 'my_value' ] ]
			},
			$ROI_tag
		);
	}
	else {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['ROI_table.id'],
				'where'          => [ [ 'ROI_table.name', '=', 'my_value' ] ]
			},
			$ROI_name
		);
	}
	my @return;
	foreach (@$data) {
		push( @return, @$_[0] );
	}
	return \@return;
}

1;
