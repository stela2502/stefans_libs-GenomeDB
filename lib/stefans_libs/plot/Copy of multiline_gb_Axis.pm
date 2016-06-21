package stefans_libs::plot::multiline_gb_Axis;
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

use stefans_libs::plot::multi_axis;
use GD;

#@ISA = qw(multi_axis);

use strict;

sub new {

	my ( $class, $gbFile, $start, $end, $x1, $y1, $x2, $y2, $resolution,
		$color ) = @_;

	my ( $self, $axis_title );

	#root::identifyCaller($class) unless ( defined $x1);
	my $error = '';
	$error .= "I need a gbFile object at stefans_libs::plot::multi_axis->new()\n" unless ( ref($gbFile) eq "gbFile" ) ;
	$error .= "I need a start in bp at stefans_libs::plot::multi_axis->new()\n" unless ( $start > 0 ) ;
	$error .= "I need a end in bp at stefans_libs::plot::multi_axis->new()\n" unless ( $end > 0 ) ;
	$error .= "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n" unless ( defined $x1 ) ;
	$error .= "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n" unless ( defined $x2 ) ;
	$error .= "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n" unless ( defined $y1 ) ;
	$error .= "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n" unless ( defined $y2 ) ;
	$error .= "I need a resolution at stefans_libs::plot::multi_axis->new()\n" unless ( defined  $resolution) ;
	$error .= "I need a color object at stefans_libs::plot::multi_axis->new()\n" unless ( ref($color) eq "color" ) ;
	Carp::confess ( $error ) if ( $error =~m/\w/);
	
	$self = {
		usePrimer_Tag                         => 1 == 0,
		color                                 => $color,
		gbFile                                => $gbFile,
		tics                                  => 6,
		usedRegions                           => [],
		max_pixel                             => $x2,
		min_pixel                             => $x1,
		y1                                    => $y1,
		y2                                    => $y2,
		space_between_the_transciption_arrows => 10,
		axis_title                            => $axis_title,
		resolution                            => $resolution
	};
	$self->{x_axis} =
	  multi_axis->new( "x", $x1, $x2, $axis_title, $resolution );
	$self->{x_axis}->Bp_Scale(1);

	if ( $resolution eq "max" ) {

		#        $self->{tics}       = 10;
		$self->{tic_length} = 20;
		$self->{font}       = Font->new($resolution);
	}
	if ( $resolution eq "med" ) {

		#       $self->{tics}       = 8;
		$self->{tic_length} = 13;
		$self->{font}       = Font->new($resolution);
	}
	if ( $resolution eq "min" ) {

		#       $self->{tics}       = 6;
		$self->{tic_length} = 7;
		$self->{font}       = Font->new($resolution);
	}
	unless ( defined $self->{font} ) {
		## "max is default"
		$self->{tic_length} = 20;
		$self->{font}       = Font->new($resolution);
	}

	bless $self, $class if ( $class eq "stefans_libs::plot::multiline_gb_Axis" );

	$self->min_value($start) if ( defined $start );
	$self->max_value($end)   if ( defined $end );

	return $self;

}

sub resetAxis {
	my ($self) = @_;
	return $self->{x_axis}->resetAxis();
}

sub defineSubAxis {
	my ( $self, $start, $end, $percentage ) = @_;
	return $self->{x_axis}->AddSubRegion( $start, $end, $percentage );
}

sub defineLocation {

	my ( $self, $gbFile, $start, $end, $x1, $y1, $x2, $y2, $resolution, $color )
	  = @_;

	my ($axis_title);

	$self->{color}     = $color;
	$self->{gbFile}    = $gbFile;
	$self->{max_pixel} = $x2;
	$self->{min_pixel} = $x1;
	$self->{y1}        = $y1;
	$self->{y2}        = $y2;
	$self->{x_axis} = multi_axis->new( "x", $x1, $x2, $axis_title, $resolution )
	  unless ( defined $self->{x_axis} );
	$self->{axis_title} = $axis_title;
	$self->{resolution} = $resolution;

	$self->{x_axis}->defineValues( $x1, $x2 );

	if ( $resolution eq "max" ) {

		#        $self->{tics}       = 10;
		$self->{tic_length} = 20;
		$self->{font}       = Font->new($resolution);
	}
	if ( $resolution eq "med" ) {

		#       $self->{tics}       = 8;
		$self->{tic_length} = 13;
		$self->{font}       = Font->new($resolution);
	}
	if ( $resolution eq "min" ) {

		#       $self->{tics}       = 6;
		$self->{tic_length} = 7;
		$self->{font}       = Font->new($resolution);
	}
	$self->{PixelForValue} = undef;
	$self->min_value($start);
	$self->max_value($end);
	$self->defineAxis();
	return $self;

}

