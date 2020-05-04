#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-05-15 Stefan Lang

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

   binCreate.pl from git@github.com:stela2502/Stefans_Lib_Esentials.git commit 8976a18c339e2885f28ff97a1210d805eeef87d7


=head1  SYNOPSIS

    Identify_Substrings_in_Fasta_db.pl
       -fasta       :the fastq databse to process
       -strings     :a list of regexp strings to find in the sequence
       -outfile     :the table with the matching information (simple yes/no)


       -help           :print this help
       -debug          :verbose output

=head1 DESCRIPTION

  A simple string matcher that searches a fastq database for a set of strings using regexp.

  To get further help use 'Identify_Substrings_in_Fasta_db.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;


use stefans_libs::fastaDB;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $fasta, @strings, $outfile);

Getopt::Long::GetOptions(
	 "-fasta=s"    => \$fasta,
       "-strings=s{,}"    => \@strings,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $fasta) {
	$error .= "the cmd line switch -fasta is undefined!\n";
}
unless ( defined $strings[0]) {
	$error .= "the cmd line switch -strings is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/Identify_Substrings_in_Fasta_db.pl';
$task_description .= " -fasta '$fasta'" if (defined $fasta);
$task_description .= ' -strings "'.join( '" "', @strings ).'"' if ( defined $strings[0]);
$task_description .= " -outfile '$outfile'" if (defined $outfile);



use stefans_libs::Version;
my $V = stefans_libs::Version->new();
my $fm = root->filemap( $outfile );
mkdir( $fm->{'path'}) unless ( -d $fm->{'path'} );

open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!
my $fastaDB = stefans_libs::fastaDB->new( $fasta );
## the $fastaDB->{data} HASH has names as keys and seq and data
my $res = data_table->new();

$res->add_column( 'acc', keys %{$fastaDB->{'data'}} );
foreach my $acc ( keys %{$fastaDB->{'data'}} ) {
	$fastaDB->{'data'}->{$acc} = lc( $fastaDB->{'data'}->{$acc} );
}

foreach my $match ( @strings ) {
	$match = lc($match);
	print "I will match this string: '$match'\n";
	$res->add_column( $match, map { if ( $_=~m/$match/) {'yes'} else { 'no'} } values %{$fastaDB->{'data'}}  );
}

$res->write_file( $outfile );
