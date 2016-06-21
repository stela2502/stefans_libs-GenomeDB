package fulfilledTask_handler;
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


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A list of functions that can enhance a class to use the fulfilled task table set.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class fulfilledTask_handler.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "fulfilledTask_handler" );

  	return $self;

}


1;
