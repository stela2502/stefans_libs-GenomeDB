#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-06-22 Stefan Lang

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

=head1  SYNOPSIS

    test_gbFle-pl.pl
       -gbFile       :<please add some info!>


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  A tool to quickly check a gbFile and the abillity to read the gbFile using the gbFeile.pm lib.

  To get further help use 'test_gbFile.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::gbFile;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $gbFile);

Getopt::Long::GetOptions(
	 "-gbFile=s"    => \$gbFile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $gbFile) {
	$error .= "the cmd line switch -gbFile is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
	print "$errorMessage.\n";
	pod2usage(q(-verbose) => 1);
}



my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/test_gbFle-pl.pl';
$task_description .= " -gbFile '$gbFile'" if (defined $gbFile);


$gbFile = gbFile->new($gbFile, $debug);

print "The gbFile ". $gbFile->Version(). " has " . scalar(@{$gbFile->Features}). " Features and ".length($gbFile->{seq})."bp of sequence\n";

## Do whatever you want!

