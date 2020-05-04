#! /usr/bin/perl -w

#  Copyright (C) 2014-11-18 Stefan Lang

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

=head1 count_entries_in_other_bedfiles.pl

This tool count the amount of regions in the other bed file that overlap any region in this bed file.

To get further help use 'count_entries_in_other_bedfiles.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile, @mapp_to, $outfile );

Getopt::Long::GetOptions(
	"-infile=s"     => \$infile,
	"-mapp_to=s{,}" => \@mapp_to,
	"-outfile=s"    => \$outfile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $mapp_to[0] ) {
	$error .= "the cmd line switch -mapp_to is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for count_entries_in_other_bedfiles.pl

   -infile       :<please add some info!>
   -mapp_to       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/count_entries_in_other_bedfiles.pl';
$task_description .= " -infile $infile" if ( defined $infile );
$task_description .= ' -mapp_to ' . join( ' ', @mapp_to )
  if ( defined $mapp_to[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );

my $fm = root->filemap($outfile);
unless ( -d $fm->{'path'} ) {
	mkdir( $fm->{'path'} );
}
open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

my $main = stefans_libs::file_readers::bed_file->new();
$main->read_file($infile);
my ( $o, $name );
foreach my $other_file (@mapp_to) {
	next unless ( -f $other_file );
	$name = root->filemap($other_file);
	$o    = stefans_libs::file_readers::bed_file->new();
	$o->read_file($other_file);
	$main->efficient_match( $o, $name->{'filename_core'} );
	for ( my $i = 0 ; $i < $main->Rows() ; $i++ ) {
		@{ @{ $main->{'data'} }[$i] }
		  [ $main->Header_Position( $name->{'filename_core'} ) ] = map {
			if   ( ref($_) eq "ARRAY" ) { scalar(@$_) }
			else                        { 0 }
		  } @{ @{ $main->{'data'} }[$i] }
		  [ $main->Header_Position( $name->{'filename_core'} ) ];
	}
}

$main->print_as_table($outfile);
