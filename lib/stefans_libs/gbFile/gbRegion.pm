package gbRegion;

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::gbFile::gbRegion

=head1 DESCRIPTION

A class to handle the genbank formated region information.

=head2 depends on

nothing

=head2 provides

L<getAsGB|"getAsGB">

L<Print|"Print">

L<Start|"Start">

L<End|"End">

L<ChangeRegion_Add|"ChangeRegion_Add">

L<ChangeRegion_Diff|"ChangeRegion_Diff">

L<Region|"Region">

L<Complement|"Complement">

L<getRegionForDrawing|"getRegionForDrawing">

L<Length|"Length">

L<getLengthForDrawing|"getLengthForDrawing">

L<ParseRegions|"ParseRegions">

L<Itemize_old|"Itemize_old">

=head1 METHODS

=head2 new

new returns a new object reference of the class gbRegion

=head3 atributes

[0]: genbank regionstring in the format "complement(join(3..5,7..9))"

=head3 method

The atribute[0] is given for parsing to L<Region,"Region">.

=head3 return value

a new gbregion object.

=cut

sub new {

	my ( $class, $region ) = @_;

	my $self = { items => [], regions => [] };

	bless( $self, "gbRegion" );
	$self->Region($region) unless ( ref($region) =~ m/\w/ );
	return $self;
}

=head2 getAsGB

=head3 atributes

[0]: region of interest start in basepairs

[1]: region of interest end in basepairs

=head3 method

return the genbank formated region if the file would start at atribute[0] and end at atribute[1].
If atribute[0] and atribute[1] are not defined atribute[0] is set to 0 and atribute[1] is set tp L<End|"End">.

=head3 return value

A genbank formated region string. 

=cut

sub Print {
	my ( $self, $start, $end ) = @_;
	$start = 0 unless ( defined $start );
	unless ( defined $end ) {
		$end = $self->End();
	}
	my $ret = $self->getAsGB( $start, $end );
	$ret =~ s/\s+//g;
	return $ret;
}

sub getSequence{
	my ( $self, $gbFile, $delta  ) = @_;
	$delta ||= 0;
	$delta += 1;
	return $gbFile->Get_SubSeq( $self->{start} -$delta, $self->{end} + $delta -2 );
}

sub getCoveredSequence{
	my ( $self, $gbFile, $delta ) = @_;
	$delta ||= 0;
	$delta += 1;
	return map {$gbFile->Get_SubSeq($_->{start} -$delta, $_->{end} + $delta-2 ) } @{$self->{regions}};
}

=head3 Print

=head3 atributes

[0]: region of interest start in basepairs

[1]: region of interest end in basepairs

=head3 method

This method parses all region items created by L<Itemize_old|"Itemize_old">.
If L<Complement|"Complement"> is defined the region becomes complement('region'),
if there are more than 1 parsed region pieces the region becomes join('region').
Each region item is used to create 'region'. From each start and end the value atribute[0] is removed to rescale the region if needed.

=head3 retrun value

A genbank formated region string.

=cut
sub fix_end{
	my ($self, $str) = @_;
	unless ($str=~ s/\.\.(\d+,)$/\.\.>$1/ ) {
		warn "The fix_end did not work on the string $str\n" if ( $self->{'debug'});
	};
	return $str;
}

