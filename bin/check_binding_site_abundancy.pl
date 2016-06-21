#! /usr/bin/perl -w

#  Copyright (C) 2012-12-07 Stefan Lang

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

=head1 check_binding_site_abundancy.pl

A tool to extract putative binding sites from a fasta db.

To get further help use 'check_binding_site_abundancy.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::fastaDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $mismatch, $infile, $pattern, $outfile );

Getopt::Long::GetOptions(
	"-infile=s"  => \$infile,
	"-pattern=s" => \$pattern,
	"-outfile=s" => \$outfile,
	"-mismatch=s" => \$mismatch,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $pattern ) {
	$error .= "the cmd line switch -pattern is undefined!\n";
}
unless ( defined $outfile ) {
	$outfile = $infile;
	$outfile =~ s/.fa$//;
	$outfile .= "_$pattern.fa";
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
 command line switches for check_binding_site_abundancy.pl

   -infile    :a fastaDB
   -pattern   :the sequence pattern you want to look for
   -outfile   :the output fastaDB (default = <infile>_<pattern>.fa)
   -mismatch  :number of possible missmatches (default 0)

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/check_binding_site_abundancy.pl';
$task_description .= " -infile $infile"   if ( defined $infile );
$task_description .= " -pattern $pattern" if ( defined $pattern );
$task_description .= " -outfile $outfile" if ( defined $outfile );

my $fastaDB = fastaDB->new($infile);
my $outfileDB = fastaDB->new();

my ( $length, $acc_id );
$acc_id = 1;

( $length, $acc_id ) = &match_2_pattern ( $pattern, $fastaDB, $outfileDB);

if ( $mismatch ) {
	die "Sorry I have no implementation for a mismatch > 1\n" if ( $mismatch > 1 );
	for ( my $i = 0; $i < length($pattern); $i ++ ){
		my @temp = split( "", $pattern );
		$temp[$i] = '.';
		( $length, $acc_id ) = &match_2_pattern ( join("", @temp), $fastaDB, $outfileDB);
	}
}

$outfileDB->WriteAsFastaDB($outfile);

sub match_2_pattern {
	my ( $pattern, $infile, $outfile ) = @_;
	my ( $length, $acc, $seq, $ref_pattern );
	$length = 0;
	$infile->Reset();
	$ref_pattern = &_rev_patern($pattern);
	while ( ( $acc, $seq ) = $fastaDB->get_next() ) {
		last unless ( defined $acc);
		$length += length($seq);
		while ( $seq =~ m/(.......$pattern.......)/g ) {
			$outfile->addEntry( $acc . " #" . $acc_id++, $1 );
		}
		while ( $seq =~ m/(.......$ref_pattern.......)/g ) {
			$outfile->addEntry( $acc . " #ref_" . $acc_id++, $1 );
		}
	}
	return ( $length, $acc_id );
}

sub _rev_patern {
	my ($pattern) = @_;
	my $ref = {
		'A' => 'T',
		'T' => 'A',
		'C' => 'G',
		'G' => 'C',
		'.' => '.',
	};
	my $ret = '';
	my @data = ( split( "", $pattern ) );
	for ( my $i = @data - 1 ; $i >= 0 ; $i-- ) {
		$ret .= $ref->{ $data[$i] };
	}
	return $ret;
}

## Do whatever you want!

