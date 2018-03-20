#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-07-11 Stefan Lang

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

    fastq_trim_and_split.pl
       -fastq       :the fastq file to split
       -outpath     :the out folder to save the spliced fastq data
       -barcodes    :a list of barcodes to search for
       -linker      :the sequence of the linker DNA
       
       -options     :format: key_1 value_1 key_2 value_2 ... key_n value_n
			
			unused at the moment

       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Takes one fastq file, identifies a linker sequence and splits the fastq file into several gzipped fastq files  based on the sample definition barcodes.

  To get further help use 'fastq_trim_and_split.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;
use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $fastq, $outpath, @barcodes, $options, @options, $rev_barcode, $linker);

Getopt::Long::GetOptions(
	 "-fastq=s"    => \$fastq,
	 "-outpath=s"    => \$outpath,
       "-barcodes=s{,}"    => \@barcodes,
       "-options=s{,}"    => \@options,
       "-linker=s" => \$linker,
       "-rev_barcode" => \$rev_barcode,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $fastq) {
	$error .= "the cmd line switch -fastq is undefined!\n";
}
unless ( defined $outpath) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
unless ( defined $barcodes[0]) {
	$error .= "the cmd line switch -barcodes is undefined!\n";
}else {
	my $OK = 1;
	@barcodes = map { uc($_ ) } @barcodes;
	foreach ( @barcodes ) {
		unless ( $_ =~ m/^[ACGT]+$/ ){
			$error .= "\t barcode $_ contains none ATGC bases\n";
		}
	}
}
unless ( defined $options[0]) {
	$warn .= "the cmd line switch -options is undefined!\n";
}
unless ( defined $linker ) {
	$error .= "the cmd line switch -linker is undefined!\n";
}else {
	unless ( $linker =~ m/^[ACGT]+$/ ){
			$error .= "\t linker $linker contains none ATGC bases\n";
		}
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

### initialize default options:

#$options->{'n'} ||= 10;

###


my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/fastq_trim_and_split.pl';
$task_description .= " -fastq '$fastq'" if (defined $fastq);
$task_description .= " -outpath '$outpath'" if (defined $outpath);
$task_description .= ' -barcodes "'.join( '" "', @barcodes ).'"' if ( defined $barcodes[0]);
$task_description .= ' -options "'.join( '" "', @options ).'"' if ( defined $options[0]);
$task_description .= " -linker '$linker'" if (defined $linker);
$task_description .= " -rev_barcode" if ($rev_barcode);

for ( my $i = 0 ; $i < @options ; $i += 2 ) {
	$options[ $i + 1 ] =~ s/\n/ /g;
	$options->{ $options[$i] } = $options[ $i + 1 ];
}
###### default options ########
#$options->{'something'} ||= 'default value';
##############################
mkdir( $outpath ) unless ( -d $outpath );
open ( LOG , ">$outpath/".$$."_fastq_trim_and_split.pl.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

if ( $fastq =~ m/gz$/ ){
	open ( FAF, "zcat $fastq |" ) or die "I could not open the file $fastq using zcat\n$!\n";
}else {
	open ( FAF, "<$fastq" ) or die "I could not open the file $fastq\n$!\n";
}

my ( $l, @entry, $ofiles, $linker_match, $fm, $barcode, $m, @tmp, @trimmed );
$l = 0;
#$linker = substr( $linker, length($linker) -4 );
$linker_match = join("?", split("",$linker))."?";
$fastq =~ s/.gz$//;
$fm = root->filemap( $fastq );

foreach $barcode ( @barcodes ) {
	$barcode = &rev_compl ( $barcode) if ( $rev_barcode);
	open ( $ofiles->{$barcode}, "| gzip -9 -c > $outpath/$fm->{'filename_core'}_$barcode.fastq.gz" ) or die "I could not open the gzip outfile process 'gzip -9 -c > $outpath/$fm->{'filename_core'}_$barcode.fastq.gz'\n$!\n";
#	print "$linker_match$barcode\n"if ( $debug);
}
open ( $ofiles->{'NoMatch'}, "| gzip -9 -c > $outpath/$fm->{'filename_core'}_NoMatch.fastq.gz" ) or die "I could not open the gzip outfile process 'gzip -9 -c > $outpath/$fm->{'filename_core'}_NoMatch.fastq.gz'\n$!\n";


WHILE: while ( <FAF> ) {
	$l ++;
	push(@entry, "$_");
	if ( $l == 4 ) {
		$l = 0;
		foreach $barcode ( sort keys %$ofiles ) {
			if ( $entry[1] =~ m/^([ACTG][ACTG][ACTG])($barcode)([ACTG][ACTG])/ ) {
				$m = "the 3+92Ns: '$1$3' the barcode: '$2' read length=".length($entry[1]);
				#warn "normal match $m\n";
				@tmp = split( " ", $entry[0]);
				$tmp[0] .= ":$1$3:$2";
				$entry[0] = join( " ",@tmp)."\n";
				$entry[1] = substr ($entry[1], length($1.$2.$3));
				$entry[3] = substr ($entry[3], length($1.$2.$3));
				print {$ofiles->{$barcode}} join("", @entry );
				@entry = @trimmed = ();
				next WHILE;
			}
		}
		if ( @entry > 0 ){
			@entry = @{&remove_linker ( [@entry] )};
			foreach $barcode ( sort keys %$ofiles ) {
			if ( $entry[1] =~ m/^([ACTG][ACTG][ACTG])($barcode)([ACTG][ACTG])/ ) {
				$m = "the 3+92Ns: '$1$3' the barcode: '$2' read length=".length($entry[1]);
				#warn "trimmed match $m\n";
				@tmp = split( " ", $entry[0]);
				$tmp[0] .= ":$1$3:$2";
				$entry[0] = join( " ",@tmp)."\n";
				$entry[1] = substr ($entry[1], length($1.$2.$3));
				$entry[3] = substr ($entry[3], length($1.$2.$3));
				print {$ofiles->{$barcode}} join("", @entry );
				@entry = @trimmed = ();
				next WHILE;
			}
			}
		}
		
		
		## oops this did not match
		print ${$ofiles->{'NoMatch'}} join("", @entry );
		@entry = (); 
	}
}

close ( FAF );

foreach $barcode ( keys %$ofiles ) {
	close ($ofiles->{$barcode} );
}


sub remove_linker {
	my $entry = shift;
	my $s;
	die "Not an array: $entry" unless ( ref($entry) eq "ARRAY");
	for ( my $i = 0 ;$i < length($linker); $i++ ) {
		$s = substr( $linker, $i );
		#print "searching for string $s\n";
		if ( @$entry[1] =~ s/^$s// ){
			@$entry[3] = substr( @$entry[3], length($s) );
			#print "Match and removed $s\n";
			last;
		}
	}
	return $entry;
}

sub rev_compl {
	my ( $forward ) = @_;
	my $rev = reverse($forward);
	$rev =~ tr/ABCDGHMNRSTUVWXYabcdghmnrstuvwxy/TVGHCDKNYSAABWXRtvghcdknysaabwxr/;
	return $rev;
}
