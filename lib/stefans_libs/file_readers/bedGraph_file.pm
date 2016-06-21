package stefans_libs_file_readers_bedGraph_file;

#  Copyright (C) 2012-10-28 Stefan Lang

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
use stefans_libs::flexible_data_structures::data_table;
use base 'data_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_file_readers_bed_file

=head1 DESCRIPTION

A simple bed file reader.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_file_readers_bed_file.

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug'       => $debug,
		'arraySorter' => arraySorter->new(),
		## if you change the columns think also to change the parse_from_string function!
		'header_position' => {
			'chromosome' => 0,
			'start'      => 1,
			'end'        => 2,
			'value'      => 3,
		},
		'default_value'         => [],
		'header'                => [ 'chromosome', 'start', 'end', 'value' ],
		'data'                  => [],
		'index'                 => {},
		'__LaTeX_column_mods__' => {},
		'__HTML_column_mods__'  => {},
		'last_warning'          => '',
		'subsets'               => {}
	};

	bless $self, $class
	  if ( $class eq "stefans_libs_file_readers_bedGraph_file" );
	$self->define_subset( 'UCSC_key', ['chromosome', 'start', 'end']);
	return $self;

}

=head2 invert ( $max )
Invert() does calculate the positions for the data values (e.g. from an promoter analysis)
as if the feature would not be in antisense, but in sense orientation in the dataset.
As example: you have selected a list of promoter elements from the database using the
gbFeatureTable->get_promoter_regions_4_genes() function. This function will give you chromosomal positions
for each transcript plus a indication whether this data is in the sense or antisense orientation.
Using this function you can invert the datapoints of the inverted data.
But inorder to keep the scale right, I need the max length of the sequences.
=cut

sub Invert {
	my ( $self, $max ) = @_;
	my ($a, $temp);
	for ( my $i = 0; $i < $self->Lines(); $i ++ ) {
		$a = @{$self->{'data'}}[$i];
		$temp = @$a[1];
		@$a[1] = $max - @$a[2];
		@$a[2] = $max - $temp;
	}
	return $self;
}

sub parse_from_string {
	my ( $self, $lines ) = @_;
	## the first line might contain important information
	$self->{'data'} = [];

	unless ( ref($lines) eq "ARRAY" ) {
		$lines = [ split( "\n", $lines ) ];
	}
	my $temp;
	$self->{'description'} = [];
	if ( @$lines[0] =~ m/^track name=/ ) {
		chomp( @$lines[0] );
		$self->Add_2_Description( @$lines[0] );
		shift(@$lines);
	}
	for ( my $i = 0 ; $i < @$lines ; $i++ ) {
		$temp = $self->__split_line( @$lines[$i] );
		## here I throw away everything but the first three information parts!
		$temp = [ @$temp[ 0 .. 3 ] ];
		@{ $self->{'data'} }[$i] = $temp;
	}
	foreach my $columnName ( keys %{ $self->{'index'} } ) {
		$self->__update_index($columnName);
	}
	foreach my $unique ( keys %{ $self->{'uniques'} } ) {
		$self->UpdateUniqueKey($unique);
	}
	$self->After_Data_read();
	return 1;
}

sub Name {
	my ( $self, $name ) = @_;
	if ( defined $name ) {
		$self->{'name'} = $name;
	}
	if ( defined $self->{'name'} ){
		return " name=\"$self->{'name'}\"";
	}
	return '';
}
sub AsString {
	my ( $self, $subset ) = @_;
	my $str = '';
	my @default_values;
	my @line;
	if ( defined $subset ) {
		## 1 get the default values
		return $self->GetAsObject($subset)->AsString();
	}
	else {
		$str .=
		  "track type=bedGraph".$self->Name()."\n";
		  ;       ## probably I support more options later on...
		@default_values = $self->getAllDefault_values();
		foreach my $data ( @{ $self->{'data'} } ) {
			@line = @$data;
			for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
				$line[$i] = $default_values[$i] unless ( defined $line[$i] );
				$line[$i] = '"' . $line[$i] . '"'
				  if ( $self->__col_format_is_string($i) )
				  ;    # &&  ! $line[$i] =~m/^\s*$/ );
			}
			$str .= join( $self->line_separator(), @line ) . "\n";
		}
	}
	return $str;
}

sub min {
	my ( $self ) = @_;
	return $self->{'min'} if ( defined $self->{'min'});
	$self->{'min'} = @{@{$self->{'data'}}[0]}[3];
	for ( my $i = 0; $i < $self->Lines(); $i ++ ) {
		$self->{'min'} = @{@{$self->{'data'}}[0]}[3] if ( @{@{$self->{'data'}}[0]}[3]< $self->{'min'});
	}
	return $self->{'min'};
}

sub max {
	my ( $self ) = @_;
	return $self->{'max'} if ( defined $self->{'max'});
	$self->{'max'} = @{@{$self->{'data'}}[0]}[3];
	for ( my $i = 0; $i < $self->Lines(); $i ++ ) {
		$self->{'max'} = @{@{$self->{'data'}}[0]}[3] if ( @{@{$self->{'data'}}[0]}[3] > $self->{'max'});
	}
	return $self->{'max'};
}

