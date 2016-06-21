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
	$error .=
	  "I need a gbFile object at stefans_libs::plot::multi_axis->new()\n"
	  unless ( ref($gbFile) eq "gbFile" );
	$error .= "I need a start in bp at stefans_libs::plot::multi_axis->new()\n"
	  unless ( $start > 0 );
	$error .= "I need a end in bp at stefans_libs::plot::multi_axis->new()\n"
	  unless ( $end > 0 );
	$error .=
	  "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n"
	  unless ( defined $x1 );
	$error .=
	  "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n"
	  unless ( defined $x2 );
	$error .=
	  "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n"
	  unless ( defined $y1 );
	$error .=
	  "I need a dimension (x1) in bp at stefans_libs::plot::multi_axis->new()\n"
	  unless ( defined $y2 );
	$error .= "I need a resolution at stefans_libs::plot::multi_axis->new()\n"
	  unless ( defined $resolution );
	$error .= "I need a color object at stefans_libs::plot::multi_axis->new()\n"
	  unless ( ref($color) eq "color" );
	Carp::confess($error) if ( $error =~ m/\w/ );

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

	bless $self, $class
	  if ( $class eq "stefans_libs::plot::multiline_gb_Axis" );

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
	my $colorOb     = color->new($arrow_brush);

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

sub define_line_coordinates {
	my ( $self, $line_count ) = @_;
	my ( $lines, $line_hight );
	#$line_hight = int( ( $self->{'y2'} - $self->{'y1'} ) / $line_count );
	$line_hight = 15;
	$lines->{-1} = [ $self->{'y1'}, $self->{'y2'}];#only necessary for the genomePlot estimation of the whole size of the axis!
	for ( my $i =0 ; $i < $line_count  ; $i++ ) {
		$lines->{$i} = [
			( $self->{'y1'} + ($i + 2) * $line_hight ) + 1,
			( $self->{'y1'} + ($i + 2) * $line_hight + $line_hight ) - 1
		];
	}
	return $lines;
}

sub plot {
	my ( $self, $im, $font ) = @_;
	## now I need to check how many overlaps we got!
	## For an overlap only the genes are of importance!
	my $line_count = $self->calculate_required_lines();
	$line_count++;
	$im->newGroup("multilineGB_AXIS_$self");
	## define lines where I can plot a gbFeature
	$self->{x_axis}
	  ->plot( $im, $self->{y1}  , $self->{color}->{black}, $self->Title() );
	my $lines = $self->define_line_coordinates($line_count);
## Now I need to figure out where to place the gbFeatures.
	my $feature_gene_name_count;
	foreach my $gbFeature ( @{ $self->{'gbFile'}->Features() } ) {
		next unless ( $gbFeature->will_be_plotted() );
		$feature_gene_name_count->{ $gbFeature->Name() } = {}
		  unless ( defined $feature_gene_name_count->{ $gbFeature->Name() } );
		unless (
			defined $feature_gene_name_count->{ $gbFeature->Name() }
			->{ $gbFeature->Tag() } )
		{
			$feature_gene_name_count->{ $gbFeature->Name() }
			  ->{ $gbFeature->Tag() } = 0;
		}
		else {
			$feature_gene_name_count->{ $gbFeature->Name() }
			  ->{ $gbFeature->Tag() }++;
		}

		$gbFeature->plot_2_image(
			$im, $self, $font,
			$self->{color},
			$self->{color}->{'black'},
			@{
				$lines->{
					@{ $self->{'placements'}->{ $gbFeature->Name() } }[
					  $feature_gene_name_count->{ $gbFeature->Name() }
					  ->{ $gbFeature->Tag() }
					] } }
		);

	}
	$im->endGroup();
}

=head2 calculate_required_lines ();

This function places each transcript into a different line in case the transcripts do overlap.
Returns the maximum number of required lines

=cut

sub calculate_required_lines {
	my ($self) = @_;
	my ( $max_line, $act_line, $last_end );
	$act_line = $max_line = 0;
	foreach my $gbfeature ( @{ $self->{'gbFile'}->Features() } ) {
		next unless ( $gbfeature->Tag() =~ m/.+RNA/ );
		if ( defined $last_end ) {
			if ( $last_end > $self->resolveValue( $gbfeature->Start() ) - 50 )
			{    ## we have an overlap!
				$act_line++;
				$max_line = $act_line if ( $act_line > $max_line );
			}
			else {
				$act_line = 0;
			}
			$self->{'placements'}->{ $gbfeature->Name() } = []
			  unless ( defined $self->{'placements'}->{ $gbfeature->Name() } );
			push(
				@{ $self->{'placements'}->{ $gbfeature->Name() } },
				$act_line
			);
		}
		else {
			$self->{'placements'}->{ $gbfeature->Name() } = []
			  unless ( defined $self->{'placements'}->{ $gbfeature->Name() } );
			push(
				@{ $self->{'placements'}->{ $gbfeature->Name() } },
				$act_line
			);
		}
		$last_end = $self->resolveValue( $gbfeature->End() );
	}
	return $max_line;
}


sub isOutOfRange {
	my ( $self, $value ) = @_;

	#print "Analyzing the location in x_axis  $self->{x_axis}\n";
	return $self->{x_axis}->isOutOfRange($value);
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
