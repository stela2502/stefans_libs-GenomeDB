package chromosomesTable;

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

use stefans_libs::database::genomeDB::nucleosomePositioning;
use stefans_libs::database::fulfilledTask;
use stefans_libs::database::variable_table;
use stefans_libs::database::genomeDB::genomeSearchResult;
use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

class to access and create the chromosomes tables in the NCBI genomes database

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class chromosomesTable.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	my ($self);
	Carp::confess ( "we need the dbh at $class new \n" ) unless ( ref($dbh) eq "DBI::db" );

	$self = {
		debug         => $debug,
		dbh           => $dbh,
		tableBaseName => undef,
		'selectID' =>
"select id from database where chromosome = ? and  chr_stop >= ? and chr_start <= ?",
		'selectID_start_stop' =>
"select id, chr_start, chr_stop from database where chromosome = ? and  chr_stop >= ? and chr_start <= ?",
		'sel_gbFileID_for_ID' => "select gbFiles_id from database where id = ?",
		'select_all' => 'select gbFiles_id, chromosome, chr_start from database'

	};

	bless $self, $class if ( $class eq "chromosomesTable" );

	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'tax_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'A id from the NCBI TAX database - I do not know what to do with that....',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chromosome',
			'type'        => 'CHAR (2)',
			'NULL'        => '0',
			'description' => 'The chromosome ID - it must not me more that two digits',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chr_start',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the start position on this chromosome',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chr_stop',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the end position on this chromosome',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'orientation',
			'type'        => 'CHAR (1)',
			'NULL'        => '0',
			'description' => 'the orientaion of that gbFile on the chromosome',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'feature_name',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the NCBI name of the database',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'feature_type',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'one more NCBI internal value',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'group_label',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'one more NCBI internal value',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'weight',
			'type'        => 'TINYINT',
			'NULL'        => '1',
			'description' => 'one more NCBI internal value',
			'needed'      => '1'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'chr_start', 'chr_stop', 'chromosome' ] );
	$hash->{'ENGINE'}           = 'MyISAM';
	$hash->{'CHARACTER_SET'}    = 'latin1';
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'chromosome', 'chr_start', 'chr_stop']
	  ; # add here the values you would take to select a single value from the database

## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $self;

}

sub expected_dbh_type {
	return 'dbh';
	#return "database_name";
}

sub get_chr_calculator {
	my ( $self ) = @_;
	return $self->{'chr_calculator'} if ( ref( $self->{'chr_calculator'} ) eq 'chromosomesTable::gbFile_to_chromosome');
	my $data_table = $self->get_data_table_4_search( {
	'search_columns' => [ref($self).".id",ref($self).".chromosome",ref($self).".chr_start",ref($self).".chr_stop",],
	'where' => [ ],});
	$data_table ->Remove_from_Column_Names ( ref($self)."." );
	$data_table ->rename_column ( 'id', 'gbFile_id' );
	$data_table ->rename_column ( 'chr_start', 'start' );
	$data_table ->rename_column ( 'chr_stop', 'end' );
	$self->{'chr_calculator'} = chromosomesTable::gbFile_to_chromosome->new( $data_table, $self->{'debug'} );
	return $self->{'chr_calculator'};
}


package chromosomesTable::gbFile_to_chromosome;

sub new {
	my ( $class, $data_table, $debug ) = @_;
	## the data table contains the gbFile_id, the chromsome name, the start and end positions on the chromosome
	my ($error, $self);
	$error = '';
	Carp::confess ( "Lib error: I did not get the requred data_table!\n") unless ( ref($data_table) eq "data_table");
	foreach ( qw(gbFile_id chromosome start end) ){
		$error .= "chromosomesTable::gbFile_to_chromosome->new()\n\tI miss the $_ variables in the table!\n"unless ( defined $data_table->Header_Position($_) );
	}
	if ( $error =~m/\w/ ){
		Carp::confess ( "LIB_ERROR: the table with the header ".join(" ", @{$data_table->{'header'}})." does not contain the needed vaiables:\n$error\n");
	}
	$data_table = $data_table->Sort_by( [['chromosome', 'lexical'], ['start', 'numeric' ]]);
	print "The sorted data table:\n".$data_table->AsString()."\n" if ( $debug );
	$self = {
		'data' => $data_table,
		'debug' => $debug,
		'chromosomes' => {},
		'chr_start_end' => {},
	};
	$self->{'data'}->createIndex('gbFile_id');
	$self->{'gbFile_id_2_chr_start'} = $data_table ->getAsHash ('gbFile_id', 'start' );
	foreach ( qw(gbFile_id chromosome start end) ){
		($self->{$_}) = $data_table->Header_Position($_);
	}
	foreach ( @{$data_table->GetAsArray('chromosome')} ) {
		$self->{'chromosomes'}->{$_} = 1;
		$self->{'chr_start_end'}->{'chr'.$_} = {'start' => 1e99, 'end' => 0 };
	}
	foreach ( @{$self->{'data'}->GetAll_AsHashArrayRef()} ){
		$self->{'chr_start_end'}->{'chr'.$_->{'chromosome'}} ->{'start'} = $_->{'start'} if ( $_->{'start'} <  $self->{'chr_start_end'}->{'chr'.$_->{'chromosome'}} ->{'start'} );
		$self->{'chr_start_end'}->{'chr'.$_->{'chromosome'}} ->{'end'} = $_->{'end'} if ( $_->{'end'} >  $self->{'chr_start_end'}->{'chr'.$_->{'chromosome'}} ->{'end'} );
	}
	bless $self, $class if ( $class eq "chromosomesTable::gbFile_to_chromosome" );
	return $self;
}

