package stefans_libs_plot_genomePlot;

#  Copyright (C) 2012-10-30 Stefan Lang

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
use stefans_libs::plot::figure;
use stefans_libs::plot::multiline_gb_Axis;

use base 'figure';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_plot_genomePlot

=head1 DESCRIPTION

This lib is a multiline plot element, that can query the database for a genome interface and can therefore access all information, that was added to that genome. It will also me able to use special table files for plotting data directly to this genome slice. The data can be supplemented as bed file or as bedGraph data.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_plot_genomePlot.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'datasets'                                => 0,
		'data'                                    => [],
		'colors'                                  => [],
		'stefans_libs_file_readers_bedGraph_file' => 50,
		'stefans_libs_file_readers_bed_file'      => 20,
		'genome_height'                           => 150,
	};

	bless $self, $class if ( $class eq "stefans_libs_plot_genomePlot" );

	return $self;

}

sub GenomeInterface {
	my ( $self, $gbFeatureTable ) = @_;
	if ( defined $gbFeatureTable ) {
		$self->{'genome'} = $gbFeatureTable;
	}
	unless ( ref( $self->{'genome'} ) eq "gbFeaturesTable" ) {
		Carp::confess(
			    "I need a gbFeaturesTable in order to plot anything!\nNot "
			  . ref( $self->{'genome'} )
			  . "\n" );
	}
	return $self->{'genome'};
}

=head AddDataset ($data, $color )

This function adds data to the figure staring from the top to the botom.
The data has to be of type 'stefans_libs_file_readers_bed_file' or 'stefans_libs_file_readers_bedGraph_file'
to be plotted.

The color should be given as 'red', 'blue' or something like that. You can get a list of defined 
colors by looking into the color object.

=cut

sub AddDataset {
	my ( $self, $data, $color, $title ) = @_;
	unless ( ref($data) eq 'stefans_libs_file_readers_bedGraph_file' ) {
		unless ( ref($data) eq 'stefans_libs_file_readers_bed_file' ) {
			Carp::confess(
"Sorry, but you can only add 'stefans_libs_file_readers_bedGraph_file'"
				  . "or 'stefans_libs_file_readers_bed_file' objects to the graph!\n"
				  . "Not '"
				  . ref($data)
				  . "'\n" );
		}
	}
	$data->Title($title);
	@{ $self->{'colors'} }[ $self->{'datasets'} ] = $color;
	@{ $self->{'data'} }[ $self->{'datasets'}++ ] = $data;
	return $self->{'datasets'};
}

sub print2file {
	my ( $self, $outfile ) = @_;

	my @temp;
	@temp = split( "/", $outfile );
	pop(@temp);
	mkdir( join( "/", @temp ) ) unless ( -d join( "/", @temp ) );
	if ( $outfile =~ m/txt$/ ) {
		$outfile =~ s/txt$/bed/;
	}
	unless ( $outfile =~ m/bedGraph$/ ) {
		$outfile .= ".bedGraph";
	}
	open( OUT, " >$outfile" )
	  or Carp::confess(
		ref($self)
		  . "::print2file -> I can not create the outfile '$outfile'\n$!\n" );
	print OUT @{ $self->{'description'} }[0] . "\n"
	  if ( defined @{ $self->{'description'} }[0] );
	for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {
		print OUT join( "\t", @{ @{ $self->{'data'} }[$i] } ) . "\n";
	}
	close(OUT);
	print "all data written to '$outfile'\n";
	return $outfile;
}

=head2 plot ( {'gbFile' => <gbFile_object>, 'start' => <start in bp>, 'end' => <end in basepair> } )

this function will create a svg outfile that would scale to 800 px width and 
a variable height. The height depends on the total amount and the type of the displayed data.

=cut

