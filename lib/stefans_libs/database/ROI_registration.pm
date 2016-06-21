package ROI_registration;

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

use stefans_libs::database::genomeDB;
use stefans_libs::database::variable_table;
use base ('variable_table');

use strict;
use warnings;

sub new {

	my ($class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) =~ m/::db$/ );
	
	my ($self);

	$self = {
		'dbh' => $dbh,
		'debug' => $debug,
	};

	bless $self, $class if ( $class eq "ROI_registration" );
	$self->init_tableStructure();
	return $self;

}

## my SQL CREATE STRING:
#"CREATE TABLE ROI_registration (
#   id INTEGER UNSIGNED auto_increment,
#   cmd TEXT NOT NULL,
#   exec_version VARCHAR(10) NOT NULL,
#   name VARCHAR(40) NOT NULL,
#   ROI_tag VARCHAR(40) NOT NULL,
#   PRIMARY KEY (id),
#   UNIQUE (name)
#   );";


sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "ROI_registration";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'cmd',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'the comand that produced these entries',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'exec_version',
			'type'        => 'VARCHAR (10)',
			'NULL'        => '0',
			'description' => 'the command version',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'ROI_name',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'a unique name for this dataset',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'ROI_tag',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'a automatically created tag to identify the ROIs in the downstream table',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'genome_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => 0,
			'description' => 'The link to the genomeDB',
			'data_hanlder' => 'genomeDB',
		}
	);
			
	push( @{ $hash->{'UNIQUES'} }, ['ROI_name', 'ROI_tag'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'ROI_name', 'ROI_tag' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables
	$self->{'data_handler'}->{'genomeDB'} = genomeDB->new( $self->{'dbh'}, $self->{'debug'} );
	
##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}

	return $dataset;
}

1;

