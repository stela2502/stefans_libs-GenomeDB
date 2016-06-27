package script_register;


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


use stefans_libs::database::system_tables::PluginRegister::PluginList;
use stefans_libs::database::lists::list_using_table;
use XML::Simple;
use base list_using_table;
##use some_other_table_class;

use strict;
use warnings;

sub new {

    my ( $class, $dbh, $debug ) = @_;
    
    Carp::confess ( "we need the dbh at $class new \n" ) unless ( ref($dbh) =~ m/::db$/ );

    my ($self);
	

    $self = {
        debug => $debug,
        dbh   => $dbh,
        XML_SIMPLE => XML::Simple->new( AttrIndent => 1 ),
    };

    bless $self, $class if ( $class eq "script_register" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "script_register";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'script_name',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '0',
               'description'  => 'the name of the executable',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'description',
               'type'         => 'TEXT',
               'NULL'         => '1',
               'description'  => 'a free text to describe the function of the script',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'type',
               'type'         => 'VARCHAR (20)',
               'NULL'         => '0',
               'description'  => 'we do not support all type of scripts, at the moment only perl scripts',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'plugin_list_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => 'this script is only usable if a set of plugins is installed',
               'link_to' => 'list_id',
               'data_handler' => 'PluginList' 
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'script_name' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'script_name' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'PluginList'} = PluginList->new($self->dbh(), $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

sub getFormdefs_4_scriptID{
	my ( $self, $my_id, $formdef_path ) = @_;
	Carp:confess( ref($self)."::getFormdefs_4_scriptID - sorry, but without id you will not get a formdef!") unless  ( defined $my_id );
	my $data_table = $self->get_data_table_4_search(
			{
				'search_columns' => [ ref($self) . ".script_name" ],
				'where'          => [
					[ ref($self) . "id",    '=',  'my_value' ]
				]
			}, $my_id
		)->get_line_asHash(0);
	return [] unless (defined $data_table);
	my $script_name = $data_table->{ref($self) . ".script_name"};
	## HURAY - now we only need to find the XML file that contains the formdef infos I need!!
	Carp::confess ( "Sorry, but we can not open the file ".$formdef_path."/". $script_name. ".xml"."n") unless ( -f $formdef_path."/". $script_name. ".xml" );
	my $xml_data = $self->{'XML_SIMPLE'}->XMLin( $formdef_path."/". $script_name. ".xml" );
	Carp::confess ( root::get_hashEntries_as_string($xml_data, 4,"Sorry, but we can not use this formdef ")) unless ( ref( $xml_data->{'formdef'}) eq "ARRAY");
	return $xml_data->{'formdef'};
}



sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