sub min_value {
	my ( $self, @values ) = @_;
	unless ( defined $self->{x_axis} ) {
		root::identifyCaller( $self, "min_value" );
		return undef;
	}
	return $self->{x_axis}->min_value(@values);
}

sub max_value {
	my ( $self, @values ) = @_;
	unless ( defined $self->{x_axis} ) {
		root::identifyCaller( $self, "max_value" );
		return undef;
	}
	return $self->{x_axis}->max_value(@values);
}

sub createBrush {
	my ( $self, $color, $orientation ) = @_;
	$color = $self->{color}->{black} unless ( defined $color );
	my $arrow_brush = new GD::SVG::Image( 9, 9 );
	my $colorOb = color->new($arrow_brush);

	#$arrow_brush->transparent($colorOb->{white});
	$arrow_brush->line( 0, 4, 9, 4, $color );
	if ( $orientation eq "sense" ) {
		$arrow_brush->line( 4, 0, 8, 4, $color );
		$arrow_brush->line( 4, 8, 8, 4, $color );
	}
	if ( $orientation =~ m/anti/ ) {
		$arrow_brush->line( 0, 4, 4, 0, $color );
		$arrow_brush->line( 0, 4, 4, 8, $color );
	}
	open( B, ">brushTest$orientation.svg" );
	binmode B;
	print B $arrow_brush->png;
	close B;
	return $arrow_brush;
}

sub Dimension {
	my ($self) = @_;
	return $self->{x_axis}
	  ->getDimensionInt( $self->max_value() - $self->min_value() );
}

sub Start {
	my ( $self, $start ) = @_;
	return $self->{x_axis}->min_value($start);
}

sub End {
	my ( $self, $end ) = @_;
	return $self->{x_axis}->max_value($end);
}

sub GB_File {
	my ( $self, $gbFile ) = @_;
	$self->{gbFile} = $gbFile if ( defined $gbFile && $gbFile =~ m/gbFile/ );
	return $self->{gbFile};
}

sub Title {
	my ( $self, $title ) = @_;
	$self->{axis_title} = $title if ( defined $title );
	return $self->{axis_title};
}

sub IsIG_region {
	my ( $self, $tag ) = @_;
	my ( @usedRegions, $use, $temp );

	@usedRegions = (
		"enhancer",  "V_region",  "V_segment", "J_segment",
		"D_segment", "C_segment", "C_region",  "silencer"
	);

	#  push (@usedRegions,"primer_bind");

	$use = 0 == 1;
	foreach $temp (@usedRegions) {
		if ( $temp eq $tag ) {
			$use = 1 == 1;
			last;
		}
	}
	return $use;
}

sub Summary {
	my ( $self, $summary ) = @_;
	if ( defined $summary ) {
		$self->{summary} = $summary;
	}
	return $self->{summary};
}

sub showPrimer {
	my ( $self, $summary ) = @_;

#print "DEBUG $self ->showPrimer has $self->{usePrimer_Tag} and will set it to $summary\n";
	if ( defined $summary ) {
		$self->{usePrimer_Tag} = $summary;
	}

	#print "\tand this value is true\n" if ( $self->{usePrimer_Tag} );
	return $self->{usePrimer_Tag};
}

sub isPartOfGene {
	my ( $self, $tag ) = @_;

	my $use = 0;
	foreach my $temp ( "mRNA", "CDS", "exon", "gene" ) {
		if ( $temp =~ m/$tag/ ) {
			$use = 1;
			last;
		}
	}

	#   print "Use Region returnes $use!\n";
	return $use;
}

