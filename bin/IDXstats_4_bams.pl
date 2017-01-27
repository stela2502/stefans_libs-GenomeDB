#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-12-01 Stefan Lang

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

    IDXstats_4_bams.pl
       -bams     :a list of sorted bam files
       -outfile  :the result outfile
       -n        :numer of processes to run

       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  create a table with the idxstats that the samtools package provides for a list of sorted bam files. This script will create the indices if necessary.

  To get further help use 'IDXstats_4_bams.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::flexible_data_structures::data_table;
use Parallel::ForkManager;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @bams, $outfile, $n);

Getopt::Long::GetOptions(
       "-bams=s{,}"    => \@bams,
	 "-outfile=s"    => \$outfile,
	 "-n=s"          => \$n,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $bams[0]) {
	$error .= "the cmd line switch -bams is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( $n ) {
	$n = 3;
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

$task_description .= 'perl '.$plugin_path .'/IDXstats_4_bams.pl';
$task_description .= ' -bams "'.join( '" "', @bams ).'"' if ( defined $bams[0]);
$task_description .= " -outfile '$outfile'" if (defined $outfile);
$task_description .= " -n $n";



open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

my $pm = Parallel::ForkManager->new($n);



FILES:
foreach my $file ( @bams ) {
	my $pid = $pm->start and next FILES;
	unless ( -f "$file.bai" ) {
		system( "samtools index $file" );
	}
	my $in;
	unless ( -f "$file.idxstat"){
		print "running samtools: 'samtools idxstats $file > $file.idxstat'\n";
		system( "samtools idxstats $file > $file.idxstat" );
	}
	
	$pm->finish; # Terminates the child process
}

$pm->wait_all_children;

print  "Calculation finished - summing up\n";
my $result = data_table->new();

my ( $this_idxstat, $hash );
foreach my $file ( @bams ) {
	unless ( -f "$file.idxstat"){
		Carp::confess ( "ERROR: file $file.idxstat does not exist" );
	}
	$this_idxstat = &read_idxfile ( "$file.idxstat" );
	if ( $result->Rows() == 0 ) {
		$result -> Add_2_Header( ['filename', @{$this_idxstat->GetAsArray('ref.seq. name')} ] );
		$hash = $this_idxstat->GetAsHash('ref.seq. name', 'ref.seq. length');
		$hash->{'filename'} = "chr length";
		$result -> AddDataset($hash);
	}
	$hash = $this_idxstat->GetAsHash('ref.seq. name', 'number of mapped reads');
	$hash->{'filename'} = $file;
	$hash ->{'unmapped'} = &sum(@{$this_idxstat->GetAsArray('number of unmapped reads')});
	$result -> AddDataset($hash);
}

$result->write_file( $outfile );

sub sum{
	my $sum = 0;
	foreach ( @_ ) {
		$sum += $_;
	}
	$sum;
}
sub read_idxfile{
	my ( $file ) = @_;
	my $data_table = data_table->new();
	$data_table->Add_2_Header( [ 'ref.seq. name', 'ref.seq. length', 'number of mapped reads', 'number of unmapped reads'] );
	open ( IN , "<$file" ) or die "I could not open the file $file\n$!\n";
	
	while ( <IN> ) {
		chomp($_);
		print "$file: $_\n" if ( $debug );
		push ( @{$data_table -> {'data'}} , [ split( "\t", $_ )] ) ;
	}
	close ( IN );
	@{@{$data_table->{'data'}}[($data_table->Rows()-1)]}[0] = "unmapped";
	return $data_table;
}