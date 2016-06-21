package gbFeature;

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

use stefans_libs::gbFile::gbRegion;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::gbFile::gbFeature

=head1 DESCRIPTION

A object of this class represents one genbank formated feature.

=head2 Depends on

L<::gbFile::gbRegion>

=head2 Provides

L<ChangeRegion_Add|"ChangeRegion_Add">

L<ChangeRegion_Diff|"ChangeRegion_Diff">

L<Region|"Region">

L<Add_noGB_Info|"Add_noGB_Info">

L<IsIg_gene|"IsIg_gene">

L<forTable|"forTable">

L<Tag|"Tag">

L<IsComplement|"IsComplement">

L<getRegionForDrawing|"getRegionForDrawing">

L<Match|"Match">

L<MatchesWith|"MatchesWith">

L<getLengthForDrawing|"getLengthForDrawing">

L<getLength|"getLength">

L<Start|"Start">

L<End|"End">

L<getAsGB|"getAsGB">

L<AddInfo|"AddInfo">

L<Name|"Name">

L<Sequence|"Sequence">

=head1 METHODS

=head2 new

=head3 atributes

[0]: the tag of this feature (gene, mRNA, ...)

[1]: the genbank formated region ( for example 'complement(join(3..7,19..30,40..440))' )

=head3 retrun values

A object of the class gbFeature

=cut

sub new {
	my ( $class, $tag, $region ) = @_;

	die
"New gbFeature needs a tag info and a region! ( '$class', '$tag', '$region')\n"
	  unless ( @_ == 3 );

	my ( $Region, %match, %addInfo );

	#  print "new gbFeature -> New region = $region\n";
	#    print "new feature $tag\n";
	if ( ref($region) eq "gbRegion" ) {
		$Region = $region;
	}
	else {
		$Region = gbRegion->new($region);
	}

	my $self = {
		seqeuce     => undef,
		seqLength   => undef,
		region      => $Region,
		tag         => $tag,
		match       => \%match,
		addInfo     => \%addInfo,
		information => undef
	};

	if ( length( $self->{'tag'} ) > 14 ) {
		$self->{'tag'} =
		  substr( length( $self->{'tag'} ), length( $self->{'tag'} ) - 14, 14 );
	}
	bless( $self, "gbFeature" );

	#    $self->Infos($infoStack);
	#    $self->Sequence($sequence);

	return $self;
}

sub isMultilineStart {
	my ( $self, $string, $qchars ) = @_;

	my ( $qL, $qR );    # left and right quote chars, like ' or ()
	my ($quote_level);  # current quote level
	my ( $myValue, $temp );

	( $qL, $qR ) = split( "", $qchars );

	$myValue = $quote_level = 0;
	my @string = split( "", $string );
	$temp = @string;
	foreach $temp (@string) {
		if ( $temp eq $qL ) {
			$myValue++;
		}
		if ( $temp eq $qR && !( $qR eq '"' ) ) {
			$myValue--;
		}
	}
	if ( $qchars =~ m/"/ ) {    #"
		return 0 if ( $myValue / 2 == int( $myValue / 2 ) );
		return 1;
	}
	return 0 if ( $myValue == 0 );
	return 1;
}