sub addGeneRegions {
	my ($self) = @_;
	my $localRegions = $self->{usedRegions};

	foreach my $region ( "mRNA", "CDS", "exon", "gene" ) {
		push( @$localRegions, $region ) unless ( $self->UseRegion($region) );
	}
	push( @$localRegions, "primer_bind" ) if ( $self->showPrimer() );

}

sub UsedRegions {
	my ( $self, @regions ) = @_;
	#print "DEBUG UsedRegions-> @regions\n";
	my $localRegions = $self->{usedRegions};
	if ( $regions[0] =~ m/ARRAY/ ) {
		my $temp = $regions[0];
		@regions = @$temp;
	}
	foreach my $region (@regions) {
		if ( $self->isPartOfGene($region) ) {
			$self->addGeneRegions();
			next;
		}
		push( @$localRegions, $region ) unless ( $self->UseRegion($region) );
	}
	unless ( defined @$localRegions[0] ) {
		$self->useDefaultRegions();
	}
	push( @$localRegions, "primer_bind" )
	  if ( $self->showPrimer() && !$self->UseRegion('primer_bind') );
	return @$localRegions;
}

sub useDefaultRegions {
	my ($self) = @_;
	my $usedRegions = $self->{usedRegions};
	@$usedRegions = (
		"enhancer",     "V_region",     "V_segment", "J_segment",
		"D_segment",    "mRNA",         "CDS",       "exon",
		"gene",         "C_segment",    "C_region",  "primer_bind",
		"misc_binding", "misc_feature", "silencer"
	);
	return 1;
}

sub Colored_V_segments {
	my ( $self, $bool ) = @_;

	#print "$self->Colored_V_segments got the boolean value $bool\n";
	$self->{colored_V_segments} = $bool if ( defined $bool );
	return $self->{color}->Colored_V_segments( $self->{colored_V_segments} );
}

sub highlight_Vsegment {
	my ( $self, $bool ) = @_;

	#print "$self->Colored_V_segments got the boolean value $bool\n";
	$self->{hi_V_seg} = $bool if ( defined $bool );
	return $self->{color}->highlight_Vsegment( $self->{hi_V_seg} );
}

sub UseRegion {
	my ( $self, $gbFeature ) = @_;
	my ( $usedRegions, $use, $tag, $temp );

	$usedRegions = $self->{usedRegions};

  #die "$self->UseRegion uses these regions:\n\t", join (" ",@usedRegions),"\n";

	$use = 0 == 1;
	$tag = $gbFeature;
	$tag = $gbFeature->Tag() if ( $gbFeature =~ m/gbFeature/ );
	foreach $temp (@$usedRegions) {
		if ( $tag =~ m/$temp/ ) {
			$use = 1 == 1;
			return $use;
		}
	}

	return $use unless ( $gbFeature =~ m/gbFeature/ );
	$tag = $gbFeature->Name();
	foreach $temp (@$usedRegions) {
		if ( $tag =~ m/$temp/ ) {
			$use = 1 == 1;
			return $use;
		}
	}
	$tag = $gbFeature->getAsGB();
	foreach $temp (@$usedRegions) {
		if ( $tag =~ m/$temp/ ) {
			$use = 1 == 1;
			return $use;
		}
	}

	return $use;
}

sub resolveValue {
	my ( $self, @values ) = @_;
	$self->defineAxis();
	return $self->{x_axis}->resolveValue(@values);
}

sub plot_simple_base_line {
	my ( $self, @values ) = @_;
	return $self->{x_axis}->plot_simple_base_line(@values);
}

sub plot {
	my ( $self, $im, $font ) = @_;

	$im->newGroup("multilineGB_AXIS_$self");
	if ( $self->Summary ) {
		$self->plot_simple( $im, $font );
	}
	else {
		$self->plot_complex( $im, $font );
	}
	$im->endGroup();
}