sub getAsGB {
	my ( $self, $start, $end ) = @_;
	my ( $regions, @print, $now_start, $now_end, $problematic, $i, $add );
	
	$start ||= 0;
	$end ||= 1e+10;
	my $gbTab = '                     ';
	
	@print   = ($gbTab); ## has to be removed afterward, but is necessary for the formating
	$regions = $self->{regions};
	return "1..2" unless ( ref($regions) eq "ARRAY" );
	if ( defined $self->Complement() ) {
		$print[0] .= $self->Complement()."(";
	}
	if ( defined $self->Join() ) {
		$print[0] .= "join(";
	}
	$i = 0;
	
	foreach my $region ( sort {$a->{start} <=> $b->{start}} @$regions ) {
		if ( $region->{tag} eq "normal" ) {
			$now_start = $region->{start} - $start;
			$now_end   = $region->{end} - $start;
			if ( $now_start < 1 ) { ## fängt vor der zu schreibenden Region an!
				if ( $region->{end} - $start < 1 ){## && hört auch vorher auf -> weg damit!
					$print[$#print] = $self->fix_end($print[$#print]);
					next;
				}                 
				$now_start = "1";
				$region->{tag_start} = "<";
			}
			if ( $region->{start} > $end ){## fängt nach der zu schreibenden Region an -> weg damit!
				$print[$#print] = $self->fix_end($print[$#print]);
				next; 
			} 
			if ( $region->{end} > $end )
			{ ## hört nach dem zu schreibenden Bereich auf, fängt aber vorher an!
				$now_end = $end;
				$region->{tag_end} = ">";
			}
			
			$problematic = 1 if ( $now_start > $now_end );
			if ( defined $start ) {
				$add = "$region->{tag_start}$now_start..$region->{tag_end}$now_end,"
			}else {
				$add = "$region->{tag_start}$region->{start}..$region->{tag_end}$region->{end},"
			}
		}
		if ( $region->{tag} eq "single" ) {
			$now_start = $region->{start} - $start;
			if ( $now_start < 1 or $region->{start} > $end ){
				next;
			}
			$add = "$now_start,";
		}
		if ( length($print[$#print].$add) > 79 ) {
			push ( @print, $gbTab.$add);
		}else {
			$print[$#print] .= $add;
		}
		$i ++;
	}
	my $print = join("\n", @print);
	chop $print;
	$print .= ")" if ( $self->Complement() );
	$print .= ")" if ( $self->Join() );
	
	return undef if ( $i ==0 );
	
	if ( defined $problematic ) {
		my @array;
		$self->{regions} = undef;
		$self->{items}   = \@array;
		$self->Region($print);
		return $self->Print( $start, $end );
	}
	$print =~ s/^$gbTab//;
	return $print;
}

sub byRegionStart {
	return $a->{start} <=> $b->{start};
}

=head2 Start

Verry simple wrapper for the overall start[bp] of this region.

=cut

sub Start {
	my ( $self, $start ) = @_;
	$self->{start} = $start if ( defined $start );

	return $self->{start};
	if ( $self->{'end'} > $self->{'start'} ) {
		return $self->{start};
	}
	return $self->{end};
}

=head2 End

Very simple wrapper for the overall end[bp] of this region.

=cut

sub End {
	my ( $self, $end ) = @_;
	$self->{end} = $end if ( defined $end );
	return $self->{end};
	if ( $self->{'end'} > $self->{'start'} ) {
		return $self->{end};
	}
	else {
		return $self->{start};
	}
}

=head2 ExprStart

Simple wrapper for the start[bp] in transcription orientation of this region.

=cut

sub ExprStart {
	my ($self) = @_;
	return $self->Start unless ( defined $self->Complement() );
	return $self->End();
}

=head2 ExprEnd

Very simple wrapper for the end[bp] in transcription orientation of this region.

=cut

sub ExprEnd {
	my ($self) = @_;
	return $self->End() unless ( defined $self->Complement() );
	return $self->Start();
}

=head2 ChangeRegion_Add

=head3 atributes

[0]: basepairs to shift the region

=head3 method

Add atribute[0] to each region entry.

=cut

sub ChangeRegion_Add {

	my ( $self, $bp_to_add ) = @_;
	return 0 if ( !( defined $bp_to_add ) || $bp_to_add == 0 );
	my ( $regions, $print );
	$regions = $self->{regions};
	foreach my $region (@$regions) {
		$region->{start} += $bp_to_add;
		$region->{end}   += $bp_to_add;
	}
	$self->Region( $self->Print( 0, $self->End() + $bp_to_add * 2 ) )
	  if ( $bp_to_add > 0 );
	$self->Region( $self->Print( 0, $self->End() ) ) if ( $bp_to_add < 0 );
	return 1;
}

=head2 ChangeRegion_Complement

=head3 atributes

[0]: the new start position -> absolutely needed!

=head3 method

substract the aold position values vrom the new start value to gain the new positions.
Afterwards the region Information is sorted and newly inserted.

=cut

sub ChangeRegion_Complement {
	my ( $self, $newStart ) = @_;
	die
"gbRegion->ChangeRegion_Complement absolutely needs to know the position of the new start!\n"
	  unless ( defined $newStart );
	my ( @new_regions, $regions, $print, $temp_start );
	$regions = $self->{regions};
	for ( my $i = @$regions - 1 ; $i >= 0 ; $i-- ) {
		$temp_start            = $newStart - @$regions[$i]->{end};
		@$regions[$i]->{end}   = $newStart - @$regions[$i]->{start};
		@$regions[$i]->{start} = $temp_start;
	}
	for ( my $i = 0 ; $i < @$regions ; $i++ ) {
		$new_regions[$i] = @$regions[ @$regions - ( $i + 1 ) ];
	}
	$self->{regions} = \@new_regions;
	$self->Region( $self->Print( 0, $self->End() ) );
	return 1;
}

=head2 ChangeRegion_Diff

Complex adjustment of the gbRegion used by L<sequence_modification::blastLine/"AddFeature">
if the NCBI BLAST result matches to the reverse strand.

=head3 atributes

[0]: end of the the BLAST hit on the query sequence

[0]: end of the search sequence in the BLAST hit

=head3 method 

Adjust the region to correctly place a feature found originally on a blast database file to the query sequence.

=cut

sub ChangeRegion_Diff {
	my ( $self, $q_end, $s_end ) = @_;
	my ( $regions, $print );
	$regions = $self->{regions};
	foreach my $region (@$regions) {
		$region->{start} = $q_end - ( $region->{start} - $s_end );
		$region->{end} = $q_end - ( $region->{end} - $s_end );
	}
	$self->Region( $self->Print( 0, 1e99 ) );
	return 1;
}

=head2 Region

=head3 atributes

[0]: a genbank formated region string or the undefined

=head3 method

Return the parsed regions if atribute[0] is not defined

Here only the complement and join tags of the genbank formated region string are evaluated.
The region information is parsed in L<ParseRegions|"ParseRegions">.

=head3 return value

A reference to the  parsed regions with the structure 
[ { start =>int, end => int, start_tag => '<' or undef, end_tag => '>' or undef } ] is returned.
 
=cut

sub Region {

	my ( $self, $region ) = @_;
	#print "We analyze the region $region\n";
	return $self->{regions} unless ( defined $region);
	if ( $region =~ m/^\d+$/ ) {
		print "we got the region part $region!\n";
	}
	my (
		@region, $items, $temp, $regions, $key,
		$value,  $start, $end,  @start,   @end
	);

	return $self->{regions} unless ( defined $region );

	$self->{items} = $self->{regions} = undef;
	chomp($region);
	@region = split( "", $region );
	$self->Itemize( \@region, 0, 0 );
	$items = $self->{items};
	die ref($self), ":Region -> we got no items for region string '$region'\n"
	  unless ( defined @$items[0] );
	if ( $region =~ m/complement/ ) {
		$self->Complement("complement");
	}
	if ( $region =~ m/join/ ) {
		$self->Join("join");
	}
	foreach $temp (@$items) {
		if ( $temp =~ m/\d+\.?\.?/ ) {
			( $temp, $start, $end ) = $self->ParseRegions($temp);
			push( @start, $start );
			push( @end,   $end );
		}
	}
	( $start, $end ) = $self->findStartEnd( \@start, \@end );
	$self->Start($start);
	$self->End($end);

	return $self->{regions};
}

=head2 Complement

Simple information class for the complement state of this region.

=head3 atributes

[0]: The complement state is set to 'complement' if this value is defined.

=head3 return value

'complement' if the region is matching to the reverse strand or undef if not.

=cut

sub Complement {
	my ( $self, $comp ) = @_;
	$self->{'complement'} = "complement" if ( defined $comp );
	return $self->{'complement'};
}

sub Join {
	my ( $self, $comp ) = @_;
	$self->{'join'} = $comp if ( defined $comp );
	return $self->{'join'};
}


=head2 Length

return the overall lenth of this region as defined by End() - Start().

=cut

sub Length {
	my ($self) = @_;
	return $self->End() - $self->Start();
}

=head2 getLengthForDrawing

Return a drawable object [ {start => self->Start, end => self->End()} ]

=cut

sub getLengthForDrawing {
	my ($self) = @_;

	#    print "gbRegion::getLengthForDrawing\n";
	#    print "start => ",$self->Start(),", end => ",$self->End(),"\n",
	my @return;
	push( @return, { start => $self->Start(), end => $self->End() } );
	return \@return;
}

=head2 ParseRegions

=head3 atributes

[0]: a genbank formated region string stripped from the complement and join tags

=head3 method
 
ParseRegions splitts up the atribute[0] at ',' and uses L<Itemize_old|"Itemize_old"> to interprete the pieces.

=head3 return value

ParseRegions a reference to the list of parsed region pieces, the overall start of the region and the overall end of the region.

=cut

sub ParseRegions {
	my ( $self, $regions ) = @_;
	my ( $return, $temp, @starts, @ends, @return, $start, $end );

	$return  = $self->{regions} ||= [];
	
	push ( @$return, map{ $self->Itemize_old($_)} split( ",", $regions ) );
	$self->{'start'} = @$return[0] ->{'start'};
	$self->{'end'}   = @$return[$#return] ->{'end'};
	$self->{'end'} ||= @$return[$#return] ->{'start'};
	
	return $return, $self->{'start'}, $self->{'end'};
}

sub findStartEnd {

	my ( $self, $start_r, $end_r ) = @_;
	my ( @values, @starts, @ends, $start, $end, $temp );

	push( @values, @$start_r );
	push( @values, @$end_r );

	return undef if ( join( "", @values ) eq "" );
	for (my $i = 0; $i < @values; $i ++ ){
		print Carp::cluck()." Value $i of ".scalar(@values)." is not defined\n" unless ( defined $values[$i] );
	} 
	@starts = sort { $a <=> $b } @values;
	@ends   = sort { $b <=> $a } @values;
	foreach $temp (@starts) {
		$start = $temp;
		last if ( defined $start );
	}
	foreach $temp (@ends) {
		$end = $temp;
		last if ( defined $end );
	}
	$self->Start($start);
	$self->End($end);
	return $start, $end;
}

sub numeric {
	return $a <=> $b;
}

sub anti_numeric {
	return $b <=> $a;
}

sub ScanForBacket {
	my ( $self, $region, $a ) = @_;

	#    print "ScanForBacket = ", join ("",@$region),"\n";
	my ( $open, $close, @values, $temp );
	$open  = 1;
	$close = 0;
	while ( $open != $close ) {
		$temp = @$region[ $a++ ];
		$open++  if ( $temp eq "(" );
		$close++ if ( $temp eq ")" );
		push( @values, $temp );
	}
	return $a, join( "", @values );
}

sub Itemize {
	my ( $self, $region, $a, $i ) = @_;
	my ( $actualItem, @items );
	$a = 0 unless ( defined $a );
	return 0 if ( @$region <= $a );

	$actualItem = '';

	for ( ; $a < @$region ; $a++ ) {
		if ( @$region[$a] eq ')' ) {    ## neuer Teil
			push( @items, $actualItem );
			$actualItem = '';
		}
		unless ( @$region[$a] eq " " ) {
			$actualItem .= @$region[$a];
		}
		else {
			## no harm here - the char is introduced during the reading of the region
			next;
		}
		if ( @$region[$a] eq '(' ) {    ## neuer Teil!
			push( @items, $actualItem );
			$actualItem = '';
		}

	}
	push( @items, $actualItem ) if ( defined $actualItem );
	$self->{items} = \@items;
	return $i;
}

=head2 Itemize_old

=head3 atributes

[0]: a region pice in the format <?\d+..\d+>? , \d+ or \d+.\d+

=head3 return value

A reference to a hash with the structure { tag => one of [normal,between,,smear] , start => start in bp, end => end in bp,
tag_end => one of [>,undef], tag_start => one of [<,undef] }

=cut

sub Itemize_old {
	my ( $self, $region, $i ) = @_;

	my ( $start, $end, $return );
	$self->Complement( 'complement' ) if ( $region =~m/complement/);
	$self->Join('join') if ( $region =~ m/join/ );
	
	if ( $region =~ m/([<>]?)(\d+)\.\.([<>]?)(\d+)/ ) {
		$return = {
			tag       => 'normal',
			start     => $2,
			end       => $4,
			tag_start => $1,
			tag_end   => $3
		  };
	}
	elsif ( $region =~ m/(\d+)\.(\d+)/ ) {
		$return = {
			tag       => 'smear',
			start     => $1,
			end       => $2,
			tag_start => "",
			tag_end   => ""
		  }
		  unless ( $region =~ m/[<>]/ );
	}
	elsif ( $region =~ m/(\d+)\^(\d+)/ ) {
		$return = {
			tag       => 'between',
			start     => $1,
			end       => $2,
			tag_start => "",
			tag_end   => ""
		};
	}
	elsif ( !defined $return && $region =~ m/^(\d+)$/ ) {
		print "we got the single tag! $region\n";
		$return =
		  { tag => "single", start => $1, tag_start => "", tag_end => "" };
	}
	unless ( defined $return ) {
		Carp::confess( "keine Verwendung für $region\n" );
		return undef;
	}
	return $return unless ( defined $return->{end} );

	if ( $return->{start} > $return->{end} ) {
		$start           = $return->{end};
		$return->{end}   = $return->{start};
		$return->{start} = $start;
		$self->Complement("complement");
	}
	return $return;
}

sub matchWithRegion {
	my ( $self, $start, $end, $delta ) = @_;
	my $regions = $self->{regions};
	foreach my $region (@$regions) {
		return 1 == 1
		  if ( $region->{start} - $delta < $end
			&& $region->{end} + $delta > $start );
	}
	return 1 == 0;
}

1;
