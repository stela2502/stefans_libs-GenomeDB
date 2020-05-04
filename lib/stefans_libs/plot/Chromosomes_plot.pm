package Chromosomes_plot;

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
use stefans_libs::database::genomeDB;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::plot::Chromosomes_plot::chromosomal_histogram;
use stefans_libs::plot::figure;
use base ('figure');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::plot::Chromosomes_plot.pm

=head1 DESCRIPTION

A lib to plot a set of histigrams representing the chromosomes and some binary value.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class Chromosomes_plot.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) =~ m/::db$/ );

	my ($self);

	$self = {
		'dbh'   => $dbh,
		'debug' => $debug
	};

	bless $self, $class if ( $class eq "Chromosomes_plot" );

	return $self;

}

=head chromosomal_resolution

set the chromosomal resolution where you want to plot your data. Please keep in mind, that chromosomes can
be hundreds of mega bases long - so setting the resolution to something below a mega base might not give you a useful result!

=cut

sub chromosomal_resolution {
	my ( $self, $distance ) = @_;
	if ( defined $distance ) {
		return $self->{'distance'} if ( $distance < 1 );
		if ( $distance < 1e+5 ) {
			warn
"The distance ($distance bp) might be a little to smal to plot things on a chromosommal scale - don't you think?\n";
		}
		$self->{'distance'} = $distance;
	}
	unless ( defined $self->{'distance'} ) {
		$self->{'distance'} = 1e+6;
	}
	return $self->{'distance'};
}

sub __we_contain_data {
	my ($self) = @_;
	return 0
	  unless ( defined $self->_getDatasets() );    ## if we do not contain data
	return 1;                                      ## if we do contain data
}

=head2 create_chromosomes_for_organism

$self->create_chromosomes_for_organism( $organism_tag )

This funtion will get the length of the chromosomes from the most actual genomeDB version of the organism and creates the internal data structure.

=head2 _process_chromosomes_arrays

I need a set of [chromosomal name, chromosome length] array refs, that will be converted into the internal data structure.

=cut

sub _process_chromosomes_arrays {
	my ( $self, @arrays ) = @_;
	foreach (@arrays) {

		#print "we are OK\n";
		next if @$_[1] =~ m/\|/;

		#print "we are still OK (@$_[1])\n";
		next if defined $self->{'chromosomes'}->{ @$_[1] };
		$self->{'chromosomes'}->{ @$_[1] } =
		  chromosomal_histogram->new( @$_[1] );
		$self->{'chromosomes'}->{ @$_[1] }->Min(0);
		$self->{'chromosomes'}->{ @$_[1] }->Max( @$_[0] );
		$self->{'chromosomes'}->{ @$_[1] }
		  ->initialize( $self->chromosomal_resolution() );
		$self->{'chromosome_count'}++;
	}
	## and now create the plot help structure - first halve of chromosomes goes up
	my $i = 0;
	$self->{'plot_assistance'} = { 'upper' => [], 'lower' => [] };
	foreach my $chromosome_name (
		sort {
			$self->{'chromosomes'}->{$b}->Max <=> $self->{'chromosomes'}->{$a}
			  ->Max
		} keys %{ $self->{'chromosomes'} }
	  )
	{
		push(
			@{ $self->{'plot_assistance'}->{'upper'} },
			$self->{'chromosomes'}->{$chromosome_name}
		);

#		if ($i < $self->{'chromosome_count'} / 2 ){
#
#		}
#		else {
#			push ( @{$self->{'plot_assistance'}->{'lower'}}, $self->{'chromosomes'}->{$chromosome_name});
#		}
		$i++;
	}
	return 1;
}

sub plot {
	my ( $self, $hash ) = @_;
	my $im = $self->plot_2_image($hash);
	Carp::confess(
		"we had some problems with the plot has:\n" . $self->{'error'} )
	  if ( $self->{'error'} =~ m/\w/ );
	Carp::confess(
		ref($self)
		  . "::plot -> we do not know the outfile name - please specify that in the hash!"

	) unless ( defined $hash->{'outfile'} );
	
	$self->writePicture( $hash->{'outfile'} );
	return 1;
}


