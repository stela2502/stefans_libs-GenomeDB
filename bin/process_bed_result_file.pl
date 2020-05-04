#! /usr/bin/perl -w

#  Copyright (C) 2012-11-05 Stefan Lang

#  This program is free software; you can redistribute it 
#  and/or modify it under the terms of the GNU General Public License 
#  as published by the Free Software Foundation; 
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful, 
#  but WITHOUT ANY WARRANTY; without even the implied warranty of 
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License 
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 process_bed_result_file.pl

This script does look into the name part of a epigenetic bed file and converts the epigenetic list into a gene based list.

To get further help use 'process_bed_result_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::bed_file;

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
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for process_bed_result_file.pl

   -infile       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/process_bed_result_file.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);

my $bed_file = stefans_libs::file_readers::bed_file -> new();
$bed_file ->read_file ( $infile );
my $result_file = data_table->new();
foreach ( qw(gene transcribed_region_hits promoter_hit mRNA_end_hit) ){
	$result_file->Add_2_Header( $_ );
}
my ( $matching, $not_matching, $result, @temp );
$matching = $not_matching = 0;
for ( my $i = 0; $i < $bed_file->Lines(); $i ++ ) {
	##the first three values are uninteresting here the last is of interest
	if ( @{@{$bed_file->{'data'}}[$i]}[3] =~ m/\w/ ) {
		$matching ++;
		foreach ( split ( " ",  @{@{$bed_file->{'data'}}[$i]}[3] ) ) {
			@temp = split("_", $_ );
			$result->{$temp[0]} = {'body' => 0, 'promoter' => 0, 'mRNA_end' => 0 } unless ( defined $result->{$temp[0]});
			if ( @temp == 1 ) {
				$result->{$temp[0]}->{'body'} ++;
			}
			elsif ( @temp == 2 ) {
				$result->{$temp[0]}->{'promoter'} ++;
			}
			elsif ( @temp == 3 ) {
				$result->{$temp[0]}->{'mRNA_end'} ++;
			}
			else {
				warn "I do not understand this entry: '$_'\n";
			}
		}
	}
	else {
		$not_matching ++;
	}
}
my $i = 0;
foreach ( sort keys %$result ) {
	@{$result_file->{'data'}} [ $i ++ ] = [ $_,$result->{$_}->{'body'}, $result->{$_}->{'promoter'}, $result->{$_}->{'mRNA_end'} ];
}
print "I got $matching matching and $not_matching not matching results in the bed file!\n";
$result_file -> Add_2_Description ( "out of ".$bed_file->Lines(). " enriched regions $matching did match to a transcribed region, promoter or mRNA end; $not_matching did not match (".($matching/$bed_file->Lines())." % matches)." );
$result_file -> Add_2_Description ( "Promoters were defined as +5000bp and -2000bp of the transcription start;");
$result_file -> Add_2_Description ( "mRNA ends were defined as +/-250bp around the mRNA end.");
$result_file -> write_file ( $outfile );
## Do whatever you want!

