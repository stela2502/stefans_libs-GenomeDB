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
	
	
    fastq_drop_polyA.pl
       -fastq     :a list of fastq files (can be gzipped)
       -ignored   :how much sequence at the beginning of the read should nevertheless be dropped
                   default 0
       -cutoff    :which quality is still acceptable (default = 10)
       
       -help      :print this help
       -debug     :verbose output
   
=head1 DESCRIPTION

  Identifies reads that contain mainly polyA sequence and drops them.
  See stefans_libs::FastqFile::FastqEntry->is_polyA() for the main function.

  To get further help use 'fastq_drop_polyA.pl -help' at the comman line.

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

my ( $help, $debug, $database, @fastq, $ignored, $cutoff);

Getopt::Long::GetOptions(
       "-fastq=s{,}"    => \@fastq,
	 "-ignored=s"    => \$ignored,
	 "-cutoff=s" => \$cutoff,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $fastq[0]) {
	$error .= "the cmd line switch -fastq is undefined!\n";
}
unless ( defined $ignored) {
	$ignored = 0;
}
unless ( defined $cutoff) {
	$cutoff = 0;
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

$task_description .= 'perl '.$plugin_path .'/fastq_drop_polyA.pl';
$task_description .= ' -fastq "'.join( '" "', @fastq ).'"' if ( defined $fastq[0]);
$task_description .= " -ignored '$ignored'" if (defined $ignored);
$task_description .= " -cutoff '$cutoff'" if (defined $cutoff);




## Do whatever you want!

my $OBJ = stefans_libs::FastqFile -> new();


my ($fm, $ofile, $filtered, $OUT, $total ) ;

my $function = sub  {
	my ( $worker, $entry ) = @_;
	$total ++;
	if ( $entry->is_polyA($ignored, $cutoff) ){
		$filtered ++;
	}
	else {
		$entry->write($OUT);
	}
	$entry->clear();
};

foreach my $file ( @fastq ) {
	$filtered = $total = 0;
	$fm = root->filemap($file);
	$ofile = $fm->{'path'}."/".$fm->{'filename_core'}."_drop_polyA.fastq.gz";
	open ($OUT, "| gzip > $ofile") or die "I could not gzip the output 'gzip > $ofile'\n$!\n";
	$OBJ->filter_file( $function, $file );
	close ( $OUT );
	print "$filtered/$total (".($filtered/$total*100)."%) polyA reads filtered ($ofile)\n";
}
	
	
	