package jobTable;

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
use stefans_libs::database::scientistTable;
use stefans_libs::database::LabBook;
use stefans_libs::exec_helper::XML_handler;
use Shell;

use base qw(variable_table);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A table to store the name of the XML job description files and a short description of the files in. The storage Path should be set in the configuration systems table.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class job_description.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	#Carp::confess("we need the dbh at $class new \n")
	$dbh = variable_table->getDBH()
	  unless ( ref($dbh) =~ m/::db$/ );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
	};

	bless $self, $class if ( $class eq "jobTable" );

	my $hash;
	$hash->{'INDICES'} = [ ['job_type'], ['md5_sum'] ];
	$hash->{'UNIQUES'}    = [ [ 'executable', 'md5_sum' ] ];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "job_description";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'a short description of the data',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'scientist_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
			  'link to the scientist that wants to be informed about the data',
			'data_handler' => 'scientistTable'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'labbook_instance_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '1',
			'description' =>
			  'a link where to insert the log for this application'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'labbook_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '1',
			'description' =>
			  'which LabBook to use to resolve the labbook_instance_id'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'job_type',
			'type' => 'VARCHAR (20)',
			'NULL' => '0',
			'description' =>
'at the moment I only support perl_scipts - but in fact all command line programs could be called!',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'cmd',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'the comand line to execute',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable',
			'type'        => 'VARCHAR(200)',
			'NULL'        => '0',
			'description' => 'the name of the execuatble'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'state',
			'type' => 'VARCHAR(70)',
			'description' =>
			  '0 not yet executed;1-99 running; 100 ready, -1 died',
			'needed' => ''
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
	);push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'last_modified',
			'type'        => 'TIMESTAMP',
			'default' => 'CURRENT_TIMESTAMP',
			'NULL'        => '0',
			'description' => '',
			'hidden'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start_date',
			'type'        => 'TIMESTAMP',
			'default' => 'CURRENT_TIMESTAMP',
			'NULL'        => '0',
			'description' => '',
			'hidden'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'max_run_time',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the maximum run time for a process in minutes',
			'hidden'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'result_files',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'a semicolon separated list of expected result files',
			'hidden'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'temp_path',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'a internal temp path setting',
			'hidden'      => 1
		}
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'executable', 'md5_sum', 'start_date' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'Group_to_MD5_hash'} = [ 'cmd', 'start_date' ]
	  ;    # define which values should be grouped to get the 'md5_sum' entry

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables
	$self->{'data_handler'}->{'scientistTable'} =
	  scientistTable->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'LabBook'} =
	  LabBook->new( $self->{'dbh'}, $self->{'debug'} );
##now we need to check if the table already exists. remove that for the variable tables!
	##Carp::confess ( root::get_hashEntries_as_string ( $self , 3 , "the jobTable object" ));
	#Carp::cluck("I create myself in the PID $$\n");
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	return $self;

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
	$job_table = ref( $self );
	$data      = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ $job_table . '.id', $job_table . '.temp_path' ],
			'where' => [ [ $job_table . '.id', '=', 'my_value' ] ],
		},
		$id
	);
	return @{ @{ $data->{'data'} }[0] }
	  if ( ref( @{ $data->{'data'} }[0] ) eq "ARRAY" );
	Carp::confess ( "I could not get the expected results for my search \n\t'$self->{'complex_search'};'\n");
	return '', '';
}

sub Add_2_Results_Files {
	my ( $self, $job_id, $file ) = @_;
	return 0 unless ( defined $file );
	
	if ( ref($file) eq "ARRAY" ) {
		$file = join( ";", @$file );
	}
	

	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => ['result_files'],
			'where'          => [
				[
					ref( $self ) . '.id', '=',
					'my_value'
				]
			],
		},
		$job_id
	);
	my $result_file = @{ @{ $data->{'data'} }[0] }[0];
	if ( $result_file =~ m/\w/ ) {
		$result_file .= ";$file";
	}
	else {
		$result_file .= "$file";
	}
	return $self
	  ->UpdateDataset( { 'id' => $job_id, 'result_files' => $result_file } );
}

=head2 worker_is_OK

returns 1 if the worker demon from the LabBook project is running.
returns 0 if not.

