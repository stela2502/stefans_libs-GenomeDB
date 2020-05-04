package densityMap;

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

use stefans_libs::statistics::new_histogram;
#use stefans_libs::statistics::HMM::logHistogram;
use stefans_libs::array_analysis::correlatingData::SpearmanTest;
use stefans_libs::plot::axis;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use strict;
use warnings;

sub new {

	my ($class) = @_;

	my ($self);

	$self = { resolution => 100, debug => 0 };

	bless $self, $class if ( $class eq "densityMap" );

	return $self;

}

sub quantilCutoff {
	my ( $self, $quantile ) = @_;

  #$quantile = int($quantile);
  #print "densityMap: we try to get the cutoff value for quantile $quantile \n";
	my $data = $self->{values};
	my $rank = int( ( $quantile / 100 ) * ( @$data - 1 ) );

	#print "We get the rank $rank and the cutoffValue @$data[$rank]\n";
	return @$data[$rank];
}

sub createRegions_basedOnQuantile {
	my ( $self, $blocks ) = @_;
	my ( $max, $min, $steps, @regions, $lastEnd );
	die "you have to tell me how many blocks I should create! (not $blocks)"
	  unless ($blocks);

	$steps = 100 / $blocks;
	for ( my $i = 0 ; $i < 100 ; $i += $steps ) {
		$lastEnd = 1 unless ( defined $lastEnd );
		my $hash =
		  { min => $lastEnd, max => $self->quantilCutoff( $i + $steps ) };
		if ( $hash->{min} >= $hash->{max} ) {
			$hash->{max} = $hash->{min} + 1;
		}
		push( @regions, $hash );
		$lastEnd = $hash->{max};
	}
	$self->{bins} = \@regions;
}

sub get_relPosition {
	my ( $self, $value ) = @_;

	unless ( defined $self->{bins} ) {
		die
"$self get_relPosition -> you first have to create the bins using createRegions_basesOnQuantile!\n";
	}
	return 0 if ( $value == $self->Min );
	my $categoryList = $self->{bins};
	die "$self->getCategoryOfTi no histo definition!\n"
	  unless ( defined @$categoryList );

	for ( my $i = 0 ; $i < @$categoryList ; $i++ ) {
		return $i
		  if ( $value > @$categoryList[$i]->{min}
			&& $value <= @$categoryList[$i]->{max} );
	}
	root::print_hashEntries( $self->{bins}, 2 );
	die
"Value $value is not in the range of $self->{min} to $self->{max} and can therefore not be evaluated!\n";
}