sub create_chromosomes_for_organism {
	my ( $self, $organism_tag ) = @_;
	my ( $genome, $genomeInterface );
	$organism_tag |= 'H_sapiens';
	$genome = genomeDB->new();
	$genomeInterface =
	  $genome->GetDatabaseInterface_for_Organism($organism_tag);
	$genomeInterface = $genomeInterface->get_rooted_to('gbFilesTable');
	$self->{'chromosomes'} = {};
	$self->{'chromosome_count'} = 0;
	$genomeInterface->printReport( '', "error_description");
	return $self->_process_chromosomes_arrays(
		@{
			$genomeInterface->getArray_of_Array_for_search(
				{
					'search_columns' => [
						'chromosomesTable.chr_stop',
						'chromosomesTable.chromosome'
					],
					'where' => [],
					'order_by' => [
						'chromosomesTable.chromosome',
						[ 'my_value', '-', 'chromosomesTable.chr_stop' ]
					],
				}
			)
		  }
	);

}

=head Add_Data_4_chromosome

$self->Add_Data_4_chromosome($chromosome, \@data_values )
The chromosome name has to be valid in the organism you want to plot data for;
the data array has to contain ONLY the position of the data points you want to plot as a histogram. This module can only plot histograms!

=cut

sub Add_Data_4_chromosome {
	my ( $self, $chromosome, $data ) = @_;
	if (   ref($data) eq "ARRAY"
		&& ref( $self->{'chromosomes'}->{$chromosome} ) eq
		"chromosomal_histogram" )
	{
		$self->{'chromosomes'}->{$chromosome}->CreateHistogram($data);
		return 1;
	}
	return 0;
}


sub _createAxies {
	my ( $self, $hash ) = @_;
	my $error = '';
	my $max;
	unless ( defined $self->{yaxis} ) {
		if ( defined $hash->{yaxis} && ref( $hash->{yaxis} ) eq "axis" ) {
			$self->{yaxis} = $hash->{yaxis};
		}
		elsif ( defined $hash->{y_min} && defined $hash->{y_max} ) {
			$self->{yaxis} =
			  axis->new( "y", $hash->{y_min}, $hash->{y_max}, $self->Ytitle(),
				$self->{'font'}->{'resolution'} );
			$max = @{ $self->{'plot_assistance'}->{'upper'} }[0]->Max();
			if ( defined @{ $self->{'plot_assistance'}->{'lower'} }[0] ) {
				$max += @{ $self->{'plot_assistance'}->{'lower'} }[0]->Max();
				$max = 1.1 * $max;
			}
			$self->{yaxis}->max_value($max);
			$self->Y_Max($max);
			$self->{yaxis}->min_value(0);
			$self->{yaxis}->Bp_Scale(1);
		}
		else {
			$error .=
"Sorry, but we can not create the missing y_axis as we do not know the positions in the image 'y_min' aynd 'y_max'\n";
		}
	}
	unless ( defined $self->{xaxis} ) {
		if ( defined $hash->{xaxis} && ref( $hash->{xaxis} ) eq "axis" ) {
			$self->{xaxis} = $hash->{xaxis};
		}
		elsif ( defined $hash->{x_min} && defined $hash->{x_max} ) {
			$self->{xaxis} =
			  axis->new( "x", $hash->{x_min}, $hash->{x_max}, $self->Xtitle(),
				$self->{'font'}->{'resolution'} );
			$self->{xaxis}->min_value(0);
			if ( defined $self->{'chromosome_count'} ) {
				$self->{xaxis}->max_value(
					scalar( @{ $self->{'plot_assistance'}->{'upper'} } ) );
				$self->{xaxis}->{'tics'} =
				  scalar( @{ $self->{'plot_assistance'}->{'upper'} } );
			}
			else {
				$error .=
"Sorry, but you need to create the internal datastructure first (use 'create_chromosomes_for_organism')";
			}

		}
		else {
			$error .=
"Sorry, but we can not create the missing x_axis as we do not know the positions in the image 'x_min' aynd 'x_max'\n";
		}
	}
	return $error if ( $error =~ m/\w/ );
	$self->{yaxis}->resolveValue(0);
	$self->{xaxis}->resolveValue(0);
	return $error;
}

