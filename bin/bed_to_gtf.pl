#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-06-29 Stefan Lang

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

    bed_to_gtf.pl
       -bed_file    :the input bed file
       -outfile     :the output gtf file
       -options     :format: key_1 value_1 key_2 value_2 ... key_n value_n
       
             db_type   :where do the gene information parts come from? (NCBI)
                        unset gene names (column 5 in the unconventional bed file) get 'unknown'
             peak_type :where do the genomic regions come from (default = 'transcription start')
            chr2geneID :create the geneID from chr start stop as chr:start-stop 
             


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Convert bed files produced e.g. during ChIP experiment analysis into a gtf file that can be used to quantify reads using expression analysis methods.

  To get further help use 'bed_to_gtf.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $bed_file, $outfile, $options, @options);

Getopt::Long::GetOptions(
	 "-bed_file=s"    => \$bed_file,
	 "-outfile=s"    => \$outfile,
       "-options=s{,}"    => \@options,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $bed_file) {
	$error .= "the cmd line switch -bed_file is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $options[0]) {
	$warn .= "the cmd line switch -options is undefined!\n";
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
unless ( $options->{'chr2geneID'} ){
	$options->{'chr2geneID'}=0;
}else {
	$options->{'chr2geneID'}=1;
}
###


my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/bed_to_gtf.pl';
$task_description .= " -bed_file '$bed_file'" if (defined $bed_file);
$task_description .= " -outfile '$outfile'" if (defined $outfile);
$task_description .= ' -options "'.join( '" "', @options ).'"' if ( defined $options[0]);


for ( my $i = 0 ; $i < @options ; $i += 2 ) {
	$options[ $i + 1 ] =~ s/\n/ /g;
	$options->{ $options[$i] } = $options[ $i + 1 ];
}
###### default options ########
$options->{'db_type'} ||= 'NCBI';
$options->{'peak_type'} ||= 'transcription start';
##############################
open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

# I expect a file like that:
#chr1    15890   15990   1       WASH7P // WASH7P        "GeneID:653635";"HGNC:38034" // "GeneID:653635";"HGNC:38034"    14362 // 14362  29370 // 29370

# and I have to convert it to something like this:
#chr1    HAVANA  gene    11869   14409   .       +       .       gene_id "ENSG00000223972.5"; gene_type "transcribed_unprocessed_pseudogene"; gene_status "KNOWN"; gene_name "DDX11L1"; level 2; havana_gene "OTTHUMG00000000961.2";

open ( IN , "<$bed_file") or die "I could not open the bed file $bed_file\n$!\n";
open ( OUT , ">$outfile") or die "I could not create the outfile $outfile\n$!\n";
my ( @line, @tmp, $tmp );

while ( <IN> ) {
	chomp($_);
	@line = split("\t", $_);	if ( $options->{'chr2geneID'} or $line[4] =~ m/\-\-\-/) {
		## no asosicated gene!
		print OUT join("\t",$line[0], 'unknown', $options->{'peak_type'}, @line[1,2], '.','.','.', "gene_id \"$line[0]:$line[1]-$line[2]\"; gene_name=\"none\""  )."\n";
	}else {
		print OUT join("\t",$line[0], $options->{'db_type'}, $options->{'peak_type'}, @line[1,2], '.','.','.', "gene_id \"$line[0]:$line[1]-$line[2]\"; gene_name=\"$line[4]\""  )."\n";
	}
}
close(IN);
close (OUT);
print "Done\n";
