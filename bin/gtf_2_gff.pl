#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-03-17 Stefan Lang

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

    gtf_2_gff.pl
       -infile       :<please add some info!>
       -outfile       :<please add some info!>


       -help           :print this help
       -debug          :verbose output

=head1 DESCRIPTION

  Convert a gtf into a gff file.

  To get further help use 'gtf_2_gff.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::root;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/gtf_2_gff.pl';
$task_description .= " -infile '$infile'" if (defined $infile);
$task_description .= " -outfile '$outfile'" if (defined $outfile);



my $fm = root->filemap( $outfile );
mkdir( $fm->{'path'}) unless ( -d $fm->{'path'} );

open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

open ( IN, "<$infile" ) or die "I could not open the infile '$infile'\n$!\n";
open ( OUT, ">$outfile") or die "I could not open the outfile '$outfile'\n$!\n";

my ($gene_name, $i);
$i =0;
while (my $line = <IN> ) {
	unless ( $line =~m/^#/){
		$line =~s/; (\w+) (\d+);/; $1=$2;/g;		
		$line =~s/" *; */;/g;
		$line =~s/ "/=/g;
	}
  print OUT $line;
}

print "Done\n";
