package executable_table;

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
use File::Copy;

use stefans_libs::database::system_tables::PluginRegister;

##use some_other_table_class;

=head1 package 'executable_table'

=head2 DESCRIPTION

This package handles the 'executables_table' script definition table.
It depends on the configuration table, as the path to the XML files is
saved using this table ('xml_formdef_path'). We expect the formdef to 
be stored in a path named as the module_id.

=cut

use strict;
use warnings;
use XML::Simple;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) =~ m/::db$/ );

	my ($self);

	$self = {
		debug           => $debug,
		dbh             => $dbh,
		'XML_interface' => XML::Simple->new(
			##	ForceArray => [ 'step', /columns/, 'variable_names' ],
			AttrIndent => 1
		),
	};

	bless $self, $class if ( $class eq "executable_table" );
	$self->init_tableStructure();

	return $self;

}

sub get_Plugin_name_4_executable_name {
	my ( $self, $executable_name ) = @_;
	my $data_hash = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ ref( $self->{'data_handler'}->{'PluginRegister'} ) . ".name" ],
			'where' => [ [ ref($self) . ".executable_name", "=", 'my_value' ] ]
		},
		$executable_name
	)->get_line_asHash(0);
	if ( ref($data_hash) eq "HASH" ) {
		return $data_hash->{ ref( $self->{'data_handler'}->{'PluginRegister'} )
			  . ".name" };
	}
	Carp::confess(
"sorry, but we could not identfy the Plugin name for the executable '$executable_name'\n$self->{'complex_search'}\n"
	  )

}

sub get_executable {
	my ( $self, $executable_name, $version ) = @_;
	my @where = ( [ ref($self) . ".executable_name", "=", 'my_value' ] );
	my @values = ($executable_name);
	if ( defined $version ) {
		push( @where, [ ref($self) . ".executable_version", "=", 'my_value' ] );
		push( @values, $version );
	}
	my $data_hash = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".executable_file" ],
			'where'          => \@where,
			'order_by'       => [ ref($self) . ".executable_version" ]
		},
		@values
	);
	$version |= 'any';
	Carp::confess(
"sorry, the executable '$executable_name' version '$version' is not registered in the system\n$self->{'complex_search'}\n"
		  . $data_hash->Rows() )
	  unless ( $data_hash->Rows() );

	$data_hash = $data_hash->get_line_asHash( $data_hash->Rows() - 1 );
	Carp::confess(
		"The program '$executable_name' could not be found on the file system ("
		  . $data_hash->{ ref($self) . ".executable_file" }
		  . ")!\n" )
	  unless ( -f $data_hash->{ ref($self) . ".executable_file" } );
	return $data_hash->{ ref($self) . ".executable_file" };
}

