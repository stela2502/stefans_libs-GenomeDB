#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-02-02 Stefan Lang

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

    extend_summits.pl
       -summits     :a list of bed files
       -outpath     :an optional outpath (default same path as infile)
       -extend      :bp to extend the region on both ends (default 250 => min 500bp regions)


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Extends the summits with -help[1]-extend 2+extend-1

  To get further help use 'extend_summits.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @summits, $outpath, $extend);

Getopt::Long::GetOptions(
       "-summits=s{,}"    => \@summits,
	 "-outpath=s"    => \$outpath,
	 "-extend=s"    => \$extend,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $summits[0]) {
	$error .= "the cmd line switch -summits is undefined!\n";
}
unless ( defined $outpath) {
	$outpath  = root->filemap($summits[0])->{'path'};
}
unless ( defined $extend) {
	$extend = 250;
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

$task_description .= 'perl '.$plugin_path .'/extend_summits.pl';
$task_description .= ' -summits "'.join( '" "', @summits ).'"' if ( defined $summits[0]);
$task_description .= " -outpath '$outpath'" if (defined $outpath);
$task_description .= " -extend '$extend'" if (defined $extend);



mkdir( $outpath ) unless ( -d $outpath );
open ( LOG , ">$outpath/".$$."_extend_summits.pl.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!
my ( $fm, $ofile,@line );
foreach my $file ( @summits ) {
	open ( IN, "<$file" ) or die "I could not open the summit file '$file'\n$!\n";
	$fm = root->filemap( $file);
	$ofile = "$outpath/$fm->{'filename_base'}_ext_$extend.bed";
	open ( OUT, ">$ofile" ) or die "I could not create ofile '$ofile'\n$!\n";
	while ( <IN> ) {
		@line=split("\t", $_ );
		$line[1] -= $extend;
		$line[1] = 1 if ( $line[1] < 1);
		$line[2] += $extend -1;
		print OUT join("\t", @line);
	}
}