sub plot_simple {
	my ( $self, $im, $font ) = @_;
	my (
		$GBregions, $plotSite, $name, $color, $meanX,
		$start,     $end,      @temp, $locations
	);

	unless ( defined $self->{gbFile} ) {
		die
"simple_multiline_gb_Axis: this is a final blow! no gbFile in MultiLinePlot!\n";
		return -1;
	}

	$self->{color}->Colored_V_segments( $self->{colored_V_segments} );
	$self->{color}->highlight_Vsegment( $self->highlight_Vsegment() );

	$self->{x_axis}
	  ->plot( $im, $self->{y1}  , $self->{color}->{black}, $self->Title() );
	$self->{y1} += 25;
	$GBregions = $self->{gbFile}->Features();
	$self->{font} = $font if ( defined $font );
	$self->{act_y1} = $self->{_y1} =
	  $self->{y1} + ( $self->{y2} - $self->{y1} ) / 40;
	$self->{act_y2} = $self->{_y2} =
	  $self->{y1} + ( $self->{y2} - $self->{y1} ) * 19 / 40;
	$self->{down_y1} = $self->{y1} + ( $self->{y2} - $self->{y1} ) * 21 / 40;
	$self->{down_y2} = $self->{y1} + ( $self->{y2} - $self->{y1} ) * 39 / 40;
	$self->{_mean} =
	  $self->{act_y1} + ( $self->{act_y2} - $self->{act_y1} ) / 2;

	foreach my $region (@$GBregions) {

		next
		  if ( $region->Start() > $self->max_value()
			|| $region->End() < $self->min_value() );
		next unless ( $self->UseRegion($region) );

		$self->{mean}   = $self->{_mean};
		$self->{actLoc} = "sense";

	   #print "$self->plot_simple: we plot a gbFeature named ", $region->Name(),
	   #  "\n";
		if ( $self->IsIG_region( $region->Tag() ) ) {
			if ( $self->{useOnlyJ558} ) {
				next unless ( $region->Name() =~ m/J558/ );
			}

			( $name, $color ) = $self->{color}->color_and_Name($region);

#print
#"$self->plot_simple: we plot a Ig segment named $name with the color $color\n";
			unless ( defined $locations->{ $region->Tag() } ) {
				print "\n\nWe create a new location entry\n\n";
				$locations->{ $region->Tag() } = {
					start => $region->Start(),
					end   => $region->End(),
					color => $color
				};
			}
			else {
				$locations->{ $region->Tag() }->{end} = $region->End();
			}
			$meanX =
			  $self->drawLine( $im, $region->Start(), $region->End(), $color )
			  ;    #gdStyledBrushed );
			$self->drawBox( $im, $region, $color );
		}
		if ( $region->Tag() =~ m/mRNA/ || $region->Tag() eq "exon" ) {

			#print "Got a mRNA\n";
			next;
			$self->drawSmallBox( $im, $region );
		}
		if ( $region->Tag() eq "CDS" ) {

			#		    print "got a CDS!\n";
			$self->drawBox( $im, $region );
		}
		if ( $region->Tag() eq "primer_bind" ) {

			next unless ( $self->showPrimer() );
			$meanX =
			  $self->drawLine( $im, $region->Start(), $region->End(),
				$self->{color}->{dark_blue} );

# next if ( $region->ExprStart() < $self->min_value() || $region->ExprStart() > $self->max_value());
			$start = $region->Start();
			$end   = $region->End();
			$start = $self->min_value() if ( $start < $self->min_value() );
			$end   = $self->max_value if ( $end > $self->max_value() );

#			warn "multiline_gb_axis does not plot the feature names in this configuration!\n";
#			next;
			( $name, $color ) = $self->{color}->getIg_Values($region);
			$name = $region->Name();
			$name = $1 if ( $name =~ m/lcl\|(.+)/ );
			$name = $1 if ( $region->getAsGB =~ m/(TW\d+)/ );

			$self->{font}->plotString_FitIntoX_range_leftEnd(
				$im,                         $name,
				$self->resolveValue($start), $self->resolveValue($end),
				$self->{down_y2} - 3,        $self->{color}->{dark_blue},
				"gbfeature"
			) if ( $region->ExprStart() == $region->End() );
			$self->{font}->plotString_FitIntoX_range_rightEnd(
				$im,                         $name,
				$self->resolveValue($start), $self->resolveValue($end),
				$self->{down_y2} - 3,        $self->{color}->{dark_blue},
				"gbfeature"
			) if ( $region->ExprStart() == $region->Start() );
		}
		if ( $region->Tag() eq "gene" ) {

			$name = $region->Name();
			if ( $name =~ m/".*/ ) {    #"
				@temp = split( '"', $name );
				$name = $temp[1];
			}
			$meanX =
			  $self->drawLine( $im, $region->Start(), $region->End(),
				$self->{color}->{black} );
			$start = $region->Start();
			$end   = $region->End();
			$start = $self->min_value() if ( $start < $self->min_value() );
			$end   = $self->max_value if ( $end > $self->max_value() );

			$self->{font}->plotString_FitIntoX_range_leftEnd(
				$im,                         $name,
				$self->resolveValue($start), $self->resolveValue($end),
				$self->{down_y2} - 3,        $self->{color}->{black},
				"gbfeature"
			) if ( $region->ExprStart() == $region->End() );
			$self->{font}->plotString_FitIntoX_range_rightEnd(
				$im,                         $name,
				$self->resolveValue($start), $self->resolveValue($end),
				$self->{down_y2} - 3,        $self->{color}->{black},
				"gbfeature"
			) if ( $region->ExprStart() == $region->Start() );
		}
	}
	my $string;
	foreach my $IgFeatureType ( keys %$locations ) {
		print
"We plot the feature Type $IgFeatureType beween bp $locations->{$IgFeatureType}->{start}",
		  " and $locations->{$IgFeatureType}->{end}\n";
		$im->line(
			$self->resolveValue( $locations->{$IgFeatureType}->{start} ),
			$self->{_y2},
			$self->resolveValue( $locations->{$IgFeatureType}->{end} ),
			$self->{_y2},
			$locations->{$IgFeatureType}->{color}
		) unless ( $IgFeatureType eq "enhancer" );
		$string = "$1 cluster" if ( $IgFeatureType =~ m/^([VDJC])_/ );
		$self->{font}->plotStringCenteredAtX(
			$im, $string,
			(
				$self->resolveValue( $locations->{$IgFeatureType}->{start} ) +
				  $self->resolveValue( $locations->{$IgFeatureType}->{end} )
			  ) / 2,
			$self->{down_y2} - 3,
			$locations->{$IgFeatureType}->{color},
			"gbfeature"
		) unless ( $IgFeatureType eq "enhancer" );
	}
	## plot the gaps:
	$self->{x_axis}
	  ->plot_holes( $im, $self->{y1}, $self->{y2}, $self->{color} );
	## plot the lines arround the axis:
	$im->line(
		$self->{min_pixel}, $self->{y1}, $self->{min_pixel},
		$self->{y2},        $self->{color}->{black}
	);
	$im->line(
		$self->{max_pixel}, $self->{y1}, $self->{max_pixel},
		$self->{y2},        $self->{color}->{black}
	);
	$self->{x_axis}
	  ->plot_simple_base_line( $im, $self->{y1}, $self->{color}->{black} );
	$self->{x_axis}->plot( $im, $self->{y2}, $self->{color}->{black} );
}

