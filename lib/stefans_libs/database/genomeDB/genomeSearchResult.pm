package genomeSearchResult;

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A data structure, that can hold results from a search across the genome.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class genomeSearchResult.

=cut

sub new {

	my ( $class, $dataset ) = @_;

	unless ( ref($dataset) eq "HASH" && $dataset->{1 }->{start} > -1 ){
		root::print_hashEntries($dataset,2,"the interior of the dataset given to $class -> new() ");
		die "we need an hash of starting proitions in the structure { <gbFile_id> => { 'chr' => chr_id, 'start' => start_on_chr_in_bp} } at startup\n";
	}

	my ($self);

	$self = {
		'gbID_2_chr_start' => $dataset,
		'data'             => {},
		'entries' => 0
	};

	bless $self, $class if ( $class eq "genomeSearchResult" );

	return $self;

}

sub expected_dbh_type {
	#return 'dbh';
	return "not a database interface";
	return "database";
}

sub _check_dataset {
	my ( $self, $dataset ) = @_;
	$self->{error} = $self->{warning} = '';
	$self->{error} .=
	  ref($self) . ":_check_dataset -> we need an array of gbFeatures\n"
	  unless ( ref( @{ $dataset->{'gbFeatures'} }[0] ) eq "gbFeature" );
	$self->{error} .=
	  ref($self)
	  . ":_check_dataset -> we need to know the gbFile_id of the result set\n"
	  unless ( defined $dataset->{'gbFile_id'} );
	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;
	unless ( $self->_check_dataset($dataset) ){
		warn $self->{error} ;
		return 0;
	}
	
	if ( defined $self->{'data'}->{ $dataset->{'gbFile_id'} } ) {
		$self->{warning} .= ref($self)
		  . ":AddDataset -> we already had an result set for gbFile_id $dataset->{'gbFile_id'}!\n";
		push(
			@{ $self->{'data'}->{ $dataset->{'gbFile_id'} } },
			@{ $dataset->{'gbFeatures'} }
		);
		$self->amount_of_entries ( my $add = scalar @{ $dataset->{'gbFeatures'} } );
		return 1;
	}
	$self->amount_of_entries ( my $add = scalar @{ $dataset->{'gbFeatures'} } );
	$self->{'data'}->{ $dataset->{'gbFile_id'} } = $dataset->{'gbFeatures'};
	return 1;
}

sub amount_of_entries{
	my ( $self, $value2add ) = @_;
	$self->{'entries'} += $value2add if ( defined $value2add );
	return $self->{'entries'};
}

sub _check_dataset_4_get_results_in_region {
	my ( $self, $dataset ) = @_;
	$self->{error} = $self->{warning} = '';
	$self->{error} .=
	  ref($self)
	  . ":check_dataset_4_get_results_in_region -> we need a gbFile_id!"
	  unless ( defined $dataset->{'gbFile_id'} );
	$self->{error} .=
	  ref($self)
	  . ":check_dataset_4_get_results_in_region -> we need a start position!"
	  unless ( defined $dataset->{'start'} );
	$self->{error} .=
	  ref($self)
	  . ":check_dataset_4_get_results_in_region -> we need a end position!"
	  unless ( defined $dataset->{'end'} );
	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub get_results_in_region {
	my ( $self, $dataset ) = @_;
	warn $self->{error}
	  unless ( $self->_check_dataset_4_get_results_in_region($dataset) );
	my @result;
	foreach my $gbFeature ( @{ $self->{'data'}->{ $dataset->{'gbFile_id'} } } )
	{
		push( @result, $gbFeature )
		  if ( $gbFeature->Start() < $dataset->{'end'}
			&& $gbFeature->End() > $dataset->{'start'} );
	}
	return \@result;
}

sub getNext {
	my ( $self, $reinit ) = @_;
	unless ( defined $self->{pos} ) {
		$self->{'pos'} = [ keys %{ $self->{data} } ];
		$self->{'act_pos'} =
		  { 'gbFile_id' => @{ $self->{'pos'} }[0], 'id' => 0 };
	}
	elsif ($reinit) {
		$self->{'pos'} = [ keys %{ $self->{data} } ];
		$self->{'act_pos'} =
		  { 'gbFile_id' => @{ $self->{'pos'} }[0], 'id' => 0 };
	}
	## now there could be no entry in that gbFile left
	unless (
		defined @{ $self->{data}->{ $self->{'act_pos'}->{'gbFile_id'} } }
		[ $self->{'act_pos'}->{'id'} ] )
	{
		## now we need to check the next gbFile...
		for ( my $i = 1 ; $i < @{ $self->{'pos'} } ; $i++ ) {
			if ( @{ $self->{'pos'} }[ $i - 1 ] ==
				$self->{'act_pos'}->{'gbFile_id'} )
			{
				$self->{'act_pos'}->{'gbFile_id'} = @{ $self->{'pos'} }[$i];
				$self->{'act_pos'}->{'id'}        = 0;
				last;
			}
		}
		return undef
		  unless (
			defined @{ $self->{data}->{ $self->{'act_pos'}->{'gbFile_id'} } }
			[ $self->{'act_pos'}->{'id'} ] );
	}
	return $self->{'act_pos'}->{'gbFile_id'},
	  @{ $self->{data}->{ $self->{'act_pos'}->{'gbFile_id'} } }
	  [ $self->{'act_pos'}->{'id'}++ ];
}

sub asArray {
	my ($self) = @_;
	my @return;
	foreach my $gbFile ( @{ $self->{'data'} } ) {
		foreach my $gbFeature (@$gbFile) {
			push( @return, $gbFeature );
		}
	}
	return @return;
}
1;
