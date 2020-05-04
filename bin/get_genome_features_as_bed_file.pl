#! /usr/bin/perl -w

#  Copyright (C) 2013-10-16 Stefan Lang

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

=head1 get_genome_features_as_bed_file.pl

This script should become as flexible as posible to get any genome feature (NOT a ROI) out from the database and into bed file.

To get further help use 'get_genome_features_as_bed_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $organism, $version, $outfile, @features );

Getopt::Long::GetOptions(
	"-organism=s"    => \$organism,
	"-version=s"     => \$version,
	"-outfile=s"     => \$outfile,
	"-features=s{,}" => \@features,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $organism ) {
	$error .= "the cmd line switch -organism is undefined!\n";
}

#unless ( defined $version) {
#	$error .= "the cmd line switch -version is undefined!\n";
#}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

#unless ( defined $features[0]) {
#	$error .= "the cmd line switch -features is undefined!\n";
#}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for get_genome_features_as_bed_file.pl

   -organism       :<please add some info!>
   -version       :<please add some info!>
   -outfile       :<please add some info!>
   -features       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/get_genome_features_as_bed_file.pl';
$task_description .= " -organism $organism" if ( defined $organism );
$task_description .= " -version $version"   if ( defined $version );
$task_description .= " -outfile $outfile"   if ( defined $outfile );
$task_description .= ' -features ' . join( ' ', @features )
  if ( defined $features[0] );

open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!

use stefans_libs::database::genomeDB;
use stefans_libs::file_readers::bed_file;
## Do whatever you want!

my $genomeDB = genomeDB->new( variable_table->getDBH() );
my $interface =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( $organism,
	$version );

## so now lets see whether I manage to get that done
## features

my $bed_file = $interface->get_as_bed_file(
	{ 
		'tag' => 'gene',
#		's_start' => 5000, 
#		's_end' => 2000 
	}
);

$bed_file->write_file($outfile);

