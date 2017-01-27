#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-01-26 Stefan Lang

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

    Picard_metrix2table.pl
       -files     :<please add some info!> you can specify more entries to that
       -outfile       :<please add some info!>


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  read a list of picard 2.8.2 metrix files and collect the important information into a tab separated summary table. The picards outfiles should be produced with the hisat2 mapping script in my SLURM lib.

  To get further help use 'Picard_metrix2table.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

use stefans_libs::flexible_data_structures::data_table;


my $VERSION = 'v1.0';


my ( $help, $debug, $database, @files, $outfile);

Getopt::Long::GetOptions(
       "-files=s{,}"    => \@files,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $files[0]) {
	$error .= "the cmd line switch -files is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/Picard_metrix2table.pl';
$task_description .= ' -files "'.join( '" "', @files ).'"' if ( defined $files[0]);
$task_description .= " -outfile '$outfile'" if (defined $outfile);


my $fm = root->filemap($outfile);
unless ( -d $fm->{'path'} ){
	mkdir( $fm->{'path'} );
}
open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!
my $data_table = data_table->new({no_doubble_cross=>1});
my ( $data,$header );
foreach my $file ( @files ) {
	( $data,$header ) = &file2_hash($file);
	unless ( scalar @{$data_table->{'data'}} ){
		$data_table->Add_2_Header($header);
	}
	push(@{$data_table->{'data'}}, $data);
}

$data_table->write_file($outfile);

sub file2_hash {
	my $file = shift;
	open ( IN, "<$file" ) or die "I could not read file '$file'\n$!\n";
## METRICS CLASS	picard.sam.DuplicationMetrics
#LIBRARY	UNPAIRED_READS_EXAMINED	READ_PAIRS_EXAMINED	SECONDARY_OR_SUPPLEMENTARY_RDS	UNMAPPED_READS	UNPAIRED_READ_DUPLICATES	READ_PAIR_DUPLICATES	READ_PAIR_OPTICAL_DUPLICATES	PERCENT_DUPLICATION	ESTIMATED_LIBRARY_SIZE
#Unknown Library	329313	3112395	452710	676791	234513	311203	0	0.130745	14508057
	my $read = 0;
	my ( @headers, @data );
	while( <IN> ) {
		if ( $_ =~ m/^## METRICS CLASS/ ){
			$read = 1;
			next;
		}
		if ( $read == 1 ) {
			## headers
			chomp;
			@headers = split("\t", $_ );
			$read ++;
			next;
		}
		if( $read == 2 ){
			chomp;
			@data = split("\t", $_ );
			$read ++;
			last;
		}
	}
	close ( IN );
	unshift(@headers, 'filename' );
	unshift(@data, $file );
	return \@data, \@headers;
}