sub parseFromString {
	my ( $self, $string ) = @_;

	return 0 unless ( $string =~ m/\w/ );

	my ( $line, @string, $lineNr );
	@string = ( split( "\n", $string ) );
	$self->{information} = {};
	$self->{region}      = undef;
	for ( my $i = 0 ; $i < @string ; $i++ ) {
		$line   = $string[$i];
		$lineNr = $i;
		if (   $line =~ m/\d+\.\.\d+/
			&& $self->isMultilineStart( $line, "()" ) == 1 )
		{
			for ( $i++ ; $i < @string ; $i++ ) {
				$string[$i] =~ m/                     (.*)$/;
				warn "no match to pattern in line $line\n"
				  unless ( defined $1 );
				$line = "$line $1";
				last
				  if ( $self->isMultilineStart( $line, "()" ) == 0
					|| $string[$i] eq "" );
			}

		}
		elsif ( $self->isMultilineStart( $line, '""' ) == 1 ) {
			for ( $i++ ; $i < @string ; $i++ ) {

				#                chop $_;
				$string[$i] =~ m/                     (.*)$/;
				$line = "$line $1";

				#                print "\tfeature Tag\t";
				last
				  if ( $self->isMultilineStart( $line, '""' ) == 0
					|| $string[$i] eq "" );
			}
		}

		#                ######
		if ( $lineNr == 0 ) {
			unless ( $line =~ m/^ +(\w+) +(.+)/ ) {
				warn "no gbFeature string\n$string\n$!\n";
				return 0;
			}
			$self->{tag}    = $1;
			$self->{region} = gbRegion->new($2);
			next;
		}
		if ( $line =~ m/ *.(\w*)=(['"].+['"])/ ) {
			$self->AddInfo( $1, $2 );
			next;

		}
		if ( $line =~ m/ *i.(\w+)=(.+)/ ) {
			$self->AddInfo( $1, $2 );
			next;
		}
	}
	return $self;
}

=head2 ChangeRegion_Add

See L<gbFile::gbRegion/"ChangeRegion_Add">

=cut

sub ChangeRegion_Add {
	my ( $self, $bp_to_add ) = @_;

	return unless ( defined $bp_to_add );

#print "gbFeature ChangeRegion_Add $bp_to_add Region Vorher = ",$self->{region}->Print(0,1e99),"\n" ;
	$self->{region}->ChangeRegion_Add($bp_to_add);

	#print "Nacher = ",$self->{region}->Print(0,1e99),"\n";
	return $self;
}

=head2 ChangeRegion_Complement

See L<gbFile::gbRegion/"ChangeRegion_Complement">

=cut

sub ChangeRegion_Complement {

	my ( $self, $end ) = @_;
	$self->{region}->ChangeRegion_Complement($end);
	return $self;
}

=head2 ChangeRegion_Diff

See L<gbFile::gbRegion/"ChangeRegion_Diff">

=cut

sub ChangeRegion_Diff {
	my ( $self, $q_end, $s_end ) = @_;
	die "ChangeRegion_Diff needs \$q_end, \$s_end ($q_end, $s_end)\n"
	  unless ( defined $q_end || defined $s_end );
	return $self->{region}->ChangeRegion_Diff( $q_end, $s_end );
}

=head2 Region

returns the gbregion entry.

=cut

sub Region {
	my ($self) = @_;
	return $self->{region};
}

=head2 Add_noGB_Info 

=head3 atributes

[0]: key to the information

[1]: the information

=head3 retrun value

a reference of a hash with the structure { key => 'information' }

=cut

sub Add_noGB_Info {
	my ( $self, $tag, $value ) = @_;
	## This Info is not in genbank format and will not pe printed!
	if ( defined $tag && defined $value ) {
		$self->{addInfo}->{$tag} = $value;
	}
	return $self->{addInfo};
}

=head2 IsIg_gene

This method returns 'C', 'D', 'J' or 'V' if the feature tag matches 'D_', 'J_', 'C_' or 'V_'.
Default is the undefined value.

=cut

sub IsIg_gene {
	my ($self) = @_;
	my ( $tag, $name, $t );
	$name = $self->Name();
	$tag  = $self->Tag();

	#    print "name = $name tag = $tag\n";
	if ( $tag =~ m/D_/ ) {
		return "D";
	}
	if ( $tag =~ m/J_/ ) {
		return "J";
	}
	if ( $tag =~ m/C_/ ) {
		return "C";
	}
	if ( $tag =~ m/V_/ ) {
		return "V";
	}
	return undef;
}

=head2 forTable

This method returns [ start[bp], end[bp], $tag, $name, "-", "-" ] for most of the feature tags.
If the feature tag eq 'D_segment', 'J_segment', 'C_region' or 'C_segment'  the name is set to  'IgHD', 'IgHJ' or 'IgHC'.
If the feature represents a V_segment the retrun array is set to 
[ start[bp], end[bp], tag, name, "IgHV", "V'family number'" ]

=cut

sub forTable {
	my ($self) = @_;

	## Daten als  "GB feature bp_start", "GB feature bp_end","tag", "description", "Ig -type", "Ig-family" ausgeben
	my ( $name, $tag );

	$name = $self->Name();
	$tag  = $self->Tag();

	## Identification by Tag
	unless ( $self->IsIg_gene() ) {    #$tag eq "enhancer" ) {
		return $self->Start(), $self->End(), $tag, $name, "-", "-";
	}

	if ( $tag eq "D_segment" ) {

		#     print "D_segment name = $name;\n";
		$name =~ m/(IGHD)(.*?)\*/;

  #     print "D_segment after match against /IGH(D.*).*?=\*/  name = $name;\n";
		return $self->Start(), $self->End(), $tag, $name, $1, "D$2";
	}
	if ( $tag eq "J_segment" ) {
		$name =~ m/(IGHJ)(\d)/;
		return $self->Start(), $self->End(), $tag, $name, $1, "J$2";
	}
	if ( $tag eq "C_region" || $tag eq "C_segment" ) {
		$name =~ m/(IGH\w)/;
		return $self->Start(), $self->End(), $tag, $name, $1, "-";
	}

	## Jetzt kann es nur noch eine V_region sein falls es überhaupt hier Betrachtung findet!
	## Alle V_regionen die nach IMGT benannt sind haben den Schlüssel V\d[1-2] als Identificator der Familie!
	## Farben wurden in Analogie zu dem paper "Johnston,...,Corcoran Ig Heavy Chain V Region" gewählt

	if ( $name =~ m/V1/ || $name =~ m/J558/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V1";
	}
	if ( $name =~ m/V2/ || $name =~ m/Q52/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V2";
	}
	if ( $name =~ m/V3/ || $name =~ m/36-60/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V3";
	}
	if ( $name =~ m/V4/ || $name =~ m/X24/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V4";
	}
	if ( $name =~ m/V5/ || $name =~ m/7183/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V5";
	}
	if ( $name =~ m/V6/ || $name =~ m/J606/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V6";
	}
	if ( $name =~ m/V7/ || $name =~ m/S107/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V7";
	}
	if ( $name =~ m/V8/ || $name =~ m/3609/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V8";
	}
	if ( $name =~ m/V9/ || $name =~ m/VGAM3\.8/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V9";
	}
	if ( $name =~ m/V10/ || $name =~ m/VH10/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V10";
	}
	if ( $name =~ m/V11/ || $name =~ m/VH11/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V11";
	}
	if ( $name =~ m/V12/ || $name =~ m/VH12/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V12";
	}
	if ( $name =~ m/V13/ || $name =~ m/3609N/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V13";
	}
	if ( $name =~ m/V14/ || $name =~ m/SM7/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V14";
	}
	if ( $name =~ m/V15/ || $name =~ m/VH15/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "V15";
	}
	if ( $name =~ m/PG/ ) {
		return $self->Start(), $self->End(), $tag, $name, "IgHV", "PG";
	}

	## Das war nichts Ig Spezifisches!

	return $self->Start(), $self->End(), $tag, $name, "-", "-";
}

#sub Lable{
#    my ( $self) = @_;
#    my @temp;
#    push(@temp, $self->Tag());
#    push(@temp, $self->Name());
#    return join(" ", @temp);
#}

=head2 Tag

returns the tag of this feature

=cut

sub Tag {
	my ( $self, $tag ) = @_;
	$self->{tag} = $tag if ( defined $tag );
	return $self->{tag};
}

=head2 IsComplement

returns 'complement' if this feature matches to the complement strain or the undefined value.

=cut

sub IsComplement {
	my ( $self, $complement ) = @_;
	return $self->{region}->Complement($complement);
}

=head2 getRegionForDrawing

See L<gbFile::gbRegion/"getRegionForDrawing">

=cut

sub getRegionForDrawing {
	my ($self) = @_;

   #   print "gbFeature:: getRegionForDrawing feature atg = ",$self->Tag(),"\n";
	return $self->{region}->Region();

	#    return $self->{region}->getRegionForDrawing();
}

=head2 getForDrawing

=head3 return values

Returns a refernect to a array with the structure ( { start => { lower = mean = upper = <int> }, end => { lower = upper = mean = <int>} } )

=cut

sub getAsPlottable {
	my ($self) = @_;

	my ( $array, $entry, @return, $i, $tag );

	$tag = $self->Name();
	$tag = "$tag$self->{tag}";

	$array = $self->{region}->Region();
	$i     = 0;
	foreach $entry (@$array) {
		my ( $hash, $start, $end );
		$start = {
			mean  => $entry->{start},
			upper => $entry->{start},
			lower => $entry->{start},
			min   => $entry->{start}
		};
		$end = {
			mean  => $entry->{end},
			upper => $entry->{end},
			lower => $entry->{end},
			max   => $entry->{end}
		};
		$hash = { start => $start, end => $end, gbFeatureTag => $tag };
		$return[ $i++ ] = $hash;
	}
	return \@return;
}

=head2 Match

=head3 atributes

[0]: start of the region of interest in basepairs

[1]: end of the region of interest in basepairs

[2]: additional space in basepairs

=head3 return value

return ($start < $self->End() + $delta) && ($end > $self->Start() - $delta)

=cut

sub Match {
	my ( $self, $start, $end, $delta ) = @_;
	return $self->{region}->matchWithRegion( $start, $end, $delta );
}

=head2 MatchesWith

MatchesWith is the interface to a internal counter.

=head3 atributes

[0]: string of the matching feature

=head3 method

the internal counter with the key atribute[0] is raied by one.

=cut

sub MatchesWith {
	my ( $self, $string ) = @_;
	if ( defined $string ) {
		$self->{match}->{$string} = 0
		  unless ( defined $self->{match}->{$string} );
		$self->{match}->{$string}++;
	}
	return $self->{match};
}

=head2 getLengthForDrawing

See L<gbFile::gbregion//"getLengthForDrawing">

=cut

sub getLengthForDrawing {
	my ($self) = @_;
	return $self->{region}->getLengthForDrawing();
}

=head2 getLength

See L<gbFile::gbRegion/"Length">

=cut

sub getLength {
	my ($self) = @_;
	return $self->{region}->Length();
}

#sub Infos {
#
#    my ( $self, $infoStack ) = @_;
#    return $self->{information} unless ( defined $infoStack );
#
#}

=head2 ExprStart

See L<gbFile::gbRegion/"ExprStart">

=cut

sub ExprStart {
	my ($self) = @_;
	return $self->{region}->ExprStart() if ( defined $self->{region} );
	return undef;
}

=head2 ExprEnd

See L<gbFile::gbRegion/"ExprEnd">

=cut

sub ExprEnd {
	my ($self) = @_;
	return $self->{region}->ExprEnd() if ( defined $self->{region} );
	return undef;
}

=head2 Start

See L<gbFile::gbRegion/"Start">

=cut

sub Start {
	my ($self) = @_;
	return $self->{region}->Start() if ( defined $self->{region} );
	return undef;
}

=head2 End

See L<gbFile::gbRegion/"End">

=cut

sub End {
	my ($self) = @_;
	return $self->{region}->End() if ( defined $self->{region} );
	return undef;
}

sub getPromoterRegion {
	my ( $self, $upstream_add, $downstream_add ) = @_;
	if ( $self->IsComplement() ) {
		return ( $self->End() - $downstream_add ),
		  ( $self->End() + $upstream_add );
	}
	else {
		return $self->Start() - $upstream_add, $self->Start() + $downstream_add;
	}
	return undef;
}

=head2 getAsGB

=head3 atributes

[0]: start in basepairs

[1]: end in basepairs

=head3 return value

Returns the text string representing this gbFeature in genbank format

=cut

sub getAsGB {
	my ( $self, $start, $end ) = @_;

	my (
		$line,        $line_i, @range, $temp, $templine,
		$information, $first,  $i,     @lineArray
	);

	$line = "     ";
	$line = "$line$self->{tag}";
	for ( my $i = 5 + length( $self->{tag} ) ; $i < 21 ; $i++ ) {
		$line = "$line ";
	}
	$temp = $self->{region}->getAsGB( $start, $end );
	return undef unless ( defined $temp );
	$line = "$line$temp";

	#  return $line unless ( length($line) > 80 );
	$line_i = 1;
	if ( length($line) > $line_i * 79 ) {
		@range = split( ",", $line );
		$line = "";
		foreach $temp (@range) {
			next if ( $temp eq '1' );
			$templine = "$line$temp,";
			if ( length($templine) > $line_i * 79 ) {
				$line_i++;
				$line = "$line\n                     $temp,";
			}
			else { $line = "$line$temp,"; }
		}
		chop $line;
		chomp $line;
	}
	push( @lineArray, $line );

	### Die erste zeile ist geschafft!!
	while ( my ( $tag, $info ) = each %{ $self->INFORMATION() } ) {
		if ( $info =~ m/ARRAY/ ) {
			foreach my $realInfo (@$info) {
				push( @lineArray, $self->_feature2string( $tag, $realInfo ) );
			}
		}
		else {
			push( @lineArray, $self->_feature2string( $tag, $info ) );

		}
	}

	foreach my $string ( keys %{ $self->{match} } ) {
		$line =
		  $self->_feature2string( undef, $string,
			"                     /note=\"match mode " );
		$temp = chop $line;
		$line = "$line$temp" unless ( $temp eq '"' );
		$line = "$line matches $information->{$string} times\"";
		push( @lineArray, $line ) if ( $line =~ m/\w/ );
	}
	$line = join( "\n", @lineArray );
	return "$line\n";
}

sub Info_AsString {
	my ($self) = @_;
	my $str = '';
	foreach my $tag ( keys %{ $self->INFORMATION() } ) {
		$str .= "$tag ";
		foreach my $string ( @{ $self->INFORMATION()->{$tag} } ) {
			$str .= ", $string";
		}
		$str .= "; ";
	}
	return $str;
}

sub INFORMATION {
	my ($self) = @_;
	unless ( ref( $self->{'information'} ) eq "HASH" ) {
		return {};
	}
	return $self->{'information'};
}

sub _feature2string {
	my ( $self, $tag, $info, $alternativeTagString ) = @_;

	my (
		$temp2, $temp,     $first, $line_i, $line,
		@range, $tempLine, @temp,  $splitString
	);
	$info   = "\"$info\"" unless ( $info =~ m/^"/ );             #"
	$line   = "                     /$tag=";
	$line_i = 1;
	$first  = 1;
	@range  = split( " ", $info );
	@range  = split( "", $info ) if ( $tag eq "translation" );
	for ( my $i = 0 ; $i < @range ; $i++ ) {
		$temp        = $range[$i];
		$splitString = " ";
		$splitString = "" if ( $i == 0 );

		if ( length($temp) > 20 ) {
			@temp = split( "", $temp );
			foreach my $string2add (@temp) {
				( $line, $line_i ) =
				  $self->_add2multiLineString( $line, $string2add, "",
					$line_i );
			}
		}
		else {
			( $line, $line_i ) =
			  $self->_add2multiLineString( $line, $temp, $splitString,
				$line_i );
		}
	}
	return $line;
}

sub _add2multiLineString {
	my ( $self, $lines, $string2add, $separation, $lineCount ) = @_;
	my ($tempLine);
	$tempLine = "$lines$separation$string2add";
	if ( length($tempLine) > $lineCount * 80 - 1 ) {
		$lineCount++;
		$line = "$line\n                     $string2add";
	}
	else {
		$line = $tempLine;
	}
	return $line, $lineCount;
}

=head2 AddInfo

=head3 atributes

[0]: feature information 'tag'

[1]: feture information 'value'

=head3 method

Add feature information to this feature.

=cut

sub AddInfo {
	my ( $self, $tag, $info ) = @_;

	unless ( defined $self->{information} ) {
		$self->{information} = {};
	}
	$self->{information}->{$tag} = []
	  unless ( defined $self->{information}->{$tag} );
	push( @{ $self->{information}->{$tag} }, $info ) if ( defined $info );
	return $self->{information}->{$tag};
}

sub DropInfo {
	my ( $self, $tag, $info ) = @_;

	unless ( defined $self->{information} ) {
		$self->{information} = {};
	}
	unless ( defined $info ) {
		delete $self->{information}->{$tag}
		  if ( ref( $self->{information}->{$tag} ) eq "ARRAY" );
	}
	else {
		for ( my $i = 0 ; $i < @{ $self->{information}->{$tag} } ; $i++ ) {
			if ( @{ $self->{information}->{$tag} }[$i] eq $info ) {
				splice( @{ $self->{information}->{$tag} }, $i, 1 );
				last;
			}
		}
	}

	return 1;
}

sub Info_for_Tag {
	my ( $self, $tag ) = @_;
	return $self->AddInfo($tag);
}

=head2 selectValue_from_tag_str

This function can be used to extract ONE information part from ONE gbFeature entry.
The function generates a string from the gbFeature info tag and returns the frst 'captures' substr from that. 
If anything goes wrong, you can check the gbFeature-S{error} string. If that one is not defined there is no
value in that gbFeature, that could match your query.

=head3 Atributes

[0] the gbFeature tag (e.g. note, gene, ...)

[1] the matchingString (e.g. 'median probability for a nucleosome over this region = ([\d\.]+)' ) 

=cut

sub selectValue_from_tag_str {
	my ( $self, $tag, $matchingStr ) = @_;
	$self->{error} = '';
	unless ( $matchingStr =~ m/\(/ && $matchingStr =~ m/\)/ ) {
		$self->{error} .=
		  ref($self)
		  . ":selectValue_from_tag_str -> the selection sting '$matchingStr' does not contain a retrieval tag ()!\n";
	}
	my ( $feature_str, $return );
	$feature_str = $self->_getFeatureStr($tag);
	warn $self->{error} unless ( defined $feature_str );
	return $1 if ( $feature_str =~ m/$matchingStr/ );
	return undef;
}

sub _getFeatureStr {
	my ( $self, $tag ) = @_;
	unless ( defined $tag ) {
		$self->{error} .=
		  ref($self)
		  . ":_getFeatureStr -> we did not get a tag information - therefore we do not know which string you want!\n";
	}
	unless ( ref( $self->{information}->{$tag} ) eq "ARRAY" ) {
		$self->{error} .=
		  ref($self)
		  . ":_getFeatureStr -> we do not have information about the tag '$tag'!\n";
		return undef;
	}
	else {
		my $return;
		foreach ( @{ $self->{information}->{$tag} } ) {
			$return .= " $_";
		}
		return $return;
	}
	return undef;
}

sub removeInfo {
	my ( $self, $tag ) = @_;
	return unless ( defined $self->{information} );
	$self->{information}->{$tag} = undef
	  if ( defined $self->{information}->{$tag} );
	return;
}

=head2 Name

=head3 atributes 

[0]: the name of this feature or the undefined value

=head3 method

The name of one feature is interpretated as the value of the feature information tag 'gene'.
If the atribute[0] is defined the name is set by using $self->AddInfo("gene",atribute[0]).

=head3 return value

the value of the 'gene' feature informatin is returned.
If this information is not defined the 'note' information is returned if it matches m/\d+[pg]*\.\d+/
(a IgH V_segment in the Corcoran IgH locus) or the undefined value.

=cut

sub Name {
	my ( $self, $name ) = @_;
	if ( defined $name ) {
		$name =~ s/"//g;
		$self->AddInfo( "gene", $name );
		return $name;
	}

	#    $self->{information}->{gene} = $name if ( defined $name);
	my $return;
	if ( $self->Tag() eq "primer_bind" ) {
		if ( $self->{name} =~ m/TW(\d+)/ ) {
			my $temp = $1;
			return "TW$temp" if ( $temp > 0 );
		}
		if ( $self->{name} =~ m/TW0-lcl|(.)/ ) {
			return $1;
		}
	}
	my $geneArrayRef;
	if ( defined $self->{information}->{gene} ) {
		$geneArrayRef = $self->{information}->{gene};
		@$geneArrayRef[0] =~ s/"//g;
		return @$geneArrayRef[0];
	}
	elsif ( defined $self->{information}->{locus_tag} ) {
		$geneArrayRef = $self->{information}->{locus_tag};
		@$geneArrayRef[0] =~ s/"//g;
		return @$geneArrayRef[0];
	}

	elsif ( defined $self->{information}->{product} ) {
		$geneArrayRef = $self->{information}->{product};
		@$geneArrayRef[0] =~ s/"//g;
		return @$geneArrayRef[0];
	}
	elsif ( defined $self->{information}->{note} ) {
		$geneArrayRef = $self->{information}->{note};
		@$geneArrayRef[0] =~ s/"//g;
		return @$geneArrayRef[0];
	}
	return "not set";

}

sub Gene {
	return Name(@_);
}

=head2 Sequence

=head3 atributes

[0]: the sequence string

=head3 return value

Returns the sequence of this gbFeature as unformated string (if it was set with this method).

=cut

sub Sequence {
	my ( $self, $sequence ) = @_;

	$self->{sequence} = $sequence if ( defined $sequence );

	$self->{seqLength} = length($sequence);

	return $self->{sequence};
}

#    return $self->{sequence} unless ( defined $sequence );
#
#    if ( length($sequence) > $self->{seqLength} ) {
#    }
#    $self->{sequence} = $sequence;
#    return $self->{sequence};
#}

=head2 plot_2_image (
$im,
$axis, 
$font, 
$color_ob, 
$color,
$y1, 
$y2
)
=cut

sub will_be_plotted {
	my ($self) = @_;
	return 1 if ( $self->Tag() =~ m/.+RNA/ );
	return 1 if ( $self->Tag() eq "CDS" );
	return 0;
}

sub plot_2_image {
	my ( $self, $im, $axis, $font, $color_ob, $color, $y1, $y2 ) = @_;
	## I have three possible options to plot myself:
	if ( $self->Tag() =~ m/.+RNA/ ) {
		## here I use smaller blocks
		my $temp = ( $y2 - $y1 ) / 4;
		$y1 += $temp;
		$y2 -= $temp;
	}
	elsif ( $self->Tag() eq "CDS" ) {
		## big blocks - no change in y values
	}
	else {
		return 0;
	}
	my ( $start, $end );
	foreach my $region ( @{ $self->getRegionForDrawing() } ) {
		next
		  if ( $region->{start} > $axis->max_value
			|| $region->{end} < $axis->min_value() );
		$start  = $region->{start};
		$start  = $axis->min_value() if ( $start < $axis->min_value() );
		$end    = $region->{end};
		$end    = $axis->max_value() if ( $end > $axis->max_value );
		$y_mean = int( ( $y1 + $y2 ) / 2 );

		if ( $y_mean - $y1 < $y2 - $y_mean ) {
			$y1--;
		}
		unless (
			int( $axis->resolveValue($start) ) ==
			int( $axis->resolveValue($end) ) )
		{
			$im->filledRectangle(
				int( $axis->resolveValue($start) ),
				$y1, int( $axis->resolveValue($end) ),
				$y2, $color
			);
		}
		else {
			$im->line(
				int( $axis->resolveValue($start) ),
				$y1, int( $axis->resolveValue($end) ),
				$y2, $color
			);
		}

	}
	if ( $self->Tag() =~ m/.+RNA/ ) {
		## here I use smaller blocks
		my $temp = ( $y2 - $y1 ) / 8;
		$y1 += $temp;
		$y2 -= $temp;
		$self->drawLine( $im, $axis, $font, $color_ob, $color, $y1, $y2 );
	}
	return 1;
}

sub drawLine {
	my ( $self, $im, $axis, $font, $color_ob, $color, $y1, $y2 ) = @_;

	my ( $arrow_height, $startBP, $endBP );
	$startBP = $self->Start();
	$endBP   = $self->End();
	$startBP = $axis->min_value() if ( $self->Start() < $axis->min_value() );
	$endBP   = $axis->max_value() if ( $self->End() > $axis->max_value );
	$color   = $color_ob->{grey} unless ( defined $color );

	my $mean = int( ( $y1 + $y2 ) / 2 );

	if ( $mean - $y1 < $y2 - $mean ) {
		$y1--;
	}

	$im->line(
		$axis->resolveValue($startBP),
		$mean, $axis->resolveValue($endBP),
		$mean, $color
	);

	$font->drawStringInRegion_Ycentered_rightLineEnd(
		$im, $self->Name(), $axis->resolveValue($startBP) - 5,
		$y1, $axis->resolveValue($startBP) - 5,
		$y2, $color, 'small'
	);

	$arrow_height = int( ( $y2 - $y1 ) );

	unless ( $self->IsComplement() ) {    #
		for (
			my $i = $axis->resolveValue($startBP) ;
			$i < $axis->resolveValue($endBP) - $arrow_height ;
			$i = $i + ( 2 * $arrow_height )
		  )
		{
			$im->line(
				$i,
				$mean - $arrow_height,
				$i + $arrow_height,
				$mean, $color_ob->{'grey'}
			);
			$im->line(
				$i,
				$mean + $arrow_height,
				$i + $arrow_height,
				$mean, $color_ob->{'grey'}
			);
		}
	}
	else {
		for (
			my $i = $axis->resolveValue($endBP) ;
			$i > $axis->resolveValue($startBP) + $arrow_height ;
			$i = $i - ( 2 * $arrow_height )
		  )
		{
			$im->line(
				$i - $arrow_height,
				$mean, $i, $mean - $arrow_height,
				$color_ob->{'grey'}
			);
			$im->line(
				$i - $arrow_height,
				$mean, $i, $mean + $arrow_height,
				$color_ob->{'grey'}
			);
		}
	}
	return 1;
}

1;

