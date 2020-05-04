package organismDB;

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
use base "variable_table";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store organism data in. 
The organism Data is also used by the database::genomeDB, the personDB and the nimblegeneDB (up to now).

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class organismDB.
INFO: You can use this class to store the organism info in each and every database.
Therefore, you have to provide a connected database handle to the new() function.
=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class:new -> we need a object of the class DBI at startup!"
	  unless ( defined $dbh );
	my ($self);

	$self = {
		dbh                 => $dbh,
		debug               => $debug,
		'select_id_for_tag' => "select id from organism where organism_tag = ?",
		'select_id_for_name' =>
		  "select id from organism where organism_name = ?",
		'select_tag_name_for_id' =>
		  "select organism_tag, organism_name from organism where id = ?",
		'select_all_for_DATAFIELD' =>
		  'select * from organism where DATAFIELD = ?'
	};

	bless $self, $class if ( $class eq "organismDB" );
	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type{
	return 'dbh';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "organism";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'organism_tag',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the organism tag as used by NCBI',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'organism_name',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '1',
			'description' => 'a free to choose organism name',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'Species_ID',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'The species ID used e.g. by the NCBI Taxonomy system',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['organism_tag'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['organism_tag']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName ) ) {
		$self->create();
	}

	return $dataset;
}

#=head2 check_dataset
#
#In order to insert a usefull database entry, we need some entries:
#
#=over 3
#
#=item  organism_tag => the tag of the database entry -
#take care, that this entry is also found in the NCBI genomes sections, as this tag will be used to download the genome if needed!
#The test will fail, if this particular genome is not in the NCBI database. You can also add some exceptions to that rule.
#But the exceptions are mainly used for test purposes. Take care, that you import the genome database for the exception by hand.
#
#=item organism_name => an optional organism name.
#
#=back
#
#=cut
#
#sub check_dataset {
#	my ( $self, $dataset ) = @_;
#	$self->{error} = $self->{warning} = '';
#	if ( defined $dataset->{id}){
#		my $data = $self->_select_all_for_DATAFIELD( $dataset->{'id'}, "id" );
#			foreach my $exp (@$data) {
#			return 1 if $exp->{'id'} = $dataset->{'id'};
#		}
#		$dataset->{'id'} = undef;
#	}
#	$self->{error} .=
#	  ref($self)
#	  . ":AddDataset -> we need a organism_tag as used by NCBI to tag its genomes!\n"
#	  unless ( defined $dataset->{organism_tag} );
#	$self->{warning} .=
#	  ref($self) . ":AddDataset -> you have not provided a organism_name\n"
#	  unless ( defined $dataset->{organism_name} );
#	return 0 if ( $self->{error} =~ m/\w/ );
#	return 1;
#}

#sub AddDataset {
#	my ( $self, $dataset ) = @_;
#
#	unless ( $self->check_dataset($dataset) ) {
#		die $self->{error} . $self->{warning};
#	}
#	return $dataset->{'id'} if ( defined $dataset->{'id'});
#
#	if ( $self->{debug} ) {
#		print ref($self),
#		  ":AddDataset -> we are in debug mode - no real inserts\n";
#		print $self->_getSearchString(
#			'insert',
#			$dataset->{organism_tag},
#			$dataset->{organism_tag}
#		  ),
#		  ";\n\n";
#	}
#	else {
#		if ( defined $self->get_organismID_for_tag( $dataset->{organism_tag} ) )
#		{
#			return $self->get_organismID_for_tag( $dataset->{organism_tag} );
#		}
#		my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
#		unless (
#			$sth->execute( $dataset->{organism_tag}, $dataset->{organism_tag} )
#		  )
#		{
#			die ref($self), ":AddDataset -> we had an sql error executing",
#			  $self->_getSearchString(
#				'insert',
#				$dataset->{organism_tag},
#				$dataset->{organism_tag}
#			  ),
#			  "\n", $self->{dbh}->errstr();
#		}
#	}
#
#	return $self->get_organismID_for_tag( $dataset->{organism_tag} );
#}

sub get_organismID_for_name {
	my ( $self, $name ) = @_;

	my $id;

	if ( $self->{debug} ) {
		print ref($self), ":get_organismID_for_name -> debug mode\n",
		  $self->_getSearchString( 'select_id_for_name', $name ), ";\n";
		return 1;
	}

	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'select_id_for_name' } );
	$sth->execute($name);
	$sth->bind_columns( \$id );
	$sth->fetch();
	return $id;
}

sub get_organismID_for_tag {
	my ( $self, $tag ) = @_;

	my $id;

	if ( $self->{debug} ) {
		print ref($self), ":get_organismID_for_tag -> debug mode\n",
		  $self->_getSearchString( 'select_id_for_tag', $tag ), ";\n";
		return 1;
	}

	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'select_id_for_tag' } );
	$sth->execute($tag);
	$sth->bind_columns( \$id );
	$sth->fetch();
	return $id;
}

sub get_organism_tag_name_for_id {
	my ( $self, $id ) = @_;
	warn ref($self), ":get_organism_tag_name_for_id -> we got no ID!\n"
	  unless ( defined $id );
	if ( $self->{debug} ) {
		print ref($self), ":get_organism_tag_name_for_id -> debug mode\n",
		  $self->_getSearchString( 'select_tag_name_for_id', $id ), ";\n";
		return 1;
	}
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'select_tag_name_for_id' } );
	unless ( $sth->execute($id) ) {
		warn "we could not execute '",
		  $self->_get_SearchHandle( 'select_tag_name_for_id', $id ), "\n",
		  $self->{dbh}->errstr();
		return 0;
	}
	return $sth->fetchrow_array();
}

## organism_tag, organism_name
#sub create {
#	my ($self) = @_;
#
#	my $stableName = $self->{dbh}->do( "
#DROP table if exists organism;" );
#
#	my $createString = "
#CREATE TABLE organism (
#	id  INTEGER UNSIGNED auto_increment,
#	organism_tag varchar (40 ) default '' NOT NULL,
#	organism_name varchar (40) default '',
#	KEY ID ( id),
#	UNIQUE  ( organism_tag ),
#	UNIQUE  ( organism_name )
#); ";
#
#	if ( $self->{debug} ) {
#		print ref($self), ":create -> we would run $createString\n";
#	}
#	else {
#		$self->{dbh}->do($createString) or die $self->{dbh}->{errstr};
#		$self->{__tableNames} = undef;
#	}
#	return 1;
#}
#
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
#	my ( @return, $id, $organism_tag, $organism_name);
#	$sth->bind_columns( \$id,  \$organism_tag, \$organism_name);
#	while ( $sth->fetch() ) {
#		push(
#			@return,
#			{
#				'id'           => $id,
#				'organism_tag' => $organism_tag,
#				'organism_name' => $organism_name
#			}
#		);
#	}
#	return \@return;
#}
1;
