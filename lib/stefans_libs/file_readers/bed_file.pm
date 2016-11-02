package stefans_libs::file_readers::bed_file;

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
use PDL;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::file_readers::bed_file

=head1 DESCRIPTION

A simple bed file reader.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::file_readers::bed_file.

=cut

sub new {

	my ( $class, $hash ) = @_;
	
	$hash = { 'debug' => $hash } unless ( ref($hash) eq "HASH");
	my ($self);

	$self = {
		'debug'       => $hash->{'debug'},
		'arraySorter' => arraySorter->new(),
		## if you change the columns think also to change the parse_from_string function!
		'header_position' => {},
		'no_doubble_cross' => 1,
		'default_value'         => [],
		'header'                => [],
		'data'                  => [],
		'index'                 => {},
		'__LaTeX_column_mods__' => {},
		'__HTML_column_mods__'  => {},
		'last_warning'          => '',
		'subsets'               => {},
		'plot_frame'            => 1,
	};

	bless $self, $class if ( $class eq "stefans_libs::file_readers::bed_file" );
	$self->Add_2_Header( [ 'chromosome', 'start','end' ,'name' ]);
	$self->read_file( $hash->{'filename'}) if ( defined $hash->{'filename'});
	return $self;

}

sub CHR_key {
	my ( $self ) = @_;
	unless ( defined $self->Header_Position( 'chr_key') ) {
		$self-> define_subset ('__data__', ['chromosome', 'start', 'end']);
		$self-> calculate_on_columns ( {
	'data_column' => '__data__', 
	'target_column' => 'chr_key',
	'function' => sub{return "$_[0]:$_[1]-$_[2]" }
	});
	}
	return $self->getAsArray( 'chr_key' );
}

=head2 select_chr ( $chr, $start, $end )

=cut

sub __header_as_string { return  '' }

sub select_chr {
	my ( $self, $chr, $start, $end ) = @_;
	$self->define_subset( '___data___', [ 'chromosome', 'start', 'end' ] );
	if ( defined $end ) {
		return $self->select_where(
			'___data___',
			sub {
				my $return = 1;
				$return = 0 unless ( $_[0] eq $chr );
				$return = 0 if ( $_[2] < $start );
				$return = 0 if ( $_[1] > $end );
				return $return;
			}
		);
	}
	if ( defined $start ) {
		return $self->select_where(
			'___data___',
			sub {
				my $return = 1;
				$return = 0 unless ( $_[0] eq $chr );
				$return = 0 if ( $_[2] < $start );
				return $return;
			}
		);
	}
	if ( defined $chr ) {
		return $self->select_where(
			'___data___',
			sub {
				my $return = 1;
				$return = 0 unless ( $_[0] eq $chr );
				return $return;
			}
		);
	}
	else {
		warn ref($self)
		  . "->select_chr( chr, start, end)\n\tI have not even gotten a chromosome!\n";
		return $self;
	}

}

sub sort {
	my ( $self ) = @_;
	return $self = $self->Sort_by(
		[ [ 'chromosome', 'lexical' ], [ 'start', 'numeric' ] ] );
}

