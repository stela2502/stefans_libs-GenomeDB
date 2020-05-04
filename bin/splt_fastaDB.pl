#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2020-04-30 Stefan Lang

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
   
   binCreate.pl from git@github.com:stela2502/Stefans_Lib_Esentials.git commit c35cfea822cac3435c5821897ec3976372a89673
   

=head1  SYNOPSIS

    splt_fastaDB.pl
       -infile       :<please add some info!>
       -outpath       :<please add some info!>


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Create a separate fasta file for every entry in the database

  To get further help use 'splt_fastaDB.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use stefans_libs::fastaDB;
use stefans_libs::fastaFile;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outpath);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outpath=s"    => \$outpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outpath) {
	$error .= "the cmd line switch -outpath is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/splt_fastaDB.pl';
$task_description .= " -infile '$infile'" if (defined $infile);
$task_description .= " -outpath '$outpath'" if (defined $outpath);



mkdir( $outpath ) unless ( -d $outpath );
open ( LOG , ">$outpath/".$$."_splt_fastaDB.pl.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

my $OBJ = stefans_libs::fastaDB -> new();
$OBJ->AddFile( $infile );
my ($acc, $seq, $fastaF, @tmp, $fname, $i);
$i = 0;
while( ($acc, $seq) = $OBJ->get_next() ) {
	$i ++;
	if ( defined($acc) ) {
		$fastaF = fastaFile->new();
		$fastaF->Create( $acc, $seq);
		@tmp = split(" ", $acc);
		$fname = File::Spec->catfile( $outpath, $tmp[0].".fa" );
		$fastaF->write_file( $fname );
		print ( "Accession $i witten to $fname\n");
	}else {
		last;
	}
}

print "$i fasta files written to $outpath\n";