sub isOutOfRange{
	my ($self, $value) = @_;
	#print "Analyzing the location in x_axis  $self->{x_axis}\n";
	return $self->{x_axis}->isOutOfRange($value);
}

sub plot_complex {
	my ( $self, $im, $font ) = @_;
	my ( $GBregions, $plotSite, $name, $color, $meanX, $start, $end, @temp );
	unless ( defined $self->{gbFile} ) {
		die
"multiline_gb_Axis: this is a final blow! no gbFile in MultiLinePlot!\n";
		return -1;
	}

	$self->useDefaultRegions();

	$self->{color}->Colored_V_segments( $self->{colored_V_segments} );
	$self->{color}->highlight_Vsegment( $self->highlight_Vsegment() );
	
	print ref($self).".the x_axis is of type ".ref($self->{x_axis})."\n";
	$self->{x_axis}->{'tic_length'} = 0;
	$self->{x_axis}->plot( $im, $self->{y1} , $self->{color}->{black}, $self->Title() );
	$self->{y1} += 25;
	$self->{x_axis}->plot_simple_base_line( $im, $self->{y1} , $self->{color}->{black}, $self->Title() );
	$GBregions = $self->{gbFile}->Features();
	$self->{font} = $font if ( defined $font && $font =~ m/Font/ );

	$self->{up_y1}   = $self->{y1} +    ( $self->{y2} - $self->{y1} ) / 40;
	$self->{up_y2}   = $self->{y1} +    ( $self->{y2} - $self->{y1} ) * 19 / 40;
	$self->{down_y1} = $self->{y1} +    ( $self->{y2} - $self->{y1} ) * 21 / 40;
	$self->{down_y2} = $self->{y1} +    ( $self->{y2} - $self->{y1} ) * 39 / 40;
	$self->{up_mean} = $self->{up_y1} + ( $self->{up_y2} - $self->{up_y1} ) / 2;
	$self->{down_mean} =
	  $self->{down_y1} + ( $self->{down_y2} - $self->{down_y1} ) / 2;

	foreach my $region (@$GBregions) {
		next
		  if ( $region->Start() > $self->max_value()
			|| $region->End() < $self->min_value() );
		next if ( $self->UseRegion($region) == 0 );

		unless ( defined $region->IsComplement() ) {   ##plot on the upper side!
			$self->{act_y1} = $self->{up_y1};
			$self->{act_y2} = $self->{up_y2};
			$self->{mean}   = $self->{up_mean};
			$self->{not_y1} = $self->{down_y1};
			$self->{not_y2} = $self->{down_y2};
			$self->{actLoc} = "sense";
		}
		else {    ## plot on the lower side!
			$self->{act_y1} = $self->{down_y1};
			$self->{act_y2} = $self->{down_y2};
			$self->{mean}   = $self->{down_mean};
			$self->{actLoc} = "anti";
			$self->{not_y1} = $self->{up_y1};
			$self->{not_y2} = $self->{up_y2};
		}
		if ( $region->Tag() eq "gene" ) {

			$name = $region->Name();
			if ( $name =~ m/".*/ ) {    #"
				@temp = split( '"', $name );
				$name = $temp[1];
			}

#			$im->setBrush($self->createBrush($self->{color}->{black}, $self->{actLoc}));
#			$im->setStyle($self->{color}->{black},$self->{color}->{black},$self->{color}->{black},#
#			$self->{color}->{black},$self->{color}->{black}, gdStyledBrushed);
#
#			$meanX = $self->drawLine($im, $region->Start(), $region->End(),gdStyledBrushed );
			$meanX =
			  $self->drawLine( $im, $region->Start(), $region->End(),
				$self->{color}->{black} );

# next if ( $region->ExprStart() < $self->min_value() || $region->ExprStart() > $self->max_value());
			$start = $region->Start();
			$end   = $region->End();
			$start = $self->min_value() if ( $start < $self->min_value() );
			$end   = $self->max_value if ( $end > $self->max_value() );

#			warn "multiline_gb_axis does not plot the feature names in this configuration!\n";
#			next;
#print "sorry maybe font is not initialized? $self->{font} in $self\n";
			$self->{font}->plotString_FitIntoX_range_leftEnd(
				$im, $name,
				$self->resolveValue($start),
				$self->resolveValue($end),
				$self->{act_y1}, $self->{color}->{black}, "gbfeature"
			) if ( $region->ExprStart() == $region->End() );
			$self->{font}->plotString_FitIntoX_range_rightEnd(
				$im, $name,
				$self->resolveValue($start),
				$self->resolveValue($end),
				$self->{not_y1}, $self->{color}->{black}, "gbfeature"
			) if ( $region->ExprStart() == $region->Start() );
		}
		if ( $self->IsIG_region( $region->Tag() ) ) {
			( $name, $color ) = $self->{color}->getIg_Values($region);

			$meanX =
			  $self->drawLine( $im, $region->Start(), $region->End(), $color )
			  ;    #gdStyledBrushed );
			$self->drawBox( $im, $region, $color );

			$self->{font}->plotStringCenteredAtXY(
				$im,
				$self->{color}
				  ->V_segment_Name( $region->Name(), $region->Tag() ),
				$self->resolveValue( $region->ExprStart() ),
				( $self->{not_y2} + $self->{not_y1} ) / 2,
				$color,
				"gbfeature"
			);
		}
		if ( $region->Tag() =~ m/mRNA/ || $region->Tag() eq "exon" ) {

			#print "Got a mRNA\n";
			$self->drawSmallBox( $im, $region );
		}
		if ( $region->Tag() eq "CDS" ) {

			#		    print "got a CDS!\n";
			$self->drawBox( $im, $region );
		}
		if ( $region->Tag() eq "primer_bind" ) {

			next unless ( $self->showPrimer() );

			#print "we plot a primer!\n";
			$meanX =
			  $self->drawLine( $im, $region->Start(), $region->End(),
				$self->{color}->{dark_blue} );

# next if ( $region->ExprStart() < $self->min_value() || $region->ExprStart() > $self->max_value());
			$start = $region->Start();
			$end   = $region->End();
			$start = $self->min_value() if ( $start < $self->min_value() );
			$end   = $self->max_value if ( $end > $self->max_value() );

#			warn "multiline_gb_axis does not plot the feature names in this configuration!\n";
#			next;
			( $name, $color ) = $self->{color}->getIg_Values($region);
			$name = $region->Name();
			#print "Name (1)? $name\n";
			$name = $1 if ( $name =~ m/lcl\|(.+)/ );
			#print "Name (2)? $name\n";
			$name = $1 if ( $region->getAsGB =~ m/(TW\d+)/ );
			#print "Name (3)? $name\n";
			$name = $1 if ( $name =~ m/lcl\|(.+)/ );
			#print "Name (4)? $name\n";

			$self->{font}->plotString_FitIntoX_range_leftEnd(
				$im,                         $name,
				$self->resolveValue($start), $self->resolveValue($end),
				$self->{act_y1},             $self->{color}->{dark_blue},
				"gbfeature"
			) if ( $region->ExprStart() == $region->End() );
			$self->{font}->plotString_FitIntoX_range_rightEnd(
				$im,                         $name,
				$self->resolveValue($start), $self->resolveValue($end),
				$self->{not_y1},             $self->{color}->{dark_blue},
				"gbfeature"
			) if ( $region->ExprStart() == $region->Start() );
		}

	}
	## plot the gaps:
	$self->{x_axis}
	  ->plot_holes( $im, $self->{y1}, $self->{y2}, $self->{color} );
	## plot the lines arround the axis:
	$im->line(
		$self->{min_pixel}, $self->{y1}, $self->{min_pixel},
		$self->{y2},        $self->{color}->{black}
	);
	$im->line(
		$self->{max_pixel}, $self->{y1}, $self->{max_pixel},
		$self->{y2},        $self->{color}->{black}
	);
	$self->{x_axis}
	  ->plot_simple_base_line( $im, $self->{y1}, $self->{color}->{black} );
	$self->{x_axis}
	  ->plot_simple_base_line( $im, $self->{y2}, $self->{color}->{black} );

}

