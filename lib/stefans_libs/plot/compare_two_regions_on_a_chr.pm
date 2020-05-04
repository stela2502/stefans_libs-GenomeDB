package stefans_libs::plot::compare_two_regions_on_a_chr;

#  Copyright (C) 2012-12-10 Stefan Lang

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
use stefans_libs::plot::fixed_values_axis;
use GD::SVG;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use stefans_libs::plot::figure;

use base ('figure');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_plot_compare_two_regions_on_a_chr

=head1 DESCRIPTION

This lib is a figure that displays a genomic region and shows two regions datasets and the genome genes in the middle.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_plot_compare_two_regions_on_a_chr.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		im    => undef,
		color => undef,
		font  => undef,
	};

	bless $self, $class
	  if ( $class eq "stefans_libs::plot::compare_two_regions_on_a_chr" );

	return $self;

}

=head2 plot ( {
	'outfile' => '',
	'upper' => {
		'name' => 'upper dataset',
		'object' => bedFileA,
 	},
 	'center' => {
 		'name' => 'genes',
 		'object' => bedFileB,
 	},
 	'lower' => {
 		'name' => 'lower dataset',
 		'object' => bedFileC,
 	},
});

=cut

sub plot_2_image {
	my ( $self, $hash ) = @_;
	Carp::confess(
		    ref($self)
		  . "->plot("
		  . root->print_perl_var_def($hash)
		  . ")\nErrors:\n$self->{'error'}" )
	  unless ( $self->_check_plot_hash($hash) );

	###############################################################
	### CONFIGURE PLOT START
	my $upper_color  = 'green';
	my $center_color = 'black';
	my $lower_color  = 'red';
	### CONFIGURE_PLOT END
	###############################################################
	### create the figure
	$hash->{im} =
	  $self->_createPicture( { 'x_res' => 1200, 'y_res' => 800 } );
	### create the coordinates
	$self->{'yaxis'} = fixed_values_axis->new( 'y', 150, 450, '', 'gbfeature' );
	$self->{'xaxis'} = fixed_values_axis->new( 'x', 150, 1150, '', 'gbfeature' );
	
	$self->_createAxies(
		{ 'x_min' => 150, 'x_max' => 1150, 'y_min' => 150, 'y_max' => 450 } );
	$self->{'yaxis'}->min_value(0);
	$self->{'yaxis'}->max_value(7);
	if ( defined $hash->{'start'} ) {
		$self->{'xaxis'}->min_value( $hash->{'start'} );
	}
	else {
		## somehow get the start values from all bed files!
		$self->{'xaxis'}->min_value( $self->min_data_start($hash) );
	}
	if ( defined $hash->{'end'} ) {
		$self->{'xaxis'}->max_value( $hash->{'end'} );
	}
	else {
		## somehow get the start values from all bed files!
		$self->{'xaxis'}->max_value( $self->max_data_end($hash) );
	}
	$self->{'xaxis'}->Bp_Scale(1);
	$self->{'xaxis'}->resolveValue( $self->{'xaxis'}->min_value() );    ##init!
	$self->{'yaxis'}->resolveValue(0);                                  ##init!
	### DONE create the coordinates
	##################################################################
	### plot the x axis
	$self->{'xaxis'}->plot(
		$hash->{'im'},               $self->{'yaxis'}->resolveValue(0),
		$self->{'color'}->{'black'}, "$hash->{'chr'} genomic orientation" ,3
	);
	
	$hash->{im}->rectangle(
		$self->{'xaxis'}->resolveValue( $self->{'xaxis'}->min_value() ),
		$self->{'yaxis'}->resolveValue(0),
		$self->{'xaxis'}->resolveValue( $self->{'xaxis'}->max_value() ),
		$self->{'yaxis'}->resolveValue(7),
		$self->{'color'}->{'black'},
	);

	## Now I have all axies defined and 'just' need to plot the data
	$hash->{'upper'}->{'object'}->{'plot_frame'} = 0;
	$hash->{'lower'}->{'object'}->{'plot_frame'} = 0;
	$hash->{'upper'}->{'object'}->plot_2_image(
		{
			'xaxis'      => $self->{'xaxis'},
			'y_min'      => $self->{'yaxis'}->resolveValue(4),
			'y_max'      => $self->{'yaxis'}->resolveValue(6),
			'chromosome' => $hash->{'chr'},
			'im'         => $hash->{'im'},
			'color_obj'  => $self->{'color'},
			'color'      => $upper_color
		}
	);
	$hash->{'lower'}->{'object'}->plot_2_image(
		{
			'xaxis'      => $self->{'xaxis'},
			'y_min'      => $self->{'yaxis'}->resolveValue(1),
			'y_max'      => $self->{'yaxis'}->resolveValue(3),
			'chromosome' => $hash->{'chr'},
			'im'         => $hash->{'im'},
			'color_obj'  => $self->{'color'},
			'color'      => $lower_color
		}
	);
	$hash->{'center'}->{'object'}->plot_2_image(
		{
			'xaxis'      => $self->{'xaxis'},
			'y_min'      => $self->{'yaxis'}->resolveValue(3),
			'y_max'      => $self->{'yaxis'}->resolveValue(4),
			'chromosome' => $hash->{'chr'},
			'im'         => $hash->{'im'},
			'color_obj'  => $self->{'color'},
			'color'      => $center_color
		}
	);
	## Now I need the legend
	$self->{font}->plotStringCenteredAtY_rightLineEnd(
		$hash->{'im'},
		$hash->{'upper'}->{'name'},
		$self->{'xaxis'}->resolveValue( $self->{'xaxis'}->min_value() ),
		$self->{'yaxis'}->resolveValue(5), $self->{'color'}->{'black'}, 'gbfeature', 0
	);
	$self->{font}->plotStringCenteredAtY_rightLineEnd(
		$hash->{'im'},
		$hash->{'lower'}->{'name'},
		$self->{'xaxis'}->resolveValue( $self->{'xaxis'}->min_value() ),
		$self->{'yaxis'}->resolveValue(2), $self->{'color'}->{'black'}, 'gbfeature', 0
	);
	$self->{font}->plotStringCenteredAtY_rightLineEnd(
		$hash->{'im'},
		$hash->{'center'}->{'name'},
		$self->{'xaxis'}->resolveValue( $self->{'xaxis'}->min_value() ),
		$self->{'yaxis'}->resolveValue(3.5), $self->{'color'}->{'black'}, 'gbfeature', 0
	);
	
}