sub plot_2_image {
	my ( $self, $hash ) = @_;
	## this data should be plotted as bars!
	my $yaxis =
	  axis->new( 'y', $hash->{'y_min'} + 1, $hash->{'y_max'} - 1, '', 'tiny' );
	## identify the min and max values..
	my ( @useable, $min, $max, $use );
	$use = 0;
	$hash->{'chromosome'} = 'chr' . $hash->{'chromosome'}
	  unless ( $hash->{'chromosome'} =~ m/^chr/ );
	for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {
		next
		  unless ( @{ @{ $self->{'data'} }[$i] }[0] eq $hash->{'chromosome'} );
		next
		  if (
			@{ @{ $self->{'data'} }[$i] }[2] <= $hash->{'xaxis'}->min_value() );
		next
		  if (
			@{ @{ $self->{'data'} }[$i] }[1] >= $hash->{'xaxis'}->max_value() );
		$min = $max = @{ @{ $self->{'data'} }[$i] }[3] unless ( defined $min );
		$min = @{ @{ $self->{'data'} }[$i] }[3]
		  if ( @{ @{ $self->{'data'} }[$i] }[3] < $min );
		$max = @{ @{ $self->{'data'} }[$i] }[3]
		  if ( @{ @{ $self->{'data'} }[$i] }[3] > $max );
		@{ @{ $self->{'data'} }[$i] }[1] = $hash->{'xaxis'}->min_value()
		  if (
			@{ @{ $self->{'data'} }[$i] }[1] < $hash->{'xaxis'}->min_value() );
		@{ @{ $self->{'data'} }[$i] }[2] = $hash->{'xaxis'}->max_value()
		  if (
			@{ @{ $self->{'data'} }[$i] }[2] > $hash->{'xaxis'}->max_value() );
		$useable[ $use++ ] = @{ $self->{'data'} }[$i];
	}
	$yaxis->min_value($min);
	$yaxis->max_value($max);
	$yaxis->resolveValue($min);
	## I need a black frame!
	$hash->{'im'}->rectangle(
		$hash->{xaxis}->resolveValue( $hash->{xaxis}->min_value() ),
		$yaxis->resolveValue($min) + 1,
		$hash->{xaxis}->resolveValue( $hash->{xaxis}->max_value() ),
		$yaxis->resolveValue($max) - 1,
		$hash->{'color_obj'}->{black},
	);
	## the 0 line
	$hash->{'im'}->line( $hash->{xaxis}->resolveValue( $hash->{xaxis}->min_value() ) +1,
	$yaxis->resolveValue(0) ,
	$hash->{xaxis}->resolveValue( $hash->{xaxis}->max_value() )-1,
	$yaxis->resolveValue(0),
	$hash->{'color_obj'}->{grey},
	);
	
	## and now I need to plot the values......
	my $last_end;
	for ( my $i = 0 ; $i < @useable ; $i++ ) {
		if ( defined $last_end ) {
			$hash->{'im'}->line(
				$hash->{'xaxis'}->resolveValue( $last_end->{'x'} ),
				$yaxis->resolveValue( $last_end->{'y'} ),
				$hash->{'xaxis'}->resolveValue( @{ $useable[$i] }[1] ),
				$yaxis->resolveValue( @{ $useable[$i] }[3] ),
				$hash->{'color_obj'}->{ $hash->{'color'} },
			);
		}
		$hash->{'im'}->line(
			$hash->{'xaxis'}->resolveValue( @{ $useable[$i] }[1] ),
			$yaxis->resolveValue( @{ $useable[$i] }[3] ),
			$hash->{'xaxis'}->resolveValue( @{ $useable[$i] }[2] ),
			$yaxis->resolveValue( @{ $useable[$i] }[3] ),
			$hash->{'color_obj'}->{ $hash->{'color'} },
		);
		$last_end =
		  { 'x' => @{ $useable[$i] }[2], 'y' => @{ $useable[$i] }[3] };
	}
	if ( defined $self->Title() ) {
		$hash->{'xaxis'}->{'font'}->plotStringAtY_leftLineEnd(
			$hash->{'im'},
			$self->Title(),
			$hash->{'xaxis'}->resolveValue( $hash->{'xaxis'}->min_value() ),
			$yaxis->resolveValue( ( $max + $min ) / 2 ) - 3,
			$hash->{'color_obj'}->{'black'},
			'gbFont',
			0
		);
	}
	##done
	return 1;
}

sub Title {
	my ( $self, $title ) = @_;
	if ( defined $title ) {
		$self->{'title'} = $title;
	}
	$self->{'title'} = '' unless ( defined $self->{'title'} );
	return $self->{'title'};
}

sub write_file {
	my ( $self, $outfile, $subset ) = @_;
	if ( defined $subset && !defined $self->{'subsets'}->{$subset} ) {
		warn "we do not print, as we do not know the subset '$subset'\n";
		return undef;
	}
	my @temp;
	@temp = split( "/", $outfile );
	pop(@temp);
	mkdir( join( "/", @temp ) ) unless ( -d join( "/", @temp ) );
	if ( $outfile =~ m/txt$/ ) {
		$outfile =~ s/txt$/bedGraph/;
	}
	unless ( $outfile =~ m/bedGraph$/ ) {
		$outfile .= ".bedGraph";
	}
	open( OUT, " >$outfile" )
	  or Carp::confess(
		ref($self)
		  . "::print2file -> I can not create the outfile '$outfile'\n$!\n" );
	print OUT $self->AsString($subset);
	close(OUT);
	return $outfile;
}

1;
