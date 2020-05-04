package stefans_libs::gbFile::file_parser;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;

=head1 LICENCE

  Copyright (C) 2016-06-23 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile::file_parser

=head1 DESCRIPTION

This provides methods to parse the gbFiles.

=head2 depends on


=cut


=head1 METHODS

=head2 new ( $hash )

new returns a new object reference of the class stefans_libs::gbFile::file_parser.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut

sub new{

	my ( $class, $hash ) = @_;

	my ( $self );

	$self = {
  	};
  	foreach ( keys %{$hash} ) {
  		$self-> {$_} = $hash->{$_};
  	}

  	bless $self, $class  if ( $class eq "stefans_libs::gbFile::file_parser" );

  	return $self;

}

sub isMultilineStart {
	my ( $self, $string, $qL, $qR ) = @_;

	my ($quote_level);  # current quote level
	my ( $myValue, $temp );


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
	if ( $qL eq $qR ) {    #"
		if ( $myValue % 2 == 0 ){
			return 0
		}else {
			#warn "OK and this string is  multiline start/end ($qL, $qR ; $myValue) ?:'$string'\n";
			return 1
		}
	}
	return $myValue;
}

1;
