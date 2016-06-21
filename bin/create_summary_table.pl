#! /usr/bin/perl -w

#  Copyright (C) 2013-11-20 Stefan Lang

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

=head1 create_summary_table.pl

This script is part of the expression analysis pipeline. Coming after the pathway searches it sums up all significant pathways. These pathways are only significant on a per analysis setting.

To get further help use 'create_summary_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @infiles, $outfile );

Getopt::Long::GetOptions(
	"-infiles=s{,}" => \@infiles,
	"-outfile=s"    => \$outfile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infiles[0] ) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

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
 command line switches for create_summary_table.pl

   -infiles       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/create_summary_table.pl';
$task_description .= ' -infiles ' . join( ' ', @infiles )
  if ( defined $infiles[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );

open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

my $summary_table = data_table->new();
foreach ( 'Pathway', 'mean p value', 'times identified' ) {
	$summary_table->Add_2_Header($_);
}
$summary_table->createIndex('Pathway');
my ( @temp, $row_id, $data_table, $col_id, $col_name, $path );
## Do whatever you want!

$data_table = data_table->new();
foreach my $infile (@infiles) {
	next unless ( -f $infile && $infile =~ m/(.+)\/Tables\/0000.xls/ );
	$path = $1;
	$data_table = data_table->new();
	$data_table->read_file($infile);
	#print "infile $infile:\n".$data_table->AsTestString();
	@temp = split( "/", $path );
	$col_name =
	  join( " ", @temp[ ( scalar(@temp) - 1 ), ( scalar(@temp) - 2 ) ] );
	$col_id = $summary_table->Add_2_Header($col_name);
	$summary_table -> setDefaultValue ( $col_name, 'n.s.' );
	foreach ( @{ $data_table->GetAll_AsHashArrayRef() } ) {
		($row_id) =
		  $summary_table->get_rowNumbers_4_columnName_and_Entry( 'Pathway',
			$_->{'pathway_name'} );
		
		unless ( defined $row_id ) {
		#	print "I have a new pathway '$_->{'pathway_name'}' and create a new table line!\n";
			$summary_table->AddDataset(
				{
					'Pathway'          => $_->{'pathway_name'},
					"$col_name"        => $_->{'hypergeometric p value'},
					'mean p value'     => $_->{'hypergeometric p value'},
					'times identified' => 1
				}
			);
		}
		else {
		#	print "I change the data for pathway '$_->{'pathway_name'}':\n";
		#	print "my col id =$col_id and I have the value $_->{'hypergeometric p value'} on line $row_id\n";
			@{ @{ $summary_table->{'data'} }[$row_id] }[$col_id] =
			  "$_->{'hypergeometric p value'}";
			@{ @{ $summary_table->{'data'} }[$row_id] }[1] +=
			  $_->{'hypergeometric p value'};
		#	print "This sets the summary value to @{ @{ $summary_table->{'data'} }[$row_id] }[1]\n";
			@{ @{ $summary_table->{'data'} }[$row_id] }[2]++;
		}
	}
}
#print "The preliminary summary table:".$summary_table->AsString();
## now I need to calculate the mean p value and sort after that value!
for ( my $i = 0 ; $i < $summary_table->Lines() ; $i++ ) {
	@{ @{ $summary_table->{'data'} }[$i] }[1] = sprintf( '%.1E',
		@{ @{ $summary_table->{'data'} }[$i] }[1] /
		  @{ @{ $summary_table->{'data'} }[$i] }[2] );
}
#print "The preliminary summary table (mean):".$summary_table->AsString();
$summary_table->Sort_by(
	[ [ 'times identified', 'antiNumeric' ], [ 'mean p value', 'numeric' ] ] );
#print "The preliminary summary table (sort):".$summary_table->AsString();

$summary_table->write_file( $outfile );