sub plot_2_image {
	my (
		$self, $im, $x1,     $y1,     $x2, $y2,
		$x3,   $y3, $xTitle, $yTitle, $titleArray
	  )
	  = @_;

	my ( $color, @colorMap, $temp, $matrix, @x_region, @y_region, $line );
	$self->initAxies( $x1, $y1, $x2, $y2 );
	$color    = $self->Color();
	@colorMap = $color->getDensityMapColorArray();

	print "we have a min value of ", $self->Min, "\n";
	$temp = @colorMap;

	$self->_plotAxies( $self->{im}, $color->{black}, $xTitle, $yTitle );

	$self->createRegions_basedOnQuantile($temp);
	$matrix = $self->DataMatrix();

	for ( my $x = 0 ; $x < @$matrix ; $x++ ) {
		@x_region = ();
		@x_region = $self->{x_hist}->getStart_End_4_DatBinID($x);
		$line     = @$matrix[$x];
		for ( my $y = 0 ; $y < @$line ; $y++ ) {
			next if ( @$line[$y] == 0 );
			@y_region = ();
			@y_region = $self->{y_hist}->getStart_End_4_DatBinID($y);

			#print "we try to get_relPosition( @$line[$y] )  and get ",
			#  $self->get_relPosition( @$line[$y] ), "\n";
			#print "the id is used to get the color ",
			#  $colorMap[ $self->get_relPosition( @$line[$y] ) ], "\n";
			$im->filledRectangle(
				$self->{xaxis}->resolveValue( $x_region[0] ),
				$self->{yaxis}->resolveValue( $y_region[0] ),
				$self->{xaxis}->resolveValue( $x_region[1] ),
				$self->{yaxis}->resolveValue( $y_region[1] ),
				$colorMap[ $self->get_relPosition( @$line[$y] ) ]
			);
		}
	}
	## print the legend in the rectangle ( x1/y2;x3/y3))!
	my $bins = $self->{bins};

	my ( $start, $end );
	for ( my $i = 0 ; $i < @$bins ; $i++ ) {
		$im->filledRectangle(
			int( $x2 + 15 ),
			int( $y3 + 15 * ( $i + 2 ) ),
			int( $x2 + 30 ),
			int( $y3 + 15 * ( $i + 3 ) ),
			$colorMap[$i]
		);
		$start = int( @$bins[$i]->{min} );
		$end   = int( @$bins[$i]->{max} );
		$self->{font}->plotString(
			$im,
			"n = $start to $end",
			int( $x2 + 40 ),
			int( $y3 + 15 * ( $i + 2 ) ),
			$color->{black}, "", "tiny"
		);
	}
	my @temp;
	$temp = $self->{statistics};
	print "We try to plot the statistic result @$temp\n";
	for ( my $i = 0 ; $i < @$temp ; $i++ ) {
		@temp = split( "\t", @$temp[$i] );

		print "we plot the string '$temp[0]  $temp[2]' ", "at position x=",
		  $x2 + 15, " and y=", int( $y3 + 17 * ( @$bins + 4 + $i ) ),
		  " with color $color->{black}\n";

		$self->{font}->plotString(
			$im,
			"$temp[0]       $temp[2]",
			int( $x2 + 15 ),
			int( $y3 + 17 * ( @$bins + 2 + $i ) ),
			$color->{black}, "", "small"
		);
	}
	if ( defined @$titleArray ) {
		$self->{font}->plotString(
			$im,
			join( " ", @$titleArray ),
			int( $x1 + 10 ),
			int( $y3 + 8 ),
			$color->{black}, "", "small"
		);
	}
	return 1;

	#getStart_End_4_DatBinID
}

sub _plotAxies {
	my ( $self, $im, $color, $xTitle, $yTitle ) = @_;
	die "you have to define the axies first!\n"
	  unless ( defined $self->{xaxis} );
	$self->{xaxis}
	  ->plot( $im, $self->{yaxis}->resolveValue( $self->{yaxis}->min_value ),
		$color, $xTitle );
	$self->{yaxis}
	  ->plot( $im, $self->{xaxis}->resolveValue( $self->{xaxis}->min_value ),
		$color, $yTitle );
	return 1;
}

sub initAxies {
	my ( $self, $x1, $y1, $x2, $y2 ) = @_;

	$self->{xaxis} = axis->new( "x", $x1, $x2, "", "med" );
	$self->{yaxis} = axis->new( "y", $y1, $y2, "", "med" );
	$self->{xaxis}->min_value( $self->{x_hist}->Min() );
	$self->{xaxis}->max_value( $self->{x_hist}->Max() );
	$self->{yaxis}->min_value( $self->{y_hist}->Min() );
	$self->{yaxis}->max_value( $self->{y_hist}->Max() );
	$self->{yaxis}->resolveValue(0);
	$self->{xaxis}->resolveValue(0);
	print "initAxis in package ", ref($self), "\nxaxis min value =",
	  $self->{xaxis}->min_value, "; max value =", $self->{xaxis}->max_value,
	  "\n", "x coordinate for min value =",
	  $self->{xaxis}->resolveValue( $self->{xaxis}->min_value ), "; max value=",
	  $self->{xaxis}->resolveValue( $self->{xaxis}->max_value ), "\n",
	  "yaxis min value =", $self->{yaxis}->min_value, "; may value =",
	  $self->{yaxis}->max_value, "\n", "y coordinate for min value =",
	  $self->{yaxis}->resolveValue( $self->{yaxis}->min_value ), "; may value=",
	  $self->{yaxis}->resolveValue( $self->{yaxis}->max_value ), "\n"
	  if ( $self->{debug} );

	return 1;
}

