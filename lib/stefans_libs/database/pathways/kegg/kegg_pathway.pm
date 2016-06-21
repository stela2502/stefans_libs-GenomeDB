package kegg_pathway;


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

use stefans_libs::database::organismDB;
use stefans_libs::database::external_files;
use stefans_libs::database::pathways::kegg::hypergeometric_max_hits;

##use some_other_table_class;

use strict;
use warnings;

sub new {

    my ( $class, $dbh, $debug ) = @_;
    
    Carp::confess ( "we need the dbh at $class new \n" ) unless ( ref($dbh) eq "DBI::db" );

    my ($self);

    $self = {
        debug => $debug,
        dbh   => $dbh
    };

    bless $self, $class if ( $class eq "kegg_pathway" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "KEGG_PATHWAYS";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'kegg_pw_id',
               'type'         => 'VARCHAR (20)',
               'NULL'         => '0',
               'description'  => 'the original pathway id (KEGG)',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'picture_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => 'the id of the png pathway picture',
               'data_handler' => 'external_files'
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'pathway_name',
               'type'         => 'VARCHAR (100)',
               'NULL'         => '0',
               'description'  => 'the name of the pathway',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'organism_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => 'the organism id',
               'data_handler' => 'organismDB'
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'description',
               'type'         => 'TEXT',
               'NULL'         => '0',
               'description'  => 'the decription of the pathway',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'pathway_name', 'organism_id' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'pathway_name', 'organism_id' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     $self->{'spare'} = {
     		   'name'         => 'id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => 'need that to link to the hypergeometric_max_hits',
               'data_handler' => 'hypergeometric_max_hits',
               'link_to'      => 'kegg_id'
          };
     push ( @{$hash->{'variables'}}, $self->{'spare'}
     );
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'organismDB'} = organismDB->new($self->{'dbh'}, $self->{'debug'});
     $self->{'data_handler'}->{'external_files'} = external_files->new($self->{'dbh'}, $self->{'debug'});
     $self->{'data_handler'}->{'hypergeometric_max_hits'} = hypergeometric_max_hits->new($self->{'dbh'}, $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	
	for ( my $i = 0; $i < @{$self->{'table_definition'}->{'variables'}}; $i ++ ){
		if ( @{$self->{'table_definition'}->{'variables'}}[$i] -> { 'name' }  eq 'id'){
			splice (@{$self->{'table_definition'}->{'variables'}}, $i,1 );
			$self->{'id_removed'} = 1;
		}
	}
	return 1;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	if ( $self->{'id_removed'} ){
		push ( @{$self->{'table_definition'}->{'variables'}}, $self->{'spare'}  );
	}
	return 1;
}

sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
