#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2018-03-19 Stefan Lang

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

=head1 CREATED BY
   
   binCreate.pl from git@gitlab:stefanlang/Stefans_Lib_Esentials.git commit d6027a714e3cf82cabf695899e4c58b469f305b4
   

=head1  SYNOPSIS

    getFastaSeq.pl
       -file      :the fasta file / fasta database
       -start     :the start position in the fasta file
       -end       :the end bp of the sequence
       -acc       :optional the acc in the fasta db file

       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Extract string from fasta file

  To get further help use 'getFastaSeq.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::fastaFile;
use stefans_libs::fastaDB;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $file, $start, $end, $acc);

Getopt::Long::GetOptions(
	 "-file=s"    => \$file,
	 "-start=s"    => \$start,
	 "-end=s"    => \$end,
	 "-acc=s"    => \$acc,
	 
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $file) {
	$error .= "the cmd line switch -file is undefined!\n";
}
unless ( defined $start) {
	$error .= "the cmd line switch -start is undefined!\n";
}
unless ( defined $end) {
	$error .= "the cmd line switch -end is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/getFastaSeq.pl';
$task_description .= " -file '$file'" if (defined $file);
$task_description .= " -start '$start'" if (defined $start);
$task_description .= " -end '$end'" if (defined $end);
$task_description .= " -acc '$acc'" if ( defined $acc );



my $fasta;

## Do whatever you want!
if ( defined $acc ) {
	my $fastaDB = stefans_libs::fastaDB->new($file);
	$fasta = fastaFile ->new();
	$fasta -> Create($acc, $fastaDB->_seq($acc) );
}else {
	$fasta = fastaFile ->new($file);
}

print $fasta -> Get_SubSeq ( $start, $end);

