#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-03-16 Stefan Lang

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

    Liftover_GTF.pl
       -gtf          :the gtf file to lift over
       -liftover_bed :the liftover bed file obtained from UCSC liftover
       -outfile      :the updated gtf file


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Use a file created by GTF_2_Bed.pl and UCSC liftover to liftover the initial gtf.

  To get further help use 'Liftover_GTF.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $gtf, $liftover_bed, $outfile);

Getopt::Long::GetOptions(
	 "-gtf=s"    => \$gtf,
	 "-liftover_bed=s"    => \$liftover_bed,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $gtf) {
	$error .= "the cmd line switch -gtf is undefined!\n";
}
unless ( defined $liftover_bed) {
	$error .= "the cmd line switch -liftover_bed is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/Liftover_GTF.pl';
$task_description .= " -gtf '$gtf'" if (defined $gtf);
$task_description .= " -liftover_bed '$liftover_bed'" if (defined $liftover_bed);
$task_description .= " -outfile '$outfile'" if (defined $outfile);



use stefans_libs::Version;
my $V = stefans_libs::Version->new();
my $fm = root->filemap( $outfile );
mkdir( $fm->{'path'}) unless ( -d $fm->{'path'} );

open ( LOG , ">$outfile.log") or die $!;
print LOG '#library version'.$V->version( 'stefans_libs-Genome' )."\n";
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

open ( my $gtf_file, "<$gtf" ) or die "I could not open the gtf file '$gtf'\n$!\n";
open (my $bed_file, "<$liftover_bed") or die "I could not open the liftover_bed file '$liftover_bed'\n$!\n";
open ( OUT, ">$outfile") or die "I could not create the outfile $outfile\n$!\n";

my ( $gtf_line, $liftover_line, $i, $tmp ) ;
$i = 0;
WHILE: while ( 1 ) {
	($gtf_line, $liftover_line ) = map { $tmp = &read_file_line ("useless", $_ ); last WHILE unless ( defined $tmp ); chomp($tmp); [ split("\t", $tmp)] }  $gtf_file, $bed_file;
	#print "working on line $i\n".join("\t",@$gtf_line );
	last unless ( defined @$gtf_line[0] );
	while( $i++ != @$liftover_line[3] ) {
		warn "line ". ($i-1)." was missing in the liftover gtf file (@$liftover_line[3])\n";
		## one gtf region could not be lifted over
		($gtf_line) = map { $tmp = &read_file_line ("useless",$_ ); last WHILE unless ( defined $tmp ); chomp($tmp); [ split("\t", $tmp)] }  $gtf_file;
	}
	
	@$gtf_line[0] = @$liftover_line[0];
	@$gtf_line[3] = @$liftover_line[1];
	@$gtf_line[4] = @$liftover_line[2];
	print OUT join("\t",@$gtf_line)."\n";
}

close ( $gtf_file );
close ( $bed_file );
close ( OUT );
print "new gtf written to '$outfile'\n";



=head2 read_file_line

## code taken from http://stackoverflow.com/questions/2498937/how-can-i-walk-through-two-files-simultaneously-in-perl

=cut

sub read_file_line {
	my ( $self, $fh ) = @_;
	if ( $fh and my $line = <$fh> ) {
		return $line;
	}
	return undef;
}



