package fulfilledTask;

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
use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A table structure, that can be added to each and every table. It creates a new table, that can store logging information about work, that has been done on the 'parent' table. The name of the table is the connection to the original table. And of cause the fact, that the lib handles this thing automatically.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class fulfilledTask.

=cut

sub new {

	my ( $class, $dbh, $parent_table_name, $debug ) = @_;

	unless ( defined $dbh ) {
		die "$class:new -> we need a database handle to be able to work!\n";
	}
	unless ( defined $parent_table_name ) {
		die
"$class:new -> we need a parent_table_name handle to be able to work!\n";
	}

	my ($self);

	$self = {

		#downstream_Tables => ['partizipatingSubjects'],
		debug => $debug,
		dbh   => $dbh,
		'select_specific_task' =>
		  'select * from database where program_id = ? && description = ?'
	};

	#	$self->{'partizipatingSubjects'} =
	#	  partizipatingSubjects->new( $self->{dbh}, $debug );
	bless $self, $class if ( $class eq "fulfilledTask" );

	
	## table definition
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = $self->TableName($parent_table_name);
	push(
		@{ $hash->{'variables'} },
		{ 'name' => 'program_id', 'type' => 'VARCHAR (40)', 'NULL' => '0', 'description' => 'the name of the executable', 'needed' => 1 }
	);
	push(
		@{ $hash->{'variables'} },
		{ 'name' => 'timestamp', 'type' => 'TIMESTAMP', 'NULL' => '0', 'description' => 'the actual time', 'needed' => 0 }
	);
	push(
		@{ $hash->{'variables'} },
		{ 'name' => 'description', 'type' => 'TEXT', 'NULL' => '0',  'description' => 'the description of the performed task', 'needed' => 1}
	);
	push(
		@{ $hash->{'variables'} },
		{ 'name' => 'md5_sum', 'type' => 'VARCHAR (32)', 'NULL' => '0', 'description' => 'purely internal value', 'needed' => 0 }
	);
	push( @{ $hash->{'INDICES'} }, (['program_id'], ['md5_sum']) );
	push( @{ $hash->{'UNIQUES'} }, ( ['md5_sum']) );
	
	$self->{'table_definition'} = $hash;
	
	$self->{'UNIQUE_KEY'} = ['md5_sum']
	  ; # add here the values you would take to select a single value from the database
	$self->{'Group_to_MD5_hash'} = [ 'description', 'program_id' ];

	
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	
	return $self;

}

sub expected_dbh_type{
	return 'dbh', "test_table";
}

sub get_fulfilled_for_id {
	my ( $self, $id ) = @_;
	return $self->_select_all_for_DATAFIELD( $id, "id" );
}

#scientist_id, description, hypothesis, aim, PMID
sub get_fulfilled_for_program_id {
	my ( $self, $id ) = @_;
	return $self->_select_all_for_DATAFIELD( $id, "program_id" );
}

sub get_experimentData_for_description {
	my ( $self, $id ) = @_;
	return $self->_select_all_for_DATAFIELD( $id, "description" );
}

#sub _select_all_for_DATAFIELD {
#	my ( $self, $value, $datafield ) = @_;
#	my $sth = $self->_get_SearchHandle(
#		{
#			'search_name'          => 'select_all_for_DATAFIELD',
#			'furtherSubstitutions' => { 'DATAFIELD' => $datafield }
#		}
#	);
#	unless ( $sth->execute($value) ) {
#		die ref($self),
#":_select_all_for_DATAFIELD ($datafield) -> we got a database error for query '",
#		  $self->_getSearchString( 'select_all_for_DATAFIELD', $value ), ";'\n",
#		  $self->{dbh}->errstr();
#	}
#
#	#program_id, timestamp, description
#	my ( @return, $id, $program_id, $description, $timestamp, $md5 );
#	$sth->bind_columns( \$id, \$program_id,, \$timestamp, \$description,
#		\$md5 );
#	while ( $sth->fetch() ) {
#		push(
#			@return,
#			{
#				'id'          => $id,
#				'program_id'  => $program_id,
#				'timestamp'   => $timestamp,
#				'description' => $description,
#				'md5'         => $md5
#			}
#		);
#	}
#	return \@return;
#}

sub hasBeenDone {
	my ( $self, $dataset ) = @_;

	my $id = $self->_return_unique_ID_for_dataset($dataset);
	return 1 if ( defined $id && $id > 0);
	return 0;
}

1;