sub min_data_start {
	my ( $self, $hash ) = @_;
}

sub max_data_end {
	my ( $self, $hash ) = @_;
}

sub _check_plot_hash {
	my ( $self, $hash ) = @_;
	$self->{'error'} = '';
	foreach ( 'outfile', 'chr' ) {
		$self->{'error'} .= "Missing the '$_' hash entry\n"
		  unless ( defined $hash->{$_} );
	}

	foreach ( 'upper', 'center', 'lower' ) {
		unless ( ref( $hash->{$_} ) eq "HASH" ) {
			$self->{'error'} .=
			    "Missing the '$_' hash entry\n"
			  . "Missing the '$_' -> 'name' hash entry\n"
			  . "Missing the '$_' -> 'object' hash entry\n";
			next;
		}
		$self->{'error'} .= "Missing the '$_' -> 'name' hash entry\n"
		  unless ( $hash->{$_}->{'name'} );
		$self->{'error'} .=
"Missing or not a 'stefans_libs::file_readers::bed_file' : '$_' -> 'object' hash entry\n"
		  unless (
			ref( $hash->{$_}->{'object'} ) eq
			"stefans_libs::file_readers::bed_file" );
	}
	return 1 unless ( $self->{'error'} =~ m/\w/ );
	return 0;
}

1;
