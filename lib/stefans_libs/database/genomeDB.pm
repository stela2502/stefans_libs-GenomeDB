package genomeDB;

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
use stefans_libs::database::genomeDB::chromosomesTable;
use stefans_libs::database::genomeDB::gbFeaturesTable;
use stefans_libs::database::organismDB;

use stefans_libs::database::variable_table;
use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION



=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class database::genomeDB.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	my ($self);


	$self = {
		debug => $debug,
		save  => {},
		dbh   => variable_table->getDBH( ),
		selectID =>
"select t1.id from genome as t1, organism_id as t2 where t1.version = ? and t1.organism =  t2.id AND t2.organism_tag = ?",
		seclect_actual =>
		  "select id from genome where organism_id = ? order by version",
		select_baseName_for_ID =>
		  "select table_baseString from genome where id = ?"
	};

	$self->{'gbFeaturesTable'} =
	  gbFeaturesTable->new( $self->{dbh}, $self->{debug} );

	bless $self, $class if ( $class eq "genomeDB" );
	
	$self->Database($database);
	
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "genome";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'version',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the version of the genome information',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'organism_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
'this could either be a organism_id or it should be undefined and the tag \'organism\' results in an ID',
			'needed'       => '1',
			'data_handler' => 'organismDB'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'creationDate',
			'type'        => 'DATE',
			'NULL'        => '0',
			'description' => 'the data this version of the genome was released',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the table base string of the genome',
			'needed'      => '1'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'version', 'organism_id' ] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'version', 'organism_id' ]
	  ; # add here the values you would take to select a single value from the database
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'data_handler'}->{'organismDB'} =
	  organismDB->new( $self->{dbh}, $self->{debug} );

	return $self;

}

sub getDescription {
	my ($self) = @_;
	return "This class is a \\textit{MASTER TABLE} class. 
	Therefore, this class simply pushes the main work during the insert process to the downstream modules.
	This class chooses the downstream handler according to the 'manufacturer' hash~key.
	At the moment "
	  . scalar( ( keys %{ $self->{'data_handler'} } ) )
	  . " data_handlers are registered.
	They have the name(s): '"
	  . join( "', '", ( keys %{ $self->{'data_handler'} } ) ) . "'.
	These data~handlers are also described in this document.\n\n";
}

sub printReport {
	my ($self) = @_;
	my $sampleInterface = gbFeaturesTable->new( $self->{dbh}, $self->{debug} );
	$sampleInterface -> TableName( 'genomeDB_table_baseString');
	return $self->_getLinkageInfo()->Print( { 'genome interface' => $sampleInterface } );
}

sub expected_dbh_type {

	#return 'dbh';
	return "database_name";
}

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;
	$self->{error} = '';
	$self->_get_search_array($dataset)
	  ; ## that will take care of all modifications of the dataset prior to the _real_insert statement

	my $table_string =
	  $dataset->{'organism'}->{'organism_tag'} . "_" . $dataset->{'version'};
	$table_string =~ s/\./_/g;

	$dataset->{'table_baseString'} = $table_string;

	$self->{'gbFeaturesTable'}->TableName($table_string);
	$self->{'error'} .= $self->{'gbFeaturesTable'}->{error};
	
	if ( $self->{error} =~ m/\w/ ) {
		warn "we got an error while trying to craete the table_baseString!\n"
		  . $self->{error};
		return 0;
	}
	return 1;
}


sub GetDatabaseInterface_for_Organism {
	my ( $self, $organism ) = @_;
	print ref($self), " we will now create a chromosomesTable object!\n"
	  if ( $self->{debug} );
	my $interface = gbFeaturesTable->new( $self->{dbh}, $self->{debug} );
	print
"Done\nAnd now we try to find the right Table Base name for the organism $organism\n"
	  if ( $self->{debug} );
	my ($tableBaseName, $genomeID) =
	  $self->select_tableBasename_and_genomeID({ 'organism_tag' => $organism });
	unless ( defined $tableBaseName ){
		Carp::confess( ref($self)."::GetDatabaseInterface_for_Organism -> we could not identify a table structure that contains information for $organism\n".
			"We have used this SQL query: '$self->{'complex_search'};'\n".
			"And probably got a database error:'".$self->{'dbh'}->errstr()."'\n"
		) if ( defined $self->{'dbh'}->errstr() );
	}
	print ref($self).":GetDatabaseInterface_for_Organism - we got \$tableBaseName = $tableBaseName and \$genomeID = $genomeID for the organism $organism\n";
	if ( $interface->TableName($tableBaseName) ){
		print ref($self),
		  ": GetDatabaseInterface_for_Organism -> we got a table name: ",
		  $interface->TableName(), "\n"
		  if ( $self->{debug} );
		$interface->{'genomeID'} = $genomeID;
		return $interface;
	}
	else { warn "no dataset for organism string $organism\n"; }
	return undef;
}

=head3 GetDatabaseInterface_for_genomeID

Atribute: the genome id

Return Value: A object of the class gbFeaturesTable or undef if the genomeID is not set.

=cut

