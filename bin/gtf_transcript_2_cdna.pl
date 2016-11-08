#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-11-04 Stefan Lang

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

    gtf_transcript_2_cdna.pl
       -gtf       :<please add some info!>
       -ids     :<please add some info!> you can specify more entries to that
       -genome_path       :<please add some info!>
       -outpath       :<please add some info!>


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Uses a gtf file and the corresponding fasta formated sequence files (single files) to obtain one or a list of transcripts as cDNA in the right orientation.

  To get further help use 'gtf_transcript_2_cdna.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::file_readers::gtf_file;
use List::MoreUtils qw(uniq);

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $gtf, @ids, $genome_path, $outpath);

Getopt::Long::GetOptions(
	 "-gtf=s"    => \$gtf,
       "-ids=s{,}"    => \@ids,
	 "-genome_path=s"    => \$genome_path,
	 "-outpath=s"    => \$outpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $gtf) {
	$error .= "the cmd line switch -gtf is undefined!\n";
}
unless ( defined $ids[0]) {
	$error .= "the cmd line switch -ids is undefined!\n";
}
elsif ( -f $ids[0]) {
	open ( IN , "<$ids[0]") or die $!;
	@ids = ();
	while ( <IN> ) {
		chomp();
		push( @ids, split(/\s+/, $_ ) );
	}
	close ( IN );
}
unless ( defined $genome_path) {
	$error .= "the cmd line switch -genome_path is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/gtf_transcript_2_cdna.pl';
$task_description .= " -gtf '$gtf'" if (defined $gtf);
$task_description .= ' -ids "'.join( '" "', @ids ).'"' if ( defined $ids[0]);
$task_description .= " -genome_path '$genome_path'" if (defined $genome_path);
$task_description .= " -outpath '$outpath'" if (defined $outpath);



mkdir( $outpath ) unless ( -d $outpath );
open ( LOG , ">$outpath/".$$."_gtf_transcript_2_cdna.pl.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

my $gtf_file = stefans_libs::file_readers::gtf_file ->new();
$gtf_file -> read_file( $gtf );
$gtf_file -> {'chr_path'} = $genome_path;
my $seq;



foreach my $id( @ids ) {
	open ( OUT, ">$outpath/$id.fa" ) or die $!;
	eval {
	print OUT $gtf_file -> get_cDNA_4_transcript ( $id );
	};
	close ( OUT );
	print "Created file $outpath/$id.fa\n";
}

print "Done\n";