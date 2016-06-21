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

=head1 count_features_on_bed_file.pl

This tool analyzed the file obtained by using the qualify_bed_file.pl script and counts the features that were placed on the bed information.

To get further help use 'count_features_on_bed_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::plot::simpleHistogram;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $target, $feature_name,$outfile);

Getopt::Long::GetOptions(
	 "-target=s"    => \$target,
	 "-outfile=s"    => \$outfile,
	 "-feature_name" => \$feature_name,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $target) {
	$error .= "the cmd line switch -target is undefined!\n";
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
 command line switches for count_features_on_bed_file.pl

   -target       :the bed input file previousely processed by qualify_bed_file.pl
   -outfile      :the bed file including a non standard 'feature_count' column (a normal table file!)
   -feature_name :a descriptive name of the features you have analyzed here

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/count_features_on_bed_file.pl';
$task_description .= " -target $target" if (defined $target);
$task_description .= " -outfile $outfile" if (defined $outfile);


open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!
my $target_bed = stefans_libs_file_readers_bed_file->new();
$target_bed -> read_file ( $target );

$target_bed->calculate_on_columns ( {
	'data_column' => 'name', 
	'target_column' => 'feature_count',
	'function' => sub{ return scalar( split(" ",$_[0])) ; }
});

$target_bed->write_file ( $outfile );
my $histogram = stefans_libs_plot_simpleHistogram->new();
$histogram->steps(2000 );
$histogram->Y_Min( 0 );
$histogram->CreateHistogram( $target_bed->GetAsArray( 'feature_count' ) );
my $im = GD::SVG::Image->new( 800, 600 );
my $color = color->new($im);
$histogram->Xtitle( "amount of $feature_name (features)" );
$histogram->Ytitle( "amount of regions" );
$histogram->plot_2_image(
	{
		'im'            => $im,
		'x_min'         => 100,
		'y_min'         => 40,
		'x_max'         => 760,
		'y_max'         => 560,
		'color'         => $color,
		'borderColor'   => $color->{black},
		'fillColor'     => $color->{'grey'},
		'portrait'      => undef,
		'fixed_axis_is' => 'Y'
	}
);
$histogram->writePicture( $outfile );