sub drawSmallBox {
	my ( $self, $im, $gbFeature, $color ) = @_;

	return 1
	  if ( $gbFeature->Start > $self->max_value
		|| $gbFeature->End < $self->min_value() );
	$color = $self->{color}->{black} unless ( defined $color );
	my ( $region_for_drawing, $start, $end, $y1, $y2, $y_mean, $x1, $x2 );
	$region_for_drawing = $gbFeature->getRegionForDrawing();
	foreach my $region (@$region_for_drawing) {

		#print "multiline_gb_Axis drawSmallBox got region $region\n";
		next
		  if ( $region->{start} > $self->max_value
			|| $region->{end} < $self->min_value() );
		$start = $region->{start};
		$start = $self->min_value() if ( $start < $self->min_value() );
		$end   = $region->{end};
		$end   = $self->max_value() if ( $end > $self->max_value );
		$x1    = $self->resolveValue($start);
		$x2    = $self->resolveValue($end);
		$y1 =
		  int( $self->{act_y1} + ( $self->{act_y2} - $self->{act_y1} ) / 3 );
		$y2 =
		  int( $self->{act_y2} - ( $self->{act_y2} - $self->{act_y1} ) / 3 );
		$y_mean = int( $self->{mean} );

#print "Try to draw a small Box with multiline_gb_Axis y1 = $y1; y2 = $y2; mean = $y_mean; x1 = $x1; x2 = $x2\n";
		if ( $y_mean - $y1 < $y2 - $y_mean ) {
			$y1--;
		}
		$im->filledRectangle(
			$self->resolveValue($start),
			$y1, $self->resolveValue($end),
			$y2, $color
		);

	}
}

