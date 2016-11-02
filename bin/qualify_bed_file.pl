#! /usr/bin/perl -w

#  Copyright (C) 2013-12-09 Stefan Lang

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

=head1 qualify_bed_file.pl

this tool uses a table containing the columns info and filename to identify bed files contining some information. 
If the information in the table is defined this information will be added to all matching bed entries in the target bed file. 
You can add a relaxing value to the search to widen up the regions in the traget file to match more information regions.

To get further help use 'qualify_bed_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $target, $source_descriptions, $outfile);

Getopt::Long::GetOptions(
	 "-target=s"    => \$target,
	 "-source_descriptions=s"    => \$source_descriptions,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $target) {
	$error .= "the cmd line switch -target is undefined!\n";
}
unless ( defined $source_descriptions) {
	$error .= "the cmd line switch -source_descriptions is undefined!\n";
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
 command line switches for qualify_bed_file.pl

   -target       :<please add some info!>
   -source_descriptions       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/qualify_bed_file.pl';
$task_description .= " -target $target" if (defined $target);
$task_description .= " -source_descriptions $source_descriptions" if (defined $source_descriptions);
$task_description .= " -outfile $outfile" if (defined $outfile);


open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

my $target_bed = stefans_libs::file_readers::bed_file->new();
$target_bed -> read_file ( $target );
for( my $i = 0; $i< $target_bed ->Lines(); $i++ ) {
	@{@{$target_bed ->{'data'}} [$i] } [3] .= " ";
}
my $descriptions_file = data_table->new();
$descriptions_file -> read_file ( $source_descriptions );
my $source_bed;

foreach my $description_hash ( @{$descriptions_file->GetAll_AsHashArrayRef() } ){
	## open the descritpion bed file
	unless ( -f $description_hash->{'file'} ) {
		warn "File not found '$description_hash->{'file'}'\n";
		next;
	}
	$source_bed = stefans_libs::file_readers::bed_file->new();
	$source_bed -> read_file ( $description_hash->{'file'} );
	print "I read the description bed file '$description_hash->{'file'}' contining values for $description_hash->{'info'}\n";
	if ( defined $description_hash->{'info'} ) {
		$description_hash->{'info'} =~s/\s+/_/g;
		for( my $i = 0; $i< $source_bed ->Lines(); $i++ ) {
			@{@{$source_bed ->{'data'}} [$i] } [3] = $description_hash->{'info'};
		}
	}
	#print "Additional info added\n";
	my $matches = $target_bed->match_to($source_bed);
	#print "I got match information to ".scalar(@$matches)." target lines\n"; 
	$target_bed->add_info_to_name($matches, $source_bed) ;
	last if ( $debug);
}

$target_bed->write_file ( $outfile );
