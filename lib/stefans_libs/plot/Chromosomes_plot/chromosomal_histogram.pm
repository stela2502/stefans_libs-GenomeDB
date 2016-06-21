package stefans_libs::plot::Chromosomes_plot::chromosomal_histogram;

#  Copyright (C) 2010-08-24 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::statistics::new_histogram;
use stefans_libs::file_readers::bedGraph_file;
use base ('new_histogram');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::plot::Chromosomes_plot::chromosomal_histogram.pm

=head1 DESCRIPTION

A histogram, that creates the bins according to a distance in bp, not a mx steps approach.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class chromosomal_histogram.

=cut

sub new {

	my ( $class, $title ) = @_;

	my ($self);

	$self = {
		debug          => 0,
		title          => $title,
		root           => root->new(),
		logged         => 0,
		scale21        => 0,
		category_steps => 10,
		minAmount      => undef,
		maxAmount      => undef,
		scale21        => 0,
		noNull         => 0
	};

	bless $self, $class
	  if ( $class eq
		"stefans_libs::plot::Chromosomes_plot::chromosomal_histogram" );
	$self->minAmount(0);
	return $self;

}

=head2 initialize

If $self->Max and $self->Min are set, I can with a distance entry create a set of virtual boxes where you can add data to.

=cut

sub initialize {
	my ( $self, $distance ) = @_;
	if ( ref( $self->{'bins'} ) eq "ARRAY" ) {

		# OK - only reinitialize - no complete breakdown!
		$self->{'data'} = {};
		foreach ( @{ $self->{'bins'} } ) {
			$self->{'data'}->{ $_->{'category'} } = 0;
		}
		return $self->{'data'}, $self->{'bins'};

	}
	$distance = 1e+6 unless ( defined $distance );

#print "$self: we are (re)initializing the data structures with a distance of $distance\n";
	$self->{'data'} = $self->{bins} = undef;
	$self->{'data'} = {};
	$self->{'bins'} = [];
	for ( my $i = $self->Min() ; $i < $self->Max() ; $i += $distance ) {

#print "we create a bin between ".($i), " and ".($i + $distance)." (max = ".$self->Max()."\n";
		push(
			@{ $self->{'bins'} },
			{
				'category' => $i + $distance / 2,
				'max'      => $i + $distance,
				'min'      => $i
			}
		);
		$self->{'data'}->{ $i + $distance / 2 } = 0;
	}
	return $self->{'data'}, $self->{'bins'};
}

sub plot_axies {
	my ( $self, $portrait, $im, $color, $xTitle, $yTitle ) = @_;

#$self->{xaxis}->plot($im, $self->{yaxis}->resolveValue( $self->minAmount() ),$color, 'just for tests!');
	$im->line(
		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
		$self->{yaxis}->resolveValue( $self->minAmount() ),
		$self->{xaxis}->resolveValue( $self->{xaxis}->max_value() ),
		$self->{yaxis}->resolveValue( $self->minAmount() ),
		$color
	);

	$im->line(
		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
		$self->{yaxis}->resolveValue( $self->minAmount() ),
		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
		$self->{yaxis}->resolveValue( $self->maxAmount() ), $color

	);
}

sub get_as_bedGraph {
	my ( $self, $data_table ) = @_;
	unless ( ref($data_table) eq "stefans_libs_file_readers_bedGraph_file" ) {
		$data_table = stefans_libs_file_readers_bedGraph_file->new();
		foreach (qw(position value)) {
			$data_table->Add_2_Header($_);
		}
	}
	foreach my $hash ( sort { $a->{min} <=> $b->{min} } @{ $self->{'bins'} } ) {
		$data_table->simple_add(
			{
				'chromosome' => "chr$self->{'title'}",
				'start' => $hash->{min},
				'end' => $hash->{max},
				'value'    => $self->{data}->{ $hash->{category} }
			}
		) if ( $self->{data}->{ $hash->{category} } > 0);
	}
	return $data_table;
}

1;