sub __process_comment_line {
	my ( $self, $line ) = @_;
	chomp($line);
	if ( $line =~ m/^track/) {
		return $line;
	}
	if ( $line =~ m/^\s*\n/ ){
		return 1;
	}
	if( $_ =~ m/^(#.*)/ ) {
		return $1;
	}
	return 0;
}

sub __split_line {
	my ( $self, $line ) =@_;
	return undef if ( $self->__process_comment_line($line));
	chomp($line);
	return [ split("\t",$line),];
}

sub After_Data_read{
	my ( $self ) = @_;
	if ( ref(@{$self->{'data'}}[0]) eq "ARRAY" ){
		for ( my $i = 4; $i< @{@{$self->{'data'}}[0]}; $i++ ){
			$self->Add_2_Header( 'orig.bed.file.col.'.$i ) unless ( defined @{$self->{'header'}}[$i] );
		}
	}
	my $kill = 0;
	for ( my $i = $self->Lines(); $i > -1; $i -- ) {
		unless ( ref(@{$self->{'data'}}[$i])  eq "ARRAY" ){
			$kill = 1;
		}
		elsif(@{@{$self->{'data'}}[$i]}[0] eq "" ){
			$kill = 1;
		}
		if ( $kill){
			splice( @{$self->{'data'}},$i,1 );
			$kill = 0;
		}
		
	}
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

=head2 match_to ( stefans_libs::file_readers::bed_file );

calculates the match between one bed_file and another.
You will get an array containing the matching entries in the other table as array of lines_ids.
A return value like that [ [1,2,3], [], [5,6],[],[],[9] ] would mean, that 
(0) the first line in this object did match to the lines 1,2 and 3 in the other file
(1) the second line did not match
(2) the third line did match to lines 5 and 6 in the other file
(3, 4) lines 4 and 5 in this object did not match to the other object,
(5) and finally line 6 did match to line 9 in the other file.

=cut

sub match_to {
	my ( $self, $other_bed_file ) = @_;
	my ( $chr_other_index_start_position,
		$index, $i, @result, $temp, $other_lines, $oL );
	$other_bed_file->createIndex('chromosome');
	unless ( ref($other_bed_file) eq ref($self) ) {
		Carp::confess( "I need another object of type "
			  . ref($self)
			  . " at startup, not '"
			  . ref($self)
			  . "\n" );
	}
	for ( $i = 0 ; $i < $self->Lines() ; $i++ ) {
		unless ( ref($other_bed_file->{'index'}->{'chromosome'}
		  ->{ @{ @{ $self->{'data'} }[$i] }[0] }) eq "ARRAY"){
		  	$result[$i]  = [];
		  	next;
		  }
		unless (
			defined
			$chr_other_index_start_position->{ @{ @{ $self->{'data'} }[$i] }[0]
			} )
		{
			$chr_other_index_start_position->{ @{ @{ $self->{'data'} }[$i] }[0]
			  } = 0;
		}
		$result[$i]  = [];
		$temp        = 0;
		$other_lines =
		  $other_bed_file->{'index'}->{'chromosome'}
		  ->{ @{ @{ $self->{'data'} }[$i] }[0] };
		for (
			$index =
			$chr_other_index_start_position->{ @{ @{ $self->{'data'} }[$i] }[0]
			} ;
			$index < scalar(@$other_lines) ;
			$index++
		  )
		{
			$oL = @$other_lines[$index];
			## Do we have an overlap? A.start < B.end && A.end > B.start
			if ( @{ @{ $self->{'data'} }[$i] }[1] <
				   @{ @{ $other_bed_file->{'data'} }[$oL] }[2]
				&& @{ @{ $self->{'data'} }[$i] }[2] >
				@{ @{ $other_bed_file->{'data'} }[$oL] }[1] )
			{
				@{ $result[$i] }[ $temp++ ] = $oL;
			}
			elsif ( @{ @{ $self->{'data'} }[$i] }[2] <
				@{ @{ $other_bed_file->{'data'} }[$oL] }[1] )
			{
				last;
			}
		}
	}
	return \@result;
}

=head2 efficient_match ($other_bed_file)

This tool will use the PDL to calculate the overlap between the two files and update this object 
by adding another column indicating how many entries from the other_bed_file matched to this entry (0-n).

=cut

sub efficient_match {
	my ( $self, $other_bed_file, $colname, $max_dist ) = @_;
	$max_dist ||= 0;
	$colname  ||= $other_bed_file->{'read_filename'};
	my $pos = $self -> Add_2_Header( $colname );
	my ($line, $rep_pdl, $t1, $t2,$t3, @intron_ids );
	local $SIG{__WARN__} = sub { };
	for ( my $i = 0; $i < $self->Rows(); $i ++ ){
		$line = $self->get_line_asHash ( $i );
		$rep_pdl = $other_bed_file ->get_pdls_4_chr( $line->{'chromosome'} );
		if (  ref($rep_pdl) eq "PDL" ) {
			$t1 = $rep_pdl->slice(',1') <= $line->{'end'} + $max_dist;
			$t2 = $rep_pdl->slice(',2') >= $line->{'start'} - $max_dist;
			#my $t =  which( $t1 + $t2 == 2 );
			#print $t;
			@intron_ids =
			  list( transpose( which( $t1 + $t2 == 2 ) ) );	
			#print "Just for test questions: ". join(" ", @intron_ids)." with ".scalar(@intron_ids). " entries\nor more accurate:".
			#join(", ", @{$other_bed_file->{'subset_4_PDL'}->{$line->{'chromosome'}}->GetAsArray('line_id')}[@intron_ids])."\n";
			@{@{$self->{'data'}}[$i]}[$pos] = [ @{$other_bed_file->{'subset_4_PDL'}->{$line->{'chromosome'}}->GetAsArray('line_id')}[@intron_ids] ];
			## the $other_bed_file->{'subset_4_PDL'} has been created to store the right ids in ...
		}
	}
	return $self;
}
=head2 efficient_match_chr_position ( $chr, $start, $end, $max_dist )

match the chromosomal area to the own data and returns the own matching row numbers.

=cut

sub efficient_match_chr_position {
	my ( $self, $chr, $start, $end, $max_dist ) = @_;
	$max_dist ||= 0;
	$end ||= $start;
	local $SIG{__WARN__} = sub { };
	my $rep_pdl = $self ->get_pdls_4_chr( $chr );
#	if ( @{@{$self->{'subset_4_PDL'}->{$chr}->{'data'}}[0]}[1]> $start ) {
#		return ();
#	}elsif ( @{@{$self->{'subset_4_PDL'}->{$chr}->{'data'}}[$self->{'subset_4_PDL'}->{$chr}->Rows()-1]}[2] < $start ){
#		return ();
#	}
	if (  ref($rep_pdl) eq "PDL" ) {
		my $t1 = $rep_pdl->slice(',1') <= $end + $max_dist;
		my $t2 = $rep_pdl->slice(',2') >= $start - $max_dist;
		my @intron_ids = list( transpose( which( $t1 + $t2 == 2 ) ) );	
		return @{$self->{'subset_4_PDL'}->{$chr}->GetAsArray('line_id')}[@intron_ids];
	}
	return ();
}



sub get_pdls_4_chr {
	my ( $self, $chr ) = @_;
	my ($data);
	$self->{'PDL'} ||={};
	$self->{'subset_4_PDL'} ||= {};
	unless ( $self->Header_Position('line_id') ){
		$self->add_column('line_id', [ 0..($self->Rows()-1)] );
	}
	unless ( defined $self->{'PDL'}->{$chr} ) {
		#print "I create the PDL for chr $chr\n";
		$self->{'subset_4_PDL'}->{$chr} =
		  $self ->select_where( 'chromosome',
			sub { return 1 if ( $_[0] eq $chr ); return 0; }, $self->{'read_filename'}  );
		return () if ( $self->{'subset_4_PDL'}->{$chr}->Rows == 0 );
		#print "I got ". $self->{'PDL'}->{$chr}->Rows. " entries for chr $chr\n".join("\t", @{@{$self->{'PDL'}->{$chr}->{'data'}}[0]})."\n";
		$self->{'subset_4_PDL'}->{$chr} -> add_column ( 'INDEX', $self->{'last_matching'} );
		$self->{'subset_4_PDL'}->{$chr} -> define_subset ( 'PDL', [ 'INDEX','start','end', 'line_id']);
		$self->{'PDL'}->{$chr} = $self->{'subset_4_PDL'}->{$chr} -> GetAsObject('PDL')->GetAsPDL();
	}
	return $self->{'PDL'}->{$chr} ;
}

sub add_info_to_name {
	my ( $self, $matching_array, $other_bed_file ) = @_;
	unless ( ref($matching_array) eq "ARRAY" ) {
		Carp::confess(
			"I need an matching arra at strt up - not $matching_array\n");
	}
	unless ( ref($other_bed_file) eq ref($self) ) {
		Carp::confess( "I need another object of type "
			  . ref($self)
			  . " at startup, not '"
			  . ref($self)
			  . "\n" );
	}
	unless ( scalar(@$matching_array) == $self->Lines() ) {
		Carp::confess( "The matching array does not have the right format! "
			  . scalar(@$matching_array) . " != "
			  . $self->Lines()
			  . "\n" );
	}
	my ($other_id);
	for ( my $i = 0 ; $i < $self->Lines ; $i++ ) {
		@{ @{ $self->{'data'} }[$i] }[3] = ''
		  unless ( defined @{ @{ $self->{'data'} }[$i] }[3] );
		foreach $other_id ( @{ @$matching_array[$i] } ) {
			@{ @{ $self->{'data'} }[$i] }[3] .=
			  @{ @{ $other_bed_file->{'data'} }[$other_id] }[3] . " ";
		}
	}
	return $self;
}

sub get_as_fastaDB{
	my ( $self, $genomeInterface, $bp_in_center, $no_N_regions ) =@_;
	my $chr_calc = $genomeInterface -> get_chr_calculator();
	my $fastaDB = stefans_libs::fastaDB->new();
	my ($array, $gbFiles, $seq, $chr, $start, $end);
	$bp_in_center = int($bp_in_center/2) if ( defined $bp_in_center);
	for ( my $i = 0; $i < $self->Lines(); $i ++) {
		($chr, $start, $end) = @{@{$self->{'data'}}[$i]}[0,1,2] ;
		$seq = '';
		if ( defined $bp_in_center ){
			$array = int(($start + $end)/2);
			$start = $array - $bp_in_center;
			$end = $array + $bp_in_center -1;
		}
		foreach ( $chr_calc->Chromosome_2_gbFile ( $chr, $start, $end ) ){
			$gbFiles->{@$_[0]} = $genomeInterface-> getGbfile_obj_for_id(@$_[0]) unless ( defined $gbFiles->{@$_[0]} );
			$seq .= $gbFiles->{@$_[0]}->Get_SubSeq( @$_[1,2] );
		}
		$array = @{@{$self->{'data'}}[$i]}[0].":".@{@{$self->{'data'}}[$i]}[1]."-".@{@{$self->{'data'}}[$i]}[2];
		if ( $no_N_regions ) {
			$fastaDB -> addEntry ( $array, $seq ) unless ( $seq =~ m/^N*$/ )
		}else {
			$fastaDB -> addEntry ( $array, $seq ) unless ( $seq eq '' );
		}
	}
	$gbFiles = undef;
	return $fastaDB;
}

sub plot_2_image {
	my ( $self, $hash ) = @_;
	## this data should be plotted as bars!
	my $yaxis =
	  axis->new( 'y', $hash->{'y_min'} + 1, $hash->{'y_max'} - 1, '', 'tiny' );
	$yaxis->min_value(0);
	$yaxis->max_value(1);
	$hash->{'chromosome'} = 'chr' . $hash->{'chromosome'}
	  unless ( $hash->{'chromosome'} =~ m/^chr/ );
	## I need a black frame! (?)
	if ( $self->{'plot_frame'} ) {
	$hash->{'im'}->rectangle(
		$hash->{xaxis}->resolveValue( $hash->{xaxis}->min_value() ),
		$yaxis->resolveValue(0) + 1,
		$hash->{xaxis}->resolveValue( $hash->{xaxis}->max_value() ),
		$yaxis->resolveValue(1) - 1,
		$hash->{'color_obj'}->{black},
	);
	}
	## and now I need to plot the bars......
	for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {

#print "I got the line '".join("'\t'", @{@{$self->{'data'}}[$i]})."' and I will compare that to '$hash->{'chromosome'}' ".$hash->{'xaxis'}->min_value()." ".$hash->{'xaxis'}->max_value()."\n";
		next
		  unless ( @{ @{ $self->{'data'} }[$i] }[0] eq $hash->{'chromosome'} );
		next
		  if (
			@{ @{ $self->{'data'} }[$i] }[2] <= $hash->{'xaxis'}->min_value() );
		next
		  if (
			@{ @{ $self->{'data'} }[$i] }[1] >= $hash->{'xaxis'}->max_value() );

		#print "And I plot the line\n";
		@{ @{ $self->{'data'} }[$i] }[1] = $hash->{'xaxis'}->min_value()
		  if (
			@{ @{ $self->{'data'} }[$i] }[1] < $hash->{'xaxis'}->min_value() );
		@{ @{ $self->{'data'} }[$i] }[2] = $hash->{'xaxis'}->max_value()
		  if (
			@{ @{ $self->{'data'} }[$i] }[2] > $hash->{'xaxis'}->max_value() );
		$hash->{'im'}->filledRectangle(
			$hash->{'xaxis'}->resolveValue( @{ @{ $self->{'data'} }[$i] }[1] ),
			$yaxis->resolveValue(0) +1,
			$hash->{'xaxis'}->resolveValue( @{ @{ $self->{'data'} }[$i] }[2] ),
			$yaxis->resolveValue(1) -1,
			$hash->{'color_obj'}->{ $hash->{'color'} },
		);
	}
	if ( defined $self->Title() ) {
		$hash->{'xaxis'}->{'font'}->plotStringAtY_leftLineEnd(
			$hash->{'im'},
			$self->Title(),
			$hash->{'xaxis'}->resolveValue( $hash->{'xaxis'}->min_value() ),
			$yaxis->resolveValue(1),
			$hash->{'color_obj'}->{'black'},
			'gbfeature',
			0
		);
	}
	##done
	return 1;
}


sub AsString{
	my ( $self, $subset ) = @_;
	my $str = '';
	my @default_values;
	my @line;
	if ( defined $subset ) {
		## 1 get the default values
		return $self->GetAsObject($subset)->AsString();
	}
	foreach my $description_line ( @{ $self->{'description'} } ) {
		$str .= "$description_line\n";
	}
	for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {
		$str .= join( "\t", @{ @{ $self->{'data'} }[$i] } ) . "\n";
	}
	return $str;
}

sub print_as_table {
	my ( $self,$outfile ) = @_;
	my @temp;
	@temp = split( "/", $outfile );
	pop(@temp);
	mkdir( join( "/", @temp ) ) unless ( -d join( "/", @temp ) );
	unless ( $outfile =~ m/xls$/ ) {
		$outfile .= ".xls";
	}
	open( OUT, " >$outfile" )
	  or Carp::confess(
		ref($self)
		  . "::print2file -> I can not create the outfile '$outfile'\n$!\n" );
		my $str = '';
	my @default_values;
	my @line;
	foreach my $description_line ( @{ $self->{'description'} } ) {
		$description_line =~ s/\n/\n#/g;
		$str .= "#$description_line\n";
	}
	$str .= '#' unless ( $self->{'no_doubble_cross'} );
	$str .= $self->SUPER::__header_as_string();
	@default_values = $self->getAllDefault_values();
	$self->Max_Header() = scalar( @{ $self->{'header'} } )
	  unless ( defined $self->Max_Header() );
	foreach my $data ( @{ $self->{'data'} } ) {
		@line = @$data;
		for ( my $i = 0 ; $i < $self->Max_Header() ; $i++ ) {
			unless ( defined $line[$i] ) {
				$line[$i] = $default_values[$i];
			}
			$line[$i] = '"' . $line[$i] . '"'
			  if ( $self->__col_format_is_string($i) );
		}
		$str .= join( $self->line_separator(), @line ) . "\n";
	}
	print OUT $str;
	close(OUT);
	print "all data written to '$outfile'\n";
	return $outfile;
}


sub print2file {
	my ( $self, $outfile, $as_is ) = @_;
	my @temp;
	@temp = split( "/", $outfile );
	pop(@temp);
	mkdir( join( "/", @temp ) ) unless ( -d join( "/", @temp ) );
	unless ( $as_is ){
	if ( $outfile =~ m/txt$/ ) {
		$outfile =~ s/txt$/bed/;
	}
	unless ( $outfile =~ m/bed$/ ) {
		$outfile .= ".bed";
	}
	}
	open( OUT, " >$outfile" )
	  or Carp::confess(
		ref($self)
		  . "::print2file -> I can not create the outfile '$outfile'\n$!\n" );
	print OUT $self->AsString();
	close(OUT);
	print "all data written to '$outfile'\n";
	return $outfile;
}

1;
