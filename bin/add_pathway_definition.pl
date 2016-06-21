#! /usr/bin/perl -w

#  Copyright (C) 2013-08-12 Stefan Lang

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

=head1 add_pathway_definition.pl

Add a pathway definition to a gtm pathway file.

To get further help use 'add_pathway_definition.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::file_readers::GSEA_Pathways;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $file, $name, $source, @genes);

Getopt::Long::GetOptions(
	 "-file=s"    => \$file,
	 "-name=s"    => \$name,
	 "-source=s"    => \$source,
	 "-genes=s{,}"    => \@genes,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $file) {
	$error .= "the cmd line switch -file is undefined!\n";
}
unless ( defined $name) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $source) {
	$error .= "the cmd line switch -source is undefined!\n";
}
unless ( defined $genes[0]) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
elsif ( -f $genes[0] ) {
	open( IN, "<$genes[0]" ) or die $_;
	my $hash;
	while (<IN>) {
		chomp($_);
		foreach ( split( /[\s,;]+/, $_ ) ) {
			$hash->{$_} = 1 if ( $_ =~ m/\w/ );
		}
	}
	close(IN);
	@genes = ( sort( keys %$hash ) );
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
 command line switches for add_pathway_definition.pl

   -file       :<please add some info!>
   -name       :<please add some info!>
   -source       :<please add some info!>
   -genes       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/add_pathway_definition.pl';
$task_description .= " -file $file" if (defined $file);
$task_description .= " -name $name" if (defined $name);
$task_description .= " -source $source" if (defined $source);
$task_description .= ' -genes '.join( ' ', @genes ) if ( defined $genes[0]);


## Do whatever you want!

my $obj = stefans_libs::file_readers::GSEA_Pathways->new();
$obj -> read_file( $file );
$obj -> AddPathway ($name, $source, \@genes );
$obj -> write_file ( $file );