sub drawBox {
	my ( $self, $im, $gbFeature, $color ) = @_;

	return 1
	  if ( $gbFeature->Start > $self->max_value
		|| $gbFeature->End < $self->min_value() );
	$color = $self->{color}->{black} unless ( defined $color );
	my ( $region_for_drawing, $start, $end, $y1, $y2, $y_mean );
	$region_for_drawing = $gbFeature->getRegionForDrawing();
	foreach my $region (@$region_for_drawing) {
		next
		  if ( $region->{start} > $self->max_value
			|| $region->{end} < $self->min_value() );
		$start = $region->{start};
		$start = $self->min_value() if ( $start < $self->min_value() );
		$end   = $region->{end};
		$end   = $self->max_value() if ( $end > $self->max_value );
		$y1 =
		  int( $self->{act_y1} + ( $self->{act_y2} - $self->{act_y1} ) / 5 );
		$y2 =
		  int( $self->{act_y2} - ( $self->{act_y2} - $self->{act_y1} ) / 5 );
		$y_mean = int( $self->{mean} );

		if ( $y_mean - $y1 < $y2 - $y_mean ) {
			$y1--;
		}
		unless (
			int( $self->resolveValue($start) ) ==
			int( $self->resolveValue($end) ) )
		{
			$im->filledRectangle(
				int( $self->resolveValue($start) ),
				$y1, int( $self->resolveValue($end) ),
				$y2, $color
			);
		}
		else {
			$im->line(
				int( $self->resolveValue($start) ),
				$y1, int( $self->resolveValue($end) ),
				$y2, $color
			);
		}

	}
}

