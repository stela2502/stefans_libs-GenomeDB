package SNP_table;

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
use stefans_libs::database::genomeDB::gbFilesTable;

use base 'variable_table';

sub new {
	my ( $class, $dbh, $debug ) = @_;

	my ($self);

	die "we need the dbh at $class new \n" unless ( ref($dbh) eq "DBI::db" );

	$self = {
		debug => $debug,
		dbh   => $dbh,
	};

	bless $self, $class
	  if ( $class eq "SNP_table" );

	$self->init_tableStructure ();
	
	return $self;

}

=head2 get_Genes_for_SNP_list ( {
	'rsIDs' => [ ],
	'distance' => <max distance in bp>
})

This function will return an object of the type stefans_libs_Latex_Document_gene_description.

=cut

sub get_Genes_for_SNP_list {
	
}

sub expected_dbh_type {
	return 'dbh';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'rsID',
			'type'        => 'VARCHAR(30)',
			'NULL'        => '0',
			'description' => 'RefSNP id',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gbFile_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the link to the a gbFiles table',
			'data_handler' => 'gbFiles_Table',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'position',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the position on the gbFile',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'withdrawn',
			'type'        => 'CHAR (1)',
			'NULL'        => '1',
			'description' => '0 = valid, 1 = withdrawn',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'validationStatus',
			'type'        => 'CHAR (1)',
			'NULL'        => '1',
			'description' => '0 = not validataed , 1-4 validated',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'minorAllele',
			'type'        => 'CHAR (1)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'majorAllele',
			'type'        => 'CHAR (1)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'rsID', 'gbFile_id', 'position' ] );
	push( @{ $hash->{'INDICES'} }, ['gbFile_id'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'rsID', 'gbFile_id', 'position' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables


	$self->{'data_handler'}->{'gbFiles_Table'} = gbFilesTable->new( $self->{'dbh'}, $self->{'debug'});
	return $dataset;
}

1;
