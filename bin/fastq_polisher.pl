#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2018-03-20 Stefan Lang

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

    fastq_polisher.pl
       -fastq         :a list of fastq files to polish
  -filter_low_quality :the quality filter avlue ( off by default)
       -outpath       :the path for the filtered fastq files


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Implement the polishing features of SplitToCells into a per fastq file polisher.

  To get further help use 'fastq_polisher.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::FastqFile;

use strict;
use warnings;

use stefans_libs::root;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @fastq, $filter_low_quality, $outpath);

Getopt::Long::GetOptions(
       "-fastq=s{,}"    => \@fastq,
	 "-filter_low_quality=s"    => \$filter_low_quality,
	 "-outpath=s"    => \$outpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $fastq[0]) {
	$error .= "the cmd line switch -fastq is undefined!\n";
}
unless ( defined $filter_low_quality) {
	$warn .= "the cmd line switch -filter_low_quality is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/fastq_polisher.pl';
$task_description .= ' -fastq "'.join( '" "', @fastq ).'"' if ( defined $fastq[0]);
$task_description .= " -filter_low_quality '$filter_low_quality'" if (defined $filter_low_quality);
$task_description .= " -outpath '$outpath'" if (defined $outpath);



mkdir( $outpath ) unless ( -d $outpath );
open ( LOG , ">$outpath/".$$."_fastq_polisher.pl.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


my $flush_counter = 0;
$| = 1;
my $filtered_polyT = 0;
my ( $ofile, $fm, $OUT, $total, $filtered_out );

my $OBJ = stefans_libs::FastqFile -> new();

my $func = sub {
	my ( $fastqfile, @entries ) = @_;    ## f1, f2, i1

	my $UMI_tag = filter_reads( $entries[0] );

	if ( defined $UMI_tag and length( $UMI_tag->sequence() ) > 50 ) {
		$entries[0] = $UMI_tag;
		$entries[0]->write($OUT);
	}
	else {
		$filtered_out++;
	}

	for ( my $i = 0 ; $i < @entries ; $i++ ) {
		$entries[$i]->clear();
	}
	
};

my $func_no_Qcheck = sub {
	my ( $fastqfile, @entries ) = @_;    ## f1, f2, i1

	my $UMI_tag = filter_no_quality_check ( $entries[0] );
	
	if ( defined $UMI_tag and length( $UMI_tag->sequence() ) > 50 ) {
		$entries[0] = $UMI_tag;
		$entries[0]->write($OUT);
	}
	else {
		$filtered_out++;
	}

	for ( my $i = 0 ; $i < @entries ; $i++ ) {
		$entries[$i]->clear();
	}
};


foreach my $file ( @fastq ) {
	$filtered_polyT = $filtered_out = 0;
	
	$fm = root->filemap($file);
	$ofile = $outpath."/".$fm->{'filename_core'}."_filtered.fastq.gz";
	open ($OUT, "| gzip > $ofile") or die "I could not gzip the output 'gzip > $ofile'\n$!\n";
	if ( defined $filter_low_quality ){
		$OBJ->filter_file( $func, $file );
	}else {
		$OBJ->filter_file( $func_no_Qcheck, $file );
	}
	
	close ( $OUT );
	print "$filtered_polyT/$flush_counter (".($filtered_polyT/$flush_counter*100)."%) polyA reads cleaned ($ofile)\n"
	  . "$filtered_out reads dropped\n";
}



sub filter_no_quality_check {
	my ( $read, $min_length ) = @_;

	$min_length ||= 10;
	## filter polyT at read end
	if ( $read->sequence() =~ m/([Aa]{5}[Aa]+)$/ ) {
		$read->trim( 'end', length( $read->sequence() ) - length($1) );
		$filtered_polyT++;
	}
	if ( $read->sequence() =~ m/([Tt]{5}[Tt]+)$/ ) {
		$read->trim( 'end', length( $read->sequence() ) - length($1) );
		$filtered_polyT++;
	}
		
	## filter reads with high ployX (>= 50%)

	my $str = $read->sequence();
	foreach ( 'Aa', 'Cc', 'Tt', 'Gg' ) {
		foreach my $repl ( $str =~ m/[$_]{$min_length}[$_]*/g ) {
			my $by = 'N' x length($repl);
			$str =~ s/$repl/$by/;
		}
	}
	my $count = $str =~ tr/N/n/;

	if ( $count != 0 and $count / length($str) > 0.5 ) {
		return undef;
	}

	if ( ++ $flush_counter % 10000 == 0 ) {
		print '.';
	} 
	## return filtered read

	return $read;
}

sub filter_reads {
	my ( $read, $min_length ) = @_;

	$min_length ||= 10;

	## filter polyT at read end
	if ( $read->sequence() =~ m/([Aa]{5}[Aa]+)$/ ) {
		$read->trim( 'end', length( $read->sequence() ) - length($1) );
		$filtered_polyT++;
	}
	if ( $read->sequence() =~ m/([Tt]{5}[Tt]+)$/ ) {
		$read->trim( 'end', length( $read->sequence() ) - length($1) );
		$filtered_polyT++;
	}
	
	$read->filter_low_quality($filter_low_quality); ## throw away crap!
	
	## filter reads with high ployX (>= 50%)

	my $str = $read->sequence();
	foreach ( 'Aa', 'Cc', 'Tt', 'Gg' ) {
		foreach my $repl ( $str =~ m/[$_]{$min_length}[$_]*/g ) {
			my $by = 'N' x length($repl);
			$str =~ s/$repl/$by/;
		}
	}
	my $count = $str =~ tr/N/n/;

	if ( $count != 0 and $count / length($str) > 0.5 ) {
		return undef;
	}

	if ( ++ $flush_counter % 10000 == 0 ) {
		print '.';
	} 
	## return filtered read

	return $read;
}



## Do whatever you want!

