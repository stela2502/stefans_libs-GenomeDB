package thread_helper;
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
use stefans_libs::database::system_tables::workingTable;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A module to help with the different threading problems

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class thread_helper.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
		'workingTable' => workingTable -> new()
  	};
  	bless $self, $class  if ( $class eq "thread_helper" );
  	return $self;
}

sub expected_dbh_type {

	#return 'dbh';
	return "not a database interface";
	#return "database_name";
}


1;
