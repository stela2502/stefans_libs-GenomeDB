package errorTable;

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
use stefans_libs::database::system_tables::jobTable;
use stefans_libs::database::variable_table;
use base qw(variable_table);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to log critical errors during script execution

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class errorTable.pm.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}
	my ($self);

	$self = {
		debug => $debug,
		dbh   => variable_table::getDBH( 'root', $database ),
		'delete_for_id' => 'delete from error_log where id = ?'
	};

	bless $self, $class if ( $class eq "errorTable" );



	my $hash;
	$hash->{'UNIQUES'}    = [['md5_sum']];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "error_log";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'job_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'data_handler'      => 'jobTable'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'time',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
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
			'type'        => 'char (32)',
			'NULL'        => '0',
			'description' => 'need to search for the descriptions',
			'needed'      => ''
		}
	);
	$self->{'table_definition'} = $hash;
	$self->{'Group_to_MD5_hash'} = ['description'];
	$self->{'UNIQUE_KEY'} = ['md5_sum']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables
	$self->{'data_handler'} ->{'jobTable'} = jobTable->new( variable_table::getDBH());
##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}

	return $self;

}

sub expected_dbh_type {
	return "database_name";
}


sub set_error_log {
	my ( $self, $workload ) = @_;
	return $self->AddDataset($workload );
}

sub select_errors_for_program {
	my ( $self, $programID ) = @_;
	return $self->_select_all_for_DATAFIELD(
		 $programID , 'evaluation_string' );
}

sub select_errors_for_description {
	my ( $self, $data ) = @_;
	my $hash = { 'description' => $data};
	$self->_create_md5_hash( $hash );
	return $self->_select_all_for_DATAFIELD(
		  $hash->{'md5_sum'} , 'md5_sum' )
	  ;
}

sub delete_errors_for_ID {
	my ( $self, $PID ) = @_;
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'delete_for_id' } );
	unless ( $sth->execute($PID) ) {
		die ref($self),
		  ":delete_workload_for_ID got a database error using the query '",
		  $self->_getSearchString( 'delete_for_id', $PID ),
		  ";\n", $self->dbh()->errstr;
	}
	return 1;
}

1;