sub _check_plot_2_image_hash {
	my ( $self, $hash ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .= "check_plot_2_image_hash: I miss a gbFile "
	  unless ( ref( $hash->{'gbFile'} ) eq "gbFile" );
	$self->{'error'} .= "check_plot_2_image_hash: I need a start value (bp) "
	  unless ( defined $hash->{'start'} );
	$self->{'error'} .= "check_plot_2_image_hash: I need a end value (bp) "
	  unless ( defined $hash->{'end'} );
	return 1 if ( $self->{'error'} =~ m/\w/ );
	return 0;
}

=head2 Dataset_height ('dataset_name', 'value' );

Set the image height for the different data types.
'dataset_names' can be 
'stefans_libs_file_readers_bedGraph_file',
'stefans_libs_file_readers_bed_file' or
'genome'.

=cut

sub Dataset_height {
	my ( $self, $dataset, $height ) = @_;
	foreach (qw(datasets data colors color font im genome)) {
		Carp::confess(
"You must not try to change any of my important features like '$dataset'"
		  )
		  if ( $dataset eq $_ );
	}
	if ( defined $height ) {
		$self->{$dataset} = $height;
	}
	Carp::confess(
		"Sorry, but you need to initialize the Dataset_height first!\n")
	  unless ( defined $self->{$dataset} );
	return $self->{$dataset};
}

sub AddGitter {
	my ( $self, $color_ob, $space ) = @_;
	print "Why do I not have the image information here? ($self $self->{'im'})\n";
	my ( $width, $height ) = $self->{'im'}->getBounds();
	for ( my $i = $space ; $i < $width ; $i += $space ) {
		$self->{'im'}
		  ->line($i, 0, $i, $height, $color_ob->{light_blue} );
	}
}

sub plot_2_image {
	my ( $self, $hash ) = @_;
	$self->_check_plot_2_image_hash($hash);
	Carp::confess( $self->{'error'} )
	  if ( $self->{'error'} =~ m/\w/ );
	my ( $group_name, $dataset, @colors );
	$group_name = ref($self) . rand();
	my $width = 800;
	my $test;
	my $gbFile = $hash->{'gbFile'};

	my $im = new GD::SVG::Image( 1000, 800 );
	my $color = color->new($im);
	$test =
	  stefans_libs::plot::multiline_gb_Axis->new( $gbFile, $hash->{'start'},
		$hash->{'end'}, 0, 0, $width, 150, 'min', $color );
	$test =
	  $test->define_line_coordinates( $test->calculate_required_lines() + 1 );

	my ( $gene_max, $gene_min );
	foreach ( sort { $a <=> $b } keys %$test ) {
		$gene_min = @{ $test->{$_} }[0] unless ( defined $gene_min );
		$gene_max = @{ $test->{$_} }[1];
	}
	my $height = $gene_max - $gene_min;    ## for the x axis and the title
	$self->Dataset_height( 'genome_height', $height );
	foreach ( @{ $self->{'data'} } ) {

		#	print "I add "
		#	  . $self->Dataset_height( ref($_) )
		#	  . " to the heigth of $height\n!";
		$height += $self->Dataset_height( ref($_) );
	}

	#print "I set the height to $height\n";

	$hash->{'im'} =
	  $self->_createPicture( { 'x_res' => $width, 'y_res' => $height } );
	print
"I have created an image ($self $self->{'im'}) using the with $width and height $height\n";
	$self->AddGitter( $self->{'color'}, 20 );

	$self->{'xaxis'} =
	  stefans_libs::plot::multiline_gb_Axis->new( $gbFile, $hash->{'start'},
		$hash->{'end'}, 0, 0, $width, 150, 'min', $self->{'color'} );
	$self->{'xaxis'}->min_value( $hash->{'start'} );
	$self->{'xaxis'}->max_value( $hash->{'end'} );
	## plot the axies
	$self->_plot_axies();

	#warn "we have plotted the axies\n";
	my $i = 0;
	my ( $last_y, $this_y );
	$last_y = $self->Dataset_height('genome_height');
	for ( my $i = 0 ; $i < $self->{'datasets'} ; $i++ ) {
		$this_y =
		  $last_y + $self->Dataset_height( ref( @{ $self->{'data'} }[$i] ) );

		@{ $self->{'data'} }[$i]->plot_2_image(
			{
				'im'         => $hash->{'im'},
				'xaxis'      => $self->{'xaxis'},
				'y_min'      => $last_y,
				'y_max'      => $this_y,
				'color_obj'  => $self->{'color'},
				'font'       => $self->{'font'},
				'color'      => @{ $self->{'colors'} }[$i],
				'chromosome' => $hash->{'chromosome'},
			}
		);

		$last_y = $this_y;
	}
	$self->plot_title();
	$self->Note( $self->{im} );
	$self->{im}->endGroup($group_name);
	return $self->{im};
}

sub _plot_axies {
	my ($self) = @_;
	## all the values should have been initialized using the _check_plot_2_image_hash
	## therefore I expect you to call that function inside of the plot_2_image function
	return 1 if ( $self->{'_axies_were_plottet_'} );
	$self->Xtitle('no title') unless ( defined $self->Xtitle() );
	unless ( ref( $self->{xaxis} ) eq "stefans_libs::plot::multiline_gb_Axis" )
	{
		$self->{xaxis}->plot(
			$self->_createPicture(), 400,
			$self->{color}->{black}, $self->Xtitle()
		);
	}
	else {
		$self->{xaxis}->plot( $self->_createPicture(), $self->{font} );
	}

	$self->{'_axies_were_plottet_'} = 1;
	return 1;
}

sub __we_contain_data {
	return 1;
}
1;
