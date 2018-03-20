#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-08-23 Stefan Lang

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
   
   binCreate.pl from  commit 
   

=head1  SYNOPSIS

    fastq_trim.pl
       -fastq     :a list of fastq entries
       -start     :trim $start bp from the start
       -end       :trim from bp $end to the read end


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Trims sequence from fastq or fastq.gz files from start and/or end and wited fastq.gz files.

  To get further help use 'fastq_trim.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

use stefans_libs::FastqFile;
use stefans_libs::root;


my ( $help, $debug, $database, @fastq, $start, $end);

Getopt::Long::GetOptions(
       "-fastq=s{,}"    => \@fastq,
	 "-start=s"    => \$start,
	 "-end=s"    => \$end,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';
my $problem = 0;

unless ( defined $fastq[0]) {
	$error .= "the cmd line switch -fastq is undefined!\n";
}
unless ( defined $start) {
	$warn .= "the cmd line switch -start is undefined!\n";
	$problem ++;
}
unless ( defined $end) {
	$warn .= "the cmd line switch -end is undefined!\n";
	$problem ++;
}

if ( $problem == 2 ){
	$error .= "Both 'start' and 'end' are undefined - did you want me to do nothing?\n"
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

$task_description .= 'perl '.$plugin_path .'/fastq_trim.pl';
$task_description .= ' -fastq "'.join( '" "', @fastq ).'"' if ( defined $fastq[0]);
$task_description .= " -start '$start'" if (defined $start);
$task_description .= " -end '$end'" if (defined $end);




## Do whatever you want!


my $OBJ = stefans_libs::FastqFile -> new();


my ($fm, $ofile, $filtered, $OUT, $total ) ;

my $function = sub  {
	my ( $worker, $entry ) = @_;
	$total ++;
	$entry->trim('start',$start ) if ( $start );
	$entry->trim('end', $end ) if ( $end );
	
	$entry->write($OUT);
	$entry->clear();
};

foreach my $file ( @fastq ) {
	$filtered = $total = 0;
	$fm = root->filemap($file);
	$ofile = $fm->{'path'}."/".$fm->{'filename_core'}."trimmed.fastq.gz";
	open ($OUT, "| gzip > $ofile") or die "I could not gzip the output 'gzip > $ofile'\n$!\n";
	$OBJ->filter_file( $function, $file );
	close ( $OUT );
	print "done with file $ofile\n";
}