sub getXaxis {
	my ($self) = @_;
	return $self->{xaxis};
}

sub getYaxis {
	my ($self) = @_;
	return $self->{yaxis};
}

sub plot {
	my ( $self, $filename, $xres, $yres, $xTitle, $yTitle, $titleArray ) = @_;

	$xres = $yres = 800 unless ( defined $xres );
	$xres = $yres unless ( $xres == $yres );

	my (
		$dataBins, $x_array, $y_array,   $im,     $xyGraph,
		$x_histo,  $yHisto,  $locations, @xrange, @yrange
	);

	$self->createPicture( $xres, $yres );

	print "we got a picture of the size $self->{x}x$self->{y}? ($self->{im})\n";

	$locations->{XY_y_max} = $self->{y} * 0.90;
	$locations->{XY_y_min} = $self->{y} * 0.30;
	$locations->{XY_x_max} = $self->{x} * 0.70;
	$locations->{XY_x_min} = $self->{x} * 0.10;

	$locations->{xHist_x_min} = $locations->{XY_x_min};
	$locations->{xHist_x_max} = $locations->{XY_x_max};
	$locations->{xHist_y_min} = $self->{y} * 0.05;
	$locations->{xHist_y_max} = $locations->{XY_y_min};

	$locations->{yHist_x_min} = $locations->{XY_x_max};
	$locations->{yHist_x_max} = $self->{x} * 0.90;
	$locations->{yHist_y_min} = $locations->{XY_y_min};
	$locations->{yHist_y_max} = $locations->{XY_y_max};

	#print "We create a simpleXYgraph object!\n";
	## here we have to plot us!

	$self->plot_2_image(
		$self->{im},            $locations->{XY_x_min},
		$locations->{XY_y_min}, $locations->{XY_x_max},
		$locations->{XY_y_max}, $locations->{xHist_y_min},
		0,                      $xTitle,
		$yTitle,                $titleArray
	);

	$self->{x_hist}->plot_2_image(
		$self->{im},               $locations->{xHist_x_min},
		$locations->{xHist_y_min}, $locations->{xHist_x_max},
		$locations->{xHist_y_max}, $self->{color}->{black},
		$self->{color}->{grey},    "",
		"",                        0,
		$self->getXaxis,           "X"
	);

	print "#1 is OK\n";

	$self->{y_hist}->plot_2_image(
		$self->{im},               $locations->{yHist_x_min},
		$locations->{yHist_y_min}, $locations->{yHist_x_max},
		$locations->{yHist_y_max}, $self->{color}->{black},
		$self->{color}->{grey},    "",
		"",                        1,
		$self->getYaxis,           "Y",
		$titleArray
	);
	print "#2 is OK\n";
	$self->writePicture($filename);
	return 1;
}

sub createPicture {
	my ( $self, $x, $y ) = @_;
	my $size;
	return $self->{im} if ( defined $self->{im} );
	$x = 800 unless ( defined $x );
	$y = 800 unless ( defined $y );
	$size = "large" if ( $x * $y >= 600000 );
	$size = "small" if ( $x * $y < 600000 );
	$size = "tiny"  if ( $x * $y < 120000 );
	$self->{x} = $x;
	$self->{y} = $y;

	#print "simpleXYgraph creates a picture ($x:$y)\n";
	$self->{im} = new GD::SVG::Image( $x, $y );
	$self->Color( color->new( $self->{im} ) );
	$self->{font} = Font->new("min");
	return $self->{im};
}

sub Color {
	my ( $self, $color ) = @_;
	$self->{color} = $color if ( ref($color) eq "color" );
	return $self->{color};
}

