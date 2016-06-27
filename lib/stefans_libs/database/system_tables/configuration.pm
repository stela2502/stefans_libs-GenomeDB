package configuration;

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
use stefans_libs::root;
use stefans_libs::database::variable_table;
use base qw(variable_table);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A table to store all the configuration options of our database system in.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class configuration.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	$dbh = variable_table::getDBH() unless ( ref($dbh) =~ m/::db$/ );
	my ($self);

	$self = {
		debug    => $debug,
		dbh      => $dbh,
	};

	bless $self, $class if ( $class eq "configuration" );

	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "system_settings";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'tag',
			'type'        => 'VARCHAR (400)',
			'NULL'        => '0',
			'description' => 'a unique tag, that is used to get the value',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'value',
			'type'        => 'VARCHAR (400)',
			'NULL'        => '0',
			'description' => 'the vale of that configuration',
			'needed'      => '1'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['tag'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'tag' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}

	return $self;

}

sub expected_dbh_type {
	#return 'dbh';
	#return "not a databse interface";
	return "database_name";
}

sub GetConfigurationValue_for_tag {
	my ( $self, $tag ) = @_;
	my $hash = $self->GET_entries_for_UNIQUE( ['value'], {'tag' => $tag} );
	return $hash->{'value'};
}

sub SetConfig {
	my ( $self, $tag, $value ) = @_;
	return 0 unless ( $tag || $value);
	my $id = $self->AddDataset( {'tag' => $tag, 'value' => $value});
	return $self->UpdateDataset ( { 'id' => $id, 'tag' => $tag, 'value' => $value} );
}

1;
