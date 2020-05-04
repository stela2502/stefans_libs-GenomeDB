package db_xref_table;
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
use base ( 'variable_table' );


sub new {

	my ( $class, $dbh, $debug ) = @_;

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
  	};

  	bless $self, $class  if ( $class eq "db_xref_table" );

	$self->init_tableStructure();
	
  	return $self;

}


sub expected_dbh_type {
	return 'dbh';

	#return "not a database interface";
	#return "database_name";
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'UNIQUES'} = [ ['gbFeature_id', 'db_name', 'db_id'] ];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'gbFeature_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'db_name',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'db_id',
			'type'        => 'varchar (20)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);

	$hash->{'ENGINE'}           = 'MyISAM';
	$hash->{'CHARACTER_SET'}    = 'latin1';
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['gbFeature_id','db_name','db_id']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables


	return $dataset;
}

1;