sub writePicture {
	my ( $self, $pictureFileName ) = @_;

	# Das Bild speichern
	print "bild unter $pictureFileName speichern:\n";
	my ( @temp, $path );
	@temp = split( "/", $pictureFileName );
	pop @temp;
	$path = join( "/", @temp );

	#print "We print to path $path\n";
	mkdir($path) unless ( -d $path );
	$pictureFileName = "$pictureFileName.svg"
	  unless ( $pictureFileName =~ m/\.svg$/ );
	open( PICTURE, ">$pictureFileName" )
	  or die "Cannot open file $pictureFileName for writing\n$!\n";

	binmode PICTURE;

	print PICTURE $self->{im}->svg()
	  or die "we could not save the picture!\n";
	close PICTURE;
	die "UPS! the picture file is not existant!\n"
	  unless ( -f $pictureFileName );
	print "Bild als $pictureFileName gespeichert\n";
	$self->{im} = undef;
	return 1;
}

sub Max {
	my ( $self, $max ) = @_;
	if ( defined $max ) {
		$self->{max} = -10E+30 unless ( defined $self->{max} );
		$self->{max} = $max if ( $max > $self->{max} );
	}
	return $self->{max};
}

sub Min {
	my ( $self, $min ) = @_;
	$self->{min} = 10E+30 unless ( defined $self->{min} );
	if ( defined $min ) {
		$self->{min} = $min if ( $min < $self->{min} );
	}
	return $self->{min};
}

sub AddData {
	my ( $self, $dataArray ) = @_;
	die "$self AddDat absolutely needs an data array of at least 2 entries\n"
	  unless ( defined $dataArray && @$dataArray > 1 );

	my ( $x_array, $y_array, @xrange, @yrange, $matrix, $x, $y, @resultsArray,
		@spearmanResults );
	$x_array = @$dataArray[0];
	$y_array = @$dataArray[1];
	die "error: not the same amount of x and y values"
	  unless ( @$x_array == @$y_array );

	$self->{x_hist} = new_histogram->new();
	$self->{y_hist} = new_histogram->new();
	$matrix = $self->DataMatrix( $self->{resolution}, $self->{resolution} );
	$self->{x_hist}->CreateHistogram( $x_array, undef, $self->{resolution} );
	$self->{y_hist}->CreateHistogram( $y_array, undef, $self->{resolution} );

	## we also want to include a linear correlation in the plot!
	my $spearmanTest = SpearmanTest->new();
	@spearmanResults = (
		$spearmanTest->_calculate_spearmanWeightFit_statistics(),
		$spearmanTest->_calculate_spearmanWeightFit_statistics(
			$x_array, $y_array
		)
	);
	$spearmanTest = undef;

	#print "we got the spearman results @spearmanResults\n";
	$self->{statistics} = \@spearmanResults;

	for ( my $i = 0 ; $i < @$x_array ; $i++ ) {
		$x = $self->{x_hist}->get_relPosition( @$x_array[$i] );
		$y = $self->{y_hist}->get_relPosition( @$y_array[$i] );
		unless ( defined @$matrix[$x] ) {
			warn
"we have a serious problem here -> eitehr the x value @$x_array[$i] \n",
"or the y value @$y_array[$i] was not initializesin the matrix!\n";
			next;
		}
		@$matrix[$x]->[$y]++;

		$self->Max( @$matrix[$x]->[$y] );
		$self->Min( @$matrix[$x]->[$y] );
	}
	foreach my $line (@$matrix) {
		foreach my $cell (@$line) {
			push( @resultsArray, $cell ) unless ( $cell == 0 );
		}
	}
	@resultsArray = ( sort { $a <=> $b } @resultsArray );
	$self->{values} = \@resultsArray;
	return 1;
}

sub DataMatrix {
	my ( $self, $x, $y ) = @_;

	return $self->{matrix} if ( defined $self->{matrix} );
	my @matrix;
	for ( my $i = 0 ; $i < $x ; $i++ ) {
		my @temp;
		$matrix[$i] = \@temp;
		for ( my $a = 0 ; $a < $y ; $a++ ) {
			$temp[$a] = 0;
		}
	}
	$self->{matrix} = \@matrix;
	return $self->{matrix};
}

1;