sub get_Executable_id {
	my ( $self, $executable_name ) = @_;
	my $data_hash = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".id" ],
			'where' => [ [ ref($self) . ".executable_name", "=", 'my_value' ] ]
		},
		$executable_name
	)->get_line_asHash(0);
	if ( ref($data_hash) eq "HASH" ) {
		return $data_hash->{ ref($self) . ".id" };
	}
	Carp::confess(
"sorry, but we could not identfy the executable_id for the name '$executable_name'\n$self->{'complex_search'}\n"
	);
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "executables_table";
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'plugin_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the plugin register',
			'data_handler' => 'PluginRegister'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable_file',
			'type'        => 'VARCHAR (300)',
			'NULL'        => '0',
			'description' => 'the filename to execute the program',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable_name',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the name of the execuable',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable_version',
			'type'        => 'VARCHAR (5)',
			'NULL'        => '0',
			'description' => 'the vresion of the executable',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'executable_description',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'a short description of the executable',
		}
	);
	push( @{ $hash->{'UNIQUES'} },
		[ 'executable_name', 'executable_version' ] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} = [ 'executable_name', 'executable_version' ];

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
	$self->{'data_handler'}->{'PluginRegister'} =
	  PluginRegister->new( $self->dbh(), $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub register_script {
	my ( $self, $PluginName, $script_file, $script_version, $description ) = @_;
	my $file = root->filemap($script_file);
	return $self->AddDataset(
		{
			'executable_file'        => $script_file,
			'executable_description' => $description,
			'plugin_id'              => { 'name' => $PluginName },
			'executable_name'        => $file->{'filename'},
			'executable_version'     => $script_version,
		}
	);

}

sub install_script {
	my ( $self, $PluginName, $PluginID, $script_file ) = @_;
	my $configuration = configuration->new( '', 0 );
	my $script_path =
	  $configuration->GetConfigurationValue_for_tag('script_base');
	my $error = '';
	unless ( -d $script_path ) {
		$error .=
"sorry, but I can not access the 'catalyst_perl_scripts' path '$script_path'\n";
	}
	if ( $error =~ m/\w/ ) {
		warn(
"Sorry, but I could not install the scriptfile $script_file due to the errors:\n"
			  . $error );
		return 0;
	}
	my @temp = split( "/", $script_file );
	my $script = $temp[ @temp - 1 ];
	root->CreatePath( $script_path . "/$PluginName" );
	copy( $script_file, $script_path . "/$PluginName/$script" )
	  or Carp::confess(
"we could not copy '$script_file' to  $script_path/$PluginName/$script \n$!\n"
	  );

	open( SCR, "<$script_path/$PluginName/$script" )
	  or Carp::confess("we could not copy the file!\n$!\n");
	@temp = undef;
	my $read    = 0;
	my $version = '';
	foreach my $line (<SCR>) {
		$read = 0 if ( $line =~ m/^To get further help use / );
		if ($read) {
			chomp($line);
			push( @temp, $line );
		}

		$read    = 1  if ( $line =~ m/^=head1 / );
		$version = $1 if ( $line =~ m/VERSION = 'v(.+)';/ );
	}
	close(SCR);

	#$script =~ s/.pl$//;
	$self->AddDataset(
		{
			'executable_file'        => $script_path . "/$PluginName/$script",
			'executable_description' => join( " ", @temp ),
			'plugin_id'              => $PluginID,
			'executable_name'        => $script,
			'executable_version'     => $version,
		}
	);
	return 1;
}

sub check_formdef {
	my ( $self, $filename ) = @_;
	my $error = '';

	#	unless ( -f $filename ) {
	#		$error .= "check formdef $filename - the file does not exist!\n";
	#	}
	#	else {
	#		my $XML_definition = $self->{'XML_interface'}->XMLin($filename);
	#		my $linkage_info   = linkage_info->new();
	#		my ( $big_step, $i, $i2 );
	#		$i = 0;
	#		warn root::get_hashEntries_as_string( $XML_definition, 10,
	#			"that should look better! " );
	#		foreach $big_step ( @{ $XML_definition->{'step'} } ) {
	#			$i++;
	#			$i2 = 0;
	#
	#			foreach my $step ( @{ $big_step->{'columns'} } ) {
	#				$i2++;
	#				$linkage_info->{'error'} = '';
	#				if ( defined $step->{'type'} && $step->{'type'} eq "db" ) {
	#					if ( defined $step->{'where_array'} ) {
	#						$error .= $linkage_info->{'error'}
	#						  unless (
	#							$linkage_info->__check_where_array(
	#								$step->{'where_array'}
	#							)
	#						  );
	#					}
	#				}
	#				else {
	#					$error .= "we miss the 'thing' in step_$i/value_$i2\n"
	#					  unless ( defined $step->{'thing'} );
	#					$error .= "we miss the 'label' in step_$i/value_$i2\n"
	#					  unless ( defined $step->{'label'} );
	#				}
	#			}
	#		}
	#		$big_step =
	#		  @{ $XML_definition->{'step'} }[ @{ $XML_definition->{'step'} } - 1 ];
	#		unless ( $big_step->{'command'} ) {
	#			$error .= root::get_hashEntries_as_string( $big_step, 3,
	#				"the final step does not include the script file name!" );
	#		}
	#
	#	}
	$self->{'error'} = $error;
	if ( $error =~ m/\w/ ) {
		warn $error . "\n";
		return 0;
	}

	return 1;
}

sub create_job {
	my ( $self, $c, $cmd, $executable ) = @_;
	unless ( defined $c->user() ) {
		Carp::confess(
			"Sorry, but we can not create a Job if you are not logged in!");
	}
	my $username = scalar( $c->user() );
	return $c->model('jobTable')->AddDataset(
		{
			'description'         => $c->session->{'description'},
			'scientist'           => { 'username' => "$username" },
			'labbook_instance_id' => $c->session->{'Entry_id'},
			'labbook_id'          => $c->session->{'LabBook_id'},
			'job_type'            => 'perl_script',
			'cmd'                 => $cmd,
			'executable'          => $executable
		}
	);
}

sub expected_dbh_type {
	return 'dbh';
}

1;