sub plot_Data {
	my ( $self, $dataset, @colors ) = @_;
	## I will always plot black!
	my ( $x_axis, $max_x );
	$max_x = 0;
	foreach ( @{ $dataset->{'upper'} } ) {
		$max_x = $_->maxAmount() if ( $_->maxAmount() > $max_x );
	}
	$self->Y_axis()->{'tics'} = 10;
	$self->Y_axis()->min_value(0);
	$self->Y_axis()->resolveValue(0);
	$self->Y_axis()->Bp_Scale(1);
	for ( my $i = 0 ; $i < @{ $dataset->{'upper'} } ; $i++ ) {
		$x_axis = axis->new(
			'x',
			$self->X_axis()->resolveValue( $i + 0.1 ),
			$self->X_axis()->resolveValue( $i + 0.9 ),
			'', 'min'
		);
		$x_axis->min_value(0);
		$x_axis->max_value($max_x);
		@{ $dataset->{'upper'} }[$i]->minAmount(0);
		@{ $dataset->{'upper'} }[$i]->maxAmount($max_x);

		#@{ $dataset->{'upper'} }[$i]->X_axis($x_axis );
		@{ $dataset->{'upper'} }[$i]->plot_2_image(
			{
				'im'     => $self->{'im'},
				'x_axis' => $x_axis,

			 #				'x_min'         => $self->X_axis()->resolveValue( $i + 0.1 ),
			 #				'x_max'         => $self->X_axis()->resolveValue( $i + 0.9 ),
			 #				'y_min'         =>  $self->X_axis()->resolveValue( $i + 0.1 ),
			 #				'y_max'         => $self->X_axis()->resolveValue( $i + 0.9 ),
				'y_axis'    => $self->Y_axis(),
				'portrait'  => 1,
				'color'     => $self->{'color'}->{'black'},
				'fillColor' => $self->{'color'}->{'blue'}
			}
		);
		$self->{'font'}->plotStringCenteredAtXY(
			$self->{'im'},
			@{ $dataset->{'upper'} }[$i]->{'title'},
			$self->X_axis()->resolveValue( $i + 0.5 ),
			$self->Y_axis()->resolveValue(0) + 15,
			$self->{'color'}->{'black'},
			'gbfeature',
			0
		);
		$self->{'im'}->line(
			$self->X_axis()->resolveValue( $i + 0.1 ),
			$self->Y_axis()->resolveValue(0),
			$self->X_axis()->resolveValue( $i + 0.1 ),
			$self->Y_axis()->resolveValue( @{ $dataset->{'upper'} }[$i]->Max ),
			$self->{'color'}->{'green'}
		);
	}
	$self->Y_Max();
}

sub _plot_axies {
	my ($self) = @_;
	## all the values should have been initialized using the _check_plot_2_image_hash
	## therefore I expect you to call that function inside of the plot_2_image function
	$self->Xtitle('Chr. name') unless ( defined $self->Xtitle() );
	$self->{xaxis}->plot_without_digits(
		$self->_createPicture(),
		$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
		$self->{color}->{black},
		$self->Xtitle(), 2
	);

	$self->Ytitle('Chr. position') unless ( defined $self->Ytitle() );
	$self->{yaxis}->plot(
		$self->_createPicture(),
		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
		$self->{color}->{black},
		$self->Ytitle()
	);

#$self->{'font'}->plotString( $self->_createPicture(), $self->Title(),
#	$self->X_axis( $self->X_axis->min_value() ) , 15, $self->{color}->{black}, 0 , 'Title' );
}

sub Title {
	my ( $self, $title ) = @_;
	$self->{'title'} = '' unless ( defined $self->{'title'} );
	$self->{'title'} .= "$title " if ( defined $title );
	return $self->{'title'};
}

sub _getDatasets {
	my ($self) = @_;
	return { 'data' => $self->{'plot_assistance'} };
}
1;