sub chromosome_length{
	my ( $self, $chr ) = @_;
	$chr = 'chr'.$chr unless ( $chr =~ m/^chr/ );
	unless ( defined $self->{'chr_start_end'}->{'length'} ){
		$self->{'chr_start_end'}->{'length'} = $self->{'chr_start_end'}->{'end'} - $self->{'chr_start_end'}->{'start'};
	}
	return $self->{'chr_start_end'};
}

=head2 gbFile_2_chromosome ( $gbFile_id, $start, $end )

returns a list of chr_name, chr_start, chr_end 
=cut

sub gbFile_2_chromosome {
	my ( $self, $gbFile_id, $start, $end) = @_;
	$start = 1 if ( $start == 0 );
	# my $data_table = $self->{'data'}->select_where ( 'gbFile_id',  sub { return 1 if ( $_[0] eq $gbFile_id); return 0; } );
	my $data =  $self->{'data'}->get_line_asHash ($self->{'data'}->get_rowNumbers_4_columnName_and_Entry( 'gbFile_id', $gbFile_id ) );
	unless ( defined $end ) {
		$end = $data->{'end'}- $data->{'start'};
	}
	#print "chr$data->{'chromosome'}, $data->{'start'} +$start -1, $data->{'start'} + $end -1\t";
	return ( 'chr'.$data->{'chromosome'}, $data->{'start'} +$start -1, $data->{'start'} + $end -1 );
}

=head2 chromosomes ()

return a list of chromosome names.

=cut
sub chromosomes {
	my ( $self ) = @_;
	return (sort keys %{$self->{'chromosomes'}});
}

=head2 Chromosome_2_gbFile ( $chr, $start, $end )

returns a array ref containing hits like that:  gbFile_id, gb_start, gb_end
=cut

sub Chromosome_2_gbFile {
	my ( $self, $chr, $start, $end ) = @_;
	my (@return, $pos, $line);
	$end = 3e+9 unless ( defined $end);
	$start = 0 unless ( defined $start);
	$chr =~s/^chr//;
	$pos = 0;
	#root::print_hashEntries( $self, 5, "the interesting data");
	for ( my $i = 0; $i < $self->{'data'}->Lines; $i ++ ) {
		$line = @{$self->{'data'}->{'data'}}[$i];
		#print "Values: ".join(" ", @$line)."\n";
		if ( $self->{'data'}->Lines() > 1 ) {
			next unless ( @$line[$self->{'chromosome'}] eq $chr); ## if there is only one entry in the DB we need to use that!
		}
		next if (  @$line[$self->{'start'}] > $end );
		next if ( @$line[$self->{'end'}] < $start );
		
		#  @$line[$self->{'start'}] <= $end && @$line[$self->{'end'}] >= $start
		#print " @$line[$self->{'start'}] <= $end && @$line[$self->{'end'}] >= $start \n";
		my ( $gb_start, $gb_end );
		if ( @$line[$self->{'start'}] > $start ) { ## the region of interest started in the last gbFile!
			$gb_start = 1;
		}
		else {
			$gb_start = $start - @$line[$self->{'start'}] +1;
		}
		if ( @$line[$self->{'end'}] < $end ){ ## the region of interest end in the next gbFile!
			$gb_end = @$line[$self->{'end'}] - @$line[$self->{'start'}] + 2;
		}
		else {
			$gb_end = $end - @$line[$self->{'start'}] +1;
		}
		$return[$pos++] = [@$line[$self->{'gbFile_id'}], $gb_start, $gb_end ];
	}
	return @return;
}


1;