sub drawLine {
	my ( $self, $im, $startBP, $endBP, $color ) = @_;
	my ( $startPix, $endPix, $arrow_height );

	$color = $self->{color}->{grey} unless ( defined $color );
	$startBP = $self->min_value() if ( $startBP < $self->min_value() );
	$endBP   = $self->max_value() if ( $endBP > $self->max_value );
	( $startPix, $endPix ) =
	  ( $self->resolveValue($startBP), $self->resolveValue($endBP) );
	$im->line(
		$self->resolveValue($startBP),
		$self->{mean}, $self->resolveValue($endBP),
		$self->{mean}, $color
	);
	$color = $self->{color}->{dark_grey}
	  if ( $color == $self->{color}->{black} );
	$arrow_height = 4;
	$arrow_height = int( ( $self->{act_y2} - $self->{act_y1} ) / 5 )
	  if ( ( $self->{act_y2} - $self->{act_y1} ) / 5 > 4 );
	$arrow_height = int( ( ( $self->{act_y2} - $self->{act_y1} ) / 5 ) * 2 / 3 )
	  if ( ( $self->{act_y2} - $self->{act_y1} ) / 5 > 8 );

	if ( $self->{actLoc} eq "sense" ) {    #
		for (
			my $i = $startPix ;
			$i < $endPix - $arrow_height ;
			$i = $i + $self->{space_between_the_transciption_arrows}
		  )
		{
			$im->line(
				$i,
				$self->{mean} - $arrow_height,
				$i + $arrow_height,
				$self->{mean}, $color
			);
			$im->line(
				$i,
				$self->{mean} + $arrow_height,
				$i + $arrow_height,
				$self->{mean}, $color
			);
		}
	}
	else {
		for (
			my $i = $endPix ;
			$i > $startPix + $arrow_height ;
			$i = $i - $self->{space_between_the_transciption_arrows}
		  )
		{
			$im->line( $i - $arrow_height,
				$self->{mean}, $i, $self->{mean} - $arrow_height, $color );
			$im->line( $i - $arrow_height,
				$self->{mean}, $i, $self->{mean} + $arrow_height, $color );
		}
	}
	return ( $self->resolveValue($endBP) + $self->resolveValue($startBP) ) / 2;
}

sub defineAxis {
	my ($self) = @_;

	unless ( defined $self->{x_axis} ) {
		$self->{x_axis} =
		  multi_axis->new( "x", $self->{x1}, $self->{x2}, $self->{axis_title},
			$self->{resolution} );
	}
	return $self->{x_axis}->defineAxis();
}

1;
