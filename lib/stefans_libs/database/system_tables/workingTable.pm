package workingTable;

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
use Shell qw(ps kill killall);
use stefans_libs::root;
use stefans_libs::database::variable_table;
use base qw(variable_table);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A table to store actual working processes and there work in.
All programs that use that table have to interprete the data in that table themselves.
There is only some things in that table - the PID of the process, +
the starting time and the a entry called workload, that is a text formated entry, 
where the processes can store there actual workload in.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class workingTable.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";

		#warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}
	my ($self);

	$self = {
		debug             => $debug,
		'second_modifier' => 1,        #this varaibale can be changed for tests
		'dbh'              => variable_table->getDBH(),
		'database'         => $database,
		select_for_program =>
		  'select * from workload where evaluation_string = ?',
		'select_for_PID'         => 'select * from workload where PID = ?',
		'select_for_description' =>
		  'select * from workload where description = ?',
		delete_for_PID => 'delete from workload where PID = ?'
	};

	bless $self, $class if ( $class eq "workingTable" );
	$self->Database($database);
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "workload";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'PID',
			'type'        => 'CHAR ( 6 )',
			'NULL'        => '0',
			'description' => 'the PID of the worker process',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'jobTable_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' =>
			  'the entry in the jobTable that is processed at the moment',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start_time',
			'type'        => 'TIMESTAMP',			
			'default' => 'CURRENT_TIMESTAMP',
			'NULL'        => '0',
			'description' => 'the execution start time',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['jobTable_id'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} =
	  ['jobTable_id']
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

sub link_2_jobsTable {
	my ( $self, $table_obj ) = @_;
	Carp::confess( "Can not link to a " . ref($table_obj) . " object\n" )
	  unless ( ref($table_obj) eq 'jobTable' );
	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq 'jobTable_id' ) {
			$_->{'data_handler'} = 'jobTable';
		}
	}
	$self->{'data_handler'}->{'jobTable'} = $table_obj;
	return 1;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	return 1;
}

sub expected_dbh_type {
	return "database_name";
}

sub set_workload {
	my ( $self, $workload ) = @_;
	return $self->AddDataset($workload);
}

=head2 get_TempPath_4_id ( workload id )

this function returns the job_id and the temp_path or '',''.

=head2 Add_2_Results_Files ( $job_id, [files] )

this function can be used to add a list of result files to the job_table. 
This is extremely useful for automatic scripts, as they can add their 
result files to the web frontend using the the get_TempPath_4_id + Add_2_Results_Files functions.

=cut

sub get_TempPath_4_id {
	my ( $self, $id ) = @_;
	unless ( defined $self->{'data_handler'}->{'jobTable'} ) {
		$self->link_2_jobsTable( jobTable->new( $self->{'dbh'} ) );
	}
	my ( $job_table, $data );
	$job_table = ref( $self->{'data_handler'}->{'jobTable'} );
	$data      = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ $job_table . '.id', $job_table . '.temp_path' ],
			'where' => [ [ ref($self) . '.id', '=', 'my_value' ] ],
		},
		$id
	);
	return @{ @{ $data->{'data'} }[0] }[1..2]
	  if ( ref( @{ $data->{'data'} }[0] ) eq "ARRAY" );
	Carp::confess ( "I could not get the expected results for my search \n\t'$self->{'complex_search'};'\n");
	return '', '';
}

sub Add_2_Results_Files {
	my ( $self, $job_id, $file ) = @_;
	unless ( defined $self->{'data_handler'}->{'jobTable'} ) {
		$self->link_2_jobsTable( jobTable->new( $self->{'dbh'} ) );
	}
	if ( ref($file) eq "ARRAY" ) {
		$file = join( ";", @$file );
	}
	return 0 unless ( defined $file );
	return $self->{'data_handler'}->{'jobTable'} -> Add_2_Results_Files ( $job_id, $file );
}

=head2 get_zombi_working_processes()

This function will check, whether any of the working processes has not finished up.
That might be due to a buggy implementation - but that should be my problem.
The job_demon script does handle the updates all by itself.

More likely is, that there has been an error in the script and therefore it did not finishe as expected.
On explanation would be that you tried to export a LabBook, but the LabBook had internal errors and
therefore the pdflatex run could not be finished.

Therefore you shoudl check whether the PIDs are still up and running.
You have given the system a max run time in minutes. If that is exceesed you will get the report.
If the process is stil running you should end it and report an error.
  
the function will return an hash like
{' job_id ' => '', ' PID ' => '', ' workload . id ' => ''}
=cut

sub get_zombi_working_processes {
	my ( $self, @PID ) = @_;
	my $dataset = $self->get_data_table_4_search(
		{
			'search_columns' => [
				ref($self) . '.id',
				ref($self) . '.PID',
				ref($self) . '.start_time',
				ref( $self->{'data_handler'}->{'jobTable'} )
				  . '.max_run_time',
				ref( $self->{'data_handler'}->{'jobTable'} ) . ".id",
			],
			'where' => [],
		}    ##the working processes
	);

	#Carp::confess ( $self->{' complex_search '});
	my $now = DateTime::Format::MySQL->parse_datetime( $self->NOW() );
	my ( $start, $hash, @return, $temp );

	for ( my $i = 0 ; $i < $dataset->Lines() ; $i++ ) {
		$hash = $dataset->get_line_asHash($i);
		if ( $hash->{'workload.start_time'} eq "1" ) {
			Carp::cluck(
				print root::get_hashEntries_as_string (
					$hash, 3, "why did you not parse the date '
				  $hash->{'workload.start_time'} '??"
				)
			);
			next;
		}

		#warn "This is a constant problem here: \$hash->{'workload.start_time'} = '$hash->{'workload.start_time'} '\n";
		$start = DateTime::Format::MySQL->parse_datetime( $hash->{'workload.start_time'} ) ;
		$temp = ( $start -  $now );
		#print root::get_hashEntries_as_string ( $hash , 3 , "The hash that is going to kill me...." );
#		warn "I try to calculate start-now = ".($temp->seconds()+ $temp->minutes * 60 )." and compare that to the max time ".( $hash ->{'job_description.max_run_time'} * 60 * $self->{' second_modifier'})." in seconds\n";
		if ( $temp->seconds + $temp->minutes * 60 > $hash ->{'job_description.max_run_time'} * 60 * $self->{'second_modifier'}){
			push ( @return, {'job_id' => $hash->{'workload.jobTable_id'}, ' PID ' => $hash->{'workload.PID'}, 'workload.id' => $hash->{'workload.id'}} )
		}
	}
	#print root::get_hashEntries_as_string ( \@return , 3 , "I found these problemeatic datasets:" );
	return @return;
}


sub select_workloads_for_PID {
	my ( $self, $PID ) = @_;
	return $self->get_data_table_4_search({
 	'search_columns' => [ref($self).".*"],
 	'where' => [[ref($self).".PID",'=','my_value']],
 	}, $PID)->get_line_asHash(0);
}

sub delete_workload_for_PID {
	my ( $self, $PID ) = @_;
	return 0 unless ( defined $PID );
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'delete_for_PID' } );
	unless ( $sth->execute($PID) ) {
		die ref($self),
		  ":delete_workload_for_PID got a database error using the query '",
		  $self->_getSearchString( 'delete_for_PID', $PID ),
		  ";
		\n ", $self->{'dbh'}->errstr;
	}
	#eval {kill( $PID ) };
	return 1;
}

1;
