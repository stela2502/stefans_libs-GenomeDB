package plottable_gbFile;
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
use stefans_libs::plot::multiline_gb_Axis;
use stefans_libs::gbFile;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

This package is a wrapper arounf a gbFile object and the multiline_gb_Axis. 
It can be used to plot a gbFile with a plot and plot_2_image function.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class plottable_gbFile.

=cut

sub new{

	my ( $class, $gbFile, $debug ) = @_;

	my ( $self );
	
	if ( defined $gbFile ){
		## the gbFile can either be a gbFile object or a a path to a gbFile
		if ( ref($gbFile) eq "gbFile"){
			## wow - we got a gbFile!!
		}
		elsif ( -f $gbFile ){
			## it could be a genbank file
			my $gbFile_obj = gbFile->new( $gbFile );
			$gbFile = $gbFile_obj if ( defined $gbFile_obj->{seq});
		}
	}

	$self = {
		debug => $debug
  	};

  	bless $self, $class  if ( $class eq "plottable_gbFile" );

  	return $self;

}


sub plot{
	my ( $self, $hash) = @_;
	die ref($self)."function plot is not implemented - use plot_2_image to plot a gbFile!\n";
	
}


sub _check_plot_2_image_hash {
	my ( $self, $hash ) = @_; 
	$self->{'error'} = $self->{'warning'} = '';
	$self->{'error'} .=  ref($self)." we need an image to plot to" unless ( defined $hash->{im} || defined $self->{im} );
	
	$self->{'error'} .= ref($self)."no data to plot (data)!\n" unless ( ref ($hash->{data}) eq "gbFile" || defined $self->{gbFile});
	$self->{'error'} .=  ref($self).":plot_2_image - no possibillity to create a x_axis ('x_min' = $hash->{x_min}; 'x_max' = $hash->{x_max})!"
		unless ( (defined ($hash->{x_min}) && defined ( $hash->{x_max})) );
	$self->{'error'} .=  ref($self).":plot_2_image - no possibillity to create a y_axis ('y_min' = $hash->{y_min}; 'y_max' = $hash->{y_max})!"
		unless ( (defined ($hash->{y_min}) && defined ( $hash->{y_max})) );
	$self->{y_min} = $hash->{y_min};
	$self->{y_max} = $hash->{y_max};
	
	$self->{'error'} .=  ref($self).":plot_2_image - we need an color object!\n" unless ( defined $hash->{color} || defined $self->{color} );
	$self->{'error'} .=  ref($self).":plot_2_image - we need an external font object" unless ( defined $hash->{font} || defined $self->{font});
	$self->{'warning'} .= ref($self)."plot_2_image - we have no start position on the gbFile - we will asume 0 ;-)\n" unless ( defined $hash->{start});
	$self->{'warning'} .= ref($self)."plot_2_image - we have no end position on the gbFile - we will asume the end of the gbFile ;-)\n" unless ( defined $hash->{end});
	return 0 if ( $self->{error} =~ m/\w/);
	return 1;
}

sub plot_2_image{
	my ( $self, $hash) = @_;
	die $self->{error} unless ( $self->_check_plot_2_image_hash ( $hash) );
	
	$self->{gbFile} = $hash->{data} if ( ref($hash->{data}) eq "gbFile" );
	
	$self->{color} = $hash->{color} if ( defined $hash->{color});
	$self->{font} = $hash->{font} if ( defined $hash->{font});
		
	$self->{x_axis} = multiline_gb_Axis->new($self->{gbFile}, $hash->{start}, $hash->{end}, $hash->{x_min}, $hash->{y_min}, $hash->{x_max}, $hash->{y_max}, $self->{font}->{resolution},
		$self->{color});
	$self->{x_axis}->plot( $hash->{im}, $hash->{font});
	return 1;
	
}


sub resolveValue{
	my ( $self, $value ) = @_;
	die ref($self).":resolveValue -> you have to plot the gbFile first!\n" unless ( defined $self->{x_axis});
	return  $self->{x_axis} -> resolveValue ( $value );
	
}

sub addMark{
	my ( $self, $im, $position, $mark_y, $tag ) = @_;
	
	$im -> line ( $self->resolveValue ( $position), $self->{y_max},  $self->resolveValue ( $position), $self->{y_min}, $self->{color}->{red} );
	if ( $mark_y > $self->{y_max} ){
		$im ->line ($self->resolveValue ( $position) , $self->{y_max}, $self->resolveValue ( $position),  $mark_y,  $self->{color}->{red});
		$self->plotStar ( $im, $self->resolveValue ( $position), $mark_y);
	}
	elsif ( $mark_y > $self->{y_min} ) {
		$im ->line ($self->resolveValue ( $position) , $self->{y_min}, $self->resolveValue ( $position),  $mark_y,  $self->{color}->{red});
		$self->plotStar ( $im, $self->resolveValue ( $position), $mark_y);
	}
	else {
		$self->plotStar ( $im, $self->resolveValue ( $position), $mark_y);
	}
	$self->{font}->plotString ( $im , $tag, $self->resolveValue ( $position) +6, $mark_y, $self->{color}->{red}, 0, 'small' ) if ( defined $tag);
}

sub plotStar{
	my ( $self, $im, $x, $y ) = @_;
	
	for( my $x_val =  -5; $x_val <=  +5; $x_val += 2 ){
		for ( my $y_val = -5; $y_val <=  + 5 ;$y_val += 2){
			$im->line( $x + $x_val, $y + $y_val, $x - $x_val, $y - $y_val, $self->{color}->{red} );
		}
	}
}

1;
