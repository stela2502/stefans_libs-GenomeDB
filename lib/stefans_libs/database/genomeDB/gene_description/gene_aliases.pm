package gene_aliases;

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
use base ('variable_table');

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "gene_aliases" );

	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "gene_aliases";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gene_name',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'one gene alias',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the link to the gene_descriptios table',
		}
	);
	push( @{ $hash->{'INDICES'} }, ['description_id'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['gene_name']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $dataset;
}

1;