sub GetDatabaseInterface_for_genomeID {
	my ( $self, $genome_ID ) = @_;
	print ref($self), " we will now create a chromosomesTable object!\n"
	  if ( $self->{debug} );
	my $interface = gbFeaturesTable->new( $self->{dbh}, $self->{debug} );
	print
"Done\nAnd now we try to find the right Table Base name for the \$genomeID $genome_ID\n"
	  if ( $self->{debug} );
	my ($tableBaseName, $genomeID) =
	  $self->select_tableBasename_and_genomeID({ 'id' => $genome_ID });
	print ref($self).":GetDatabaseInterface_for_Organism - we got \$tableBaseName = $tableBaseName and \$genomeID = $genomeID\n";
	if ( $interface->TableName($tableBaseName) ){
		print ref($self),
		  ": GetDatabaseInterface_for_Organism -> we got a table name: ",
		  $interface->TableName(), "\n"
		  if ( $self->{debug} );
		$interface->{'genomeID'} = $genomeID;
		return $interface;
	}
	else { warn "no dataset for \$genomeID $genomeID\n"; }
	return undef;
}

sub GetDatabaseInterface_for_Organism_and_Version {
	my ( $self, $organism, $version ) = @_;
	return $self->GetDatabaseInterface_for_Organism ($organism ) unless ( defined $version );
	
	print ref($self), " we will now create a chromosomesTable object!\n"
	  if ( $self->{debug} );
	my $interface = gbFeaturesTable->new( $self->{dbh}, $self->{debug} );
	print
"Done\nAnd now we try to find the right Table Base name for the organism $organism and version $version \n"
	  if ( $self->{debug} );
	my ($tableBaseName, $genomeID) =
	  $self->select_tableBasename_and_genomeID({ 'organism_tag' => $organism, 'version' => $version });
	Carp::confess ( "Sorry I do not have the data for the genome $organism + $version\n") unless ( defined $tableBaseName);
	#print ref($self).":GetDatabaseInterface_for_Organism - we got \$tableBaseName = $tableBaseName and \$genomeID = $genomeID\n";
	if ( $interface->TableName($tableBaseName) ){
		print ref($self),
		  ": GetDatabaseInterface_for_Organism -> we got a table name: ",
		  $interface->TableName(), "\n"
		  if ( $self->{debug} );
		$interface->{'genomeID'} = $genomeID;
		return $interface;
	}
	else { warn "no dataset for organism $organism and version $version\n"; }
	return undef;
}

=head2 getGenomeHandle_for_dataset

You can get an genomeInterface for an hash, that should either contain an 'id' or
an 'organism_tag' or an 'organism_tag' and an 'version' tag.
The interface will be of the type gbFeature_table. 
So if you want to have a gbFiles_table based interface you have to use the 
interface_method 'get_rooted_to('gbFilesTable')'.

=cut


sub getGenomeHandle_for_dataset{
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';
	my ( $tableBaseName, $genomeID ) = $self->select_tableBasename_and_genomeID( $dataset);
	my $interface = gbFeaturesTable->new( $self->{dbh}, $self->{debug} );
	if ( $interface->TableName($tableBaseName) ){
		$interface->{'genomeID'} = $genomeID;
		$interface->Database($self->Database );
		return $interface;
	}
	else { warn root::get_hashEntries_as_string( $dataset, 4, "We got no genome interface for this dataset:"); }
	return undef;
}

sub select_tableBasename_and_genomeID {
	my ( $self, $dataset ) = @_;
	my $data;
	if ( defined $dataset->{'id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ref($self).'.table_baseString', ref($self).'.id'],
				'where'          => [ [ ref($self).'.id', '=', 'my value' ] ]
			},
			$dataset->{'id'}
		);
	}
	elsif ( defined $dataset->{'version'} && defined $dataset->{'organism_tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ref($self).'.table_baseString', ref($self).'.id'],
				'where'          => [ 
					[ 'organism_tag', '=', 'my value' ],
					[ ref($self).'.version', '=', 'my value' ],
				 ]
			},
			$dataset->{'organism_tag'},
			$dataset->{'version'}
		);
	}
	elsif ( defined $dataset->{'organism_tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ref($self).'.table_baseString', ref($self).'.id'],
				'where'          => [ 
					[ 'organism_tag', '=', 'my value' ],
				 ],
				 'order_by' => [ ref($self).'.version' ]
			},
			$dataset->{'organism_tag'},
		);
	}
	else {
		Carp::confess ( ref($self).":select_tableBasename_and_genomeID -> sorry, but we can't help you with that serach dataset:\n".root::get_hashEntries_as_string($dataset, 3, "the search dataset:" ) );
	}
	#print "we executed this search $self->{complex_search}\n";
	if ( ref( @$data[0] ) eq "ARRAY" ) {
		return  @{@$data[0]};
	}
	return undef, undef;
}

sub ID {
	my ( $self, $version, $organism ) = @_;

	$self->{execute_searchID} = $self->{dbh}->prepare( $self->{selectID} )
	  unless ( defined $self->{execute_searchID} );
	$organism = $self->{organismDB}->get_organismID_for_tag($organism);
	unless ( $self->{execute_searchID}->execute( $version, $organism ) ) {
		my $str = $self->{selectID};
		$str =~ s/\?/$version/;
		$str =~ s/\?/$organism/;
		warn ref($self),
		  ":ID -> we got an DB error using theis search: '$str;'\n",
		  $self->{dbh}->errstr();
		return undef;
	}
	my @id = $self->{execute_searchID}->fetchrow_array();
	return $id[0];
}

1;
