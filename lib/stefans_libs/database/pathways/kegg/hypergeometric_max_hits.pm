package hypergeometric_max_hits;

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
use
  stefans_libs::database::pathways::kegg::hypergeometric_max_hits::background_lists;

##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
	};

	bless $self, $class if ( $class eq "hypergeometric_max_hits" );
	$self->init_tableStructure();
	$self->{'register'} =
	  stefans_libs::database::pathways::kegg::hypergeometric_max_hits::background_lists
	  ->new( $self->{'dbh'}, $self->{'debug'} );
	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "hypergeometric_max_hits";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'reference_dataset',
			'type'        => 'VARCHAR (30)',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'kegg_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'max_count',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'bad_entries',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'reference_dataset', 'kegg_id' ] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} = [ 'reference_dataset', 'kegg_id' ];

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
	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub init_register {
	my ($self) = @_;
	my $data_table = $self->{'register'}->get_data_table_4_search(
		{ 'search_columns' => [ref($self->{'register'}).'.reference_dataset'], },
	);
	return 0 if (  $data_table ->Lines() );
	$data_table = $self->get_data_table_4_search(
		{ 'search_columns' => [ref($self).'.reference_dataset'], },
	);
	my $last_name;
	for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
		unless ( $last_name eq @{ @{ $data_table->{'data'} }[$i] }[0] ) {
			$last_name = @{ @{ $data_table->{'data'} }[$i] }[0];
			print "I try to create the entry '$last_name'\n";
			$self->{'register'}
			  ->AddDataset( { 'reference_dataset' => $last_name } );
		}
	}
	return 1;
}

sub reference_dataset_names {
	my ($self) = @_;
	print "Init register returned: ".
	$self->init_register();
	return $self->{'register'}
	  ->get_data_table_4_search( { 'search_columns' => ['reference_dataset'], },
	  )->GetAsArray('reference_dataset');
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