=cut

sub worker_is_OK {
	my ( $self ) = @_;
	my $sh = Shell->new();
	my $CMD = "jobs_demon.pl";
	my $string = $sh->ps("-A -l -f");
	my @string = split( "\n", "#".$string );
	my (@temp, $PID, $temp);
	foreach ( @string ) {
		if ( $_ =~m/$CMD/){
			return 1;
			$PID = $1 if ( $_ =~ m/ (\d\d\d\d) / );
		}
	}
}
sub TouchJob {
	my ( $self, $jobID ) = @_;
	my $now = $self->NOW();
	return $self->UpdateDataset(
		{ 'id' => $jobID, 'last_modified' => "$now" } );
}

sub get_LabBook_and_Entry_id_4_myID {
	my ( $self, $id ) = @_;
	return undef unless ( defined $id );
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'labbook_id', 'labbook_instance_id' ],
			'where' => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$id
	);
	if ( ref($data_table) eq "data_table" ) {
		return @{ @{ $data_table->{'data'} }[0] };
	}
	return undef;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	$dataset->{'state'} = 'new' unless ( defined $dataset->{'state'} );
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub getResultFiles {
	my ($self, $md5_hash ) = @_;
	my $dataset = $self->get_data_table_4_search(
		{
			'search_columns' => [  ref($self). ".result_files" ],
			'where' => [ [ ref($self) . ".md5_sum", '=', 'my_value' ] ],
		},$md5_hash
	)->get_line_asHash(0);
	return  undef if ( $dataset -> {ref($self). ".result_files"}) eq "none";
	return split(";", $dataset -> {ref($self). ".result_files"} );
}

sub get_next_unprocessed_command {
	my ($self) = @_;
	my $dataset = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.id', ref($self) . '.cmd', ref($self). ".md5_sum" ],
			'where' => [ [ ref($self) . ".state", '=', 'my_value' ] ],
			'order_by' => [ ref($self) . ".id" ],
			'limit'    => 'limit 1'
		},
		'new'
	)->get_line_asHash(0);
	return undef unless ( defined $dataset );
	return $dataset->{ ref($self) . '.id' }, $dataset->{ ref($self) . '.cmd' }, $dataset->{ ref($self). ".md5_sum" };
}

sub FinalizeJob {
	my ( $self, $my_id, @output ) = @_;
	my $dataset = $self->get_data_table_4_search(
		{
			'search_columns' => [
				ref($self) . '.labbook_id',
				ref($self) . '.labbook_instance_id'
			],
			'where' => [ [ ref($self) . '.id', '=', 'my_value' ] ]
		},
		$my_id
	)->get_line_asHash(0);
	$self->UpdateDataset( { 'id' => $my_id, 'state' => 'ready'} );
	return 0 unless ( defined $dataset );
	return $self->{'data_handler'}->{'LabBook'}->Add_2_LabBook_entry(
		$dataset->{ ref($self) . '.labbook_id' },
		$dataset->{ ref($self) . '.labbook_instance_id' },
		join( "\n", @output )
	);
}

sub getEMAIL_address {
	my ( $self, $id ) = @_;
	Carp::confess(
		"we can not return a address if you do not give me an jobs id!\n")
	  unless ( defined $id );
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => ['scientistTable.email'],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$id
	)->get_line_asHash(0);
	Carp::confess(
"I could not get the email using the sql search $self->{'complex_search'}\n"
	) unless ( defined $data );
	return $data->{'scientistTable.email'};
}

sub expected_dbh_type {

	#return 'dbh';
	#return "not a database interface";
	return "database_name";
}

sub Select_by_ID {
	my ( $self, $data ) = @_;
	return $self->_select_all_for_DATAFIELD( $data, 'id' );
}

sub Select_by_Job_Type {
	my ( $self, $data ) = @_;
	return $self->_select_all_for_DATAFIELD( $data, 'job_type' );
}

sub Select_by_Description {
	my ( $self, $data ) = @_;
	my $hash = { 'description' => $data };
	$self->_create_md5_hash($hash);
	return $self->_select_all_for_DATAFIELD( $hash->{'md5_sum'}, 'md5_sum' );
}

1;
