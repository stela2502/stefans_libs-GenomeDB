#! /usr/bin/perl -w

#  Copyright (C) 2014-03-19 Stefan Lang

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

=head1 transfere_genome.pl

This tool helps to transfere a genome database between two server installations.

To get further help use 'transfere_genome.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::database::genomeDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $organism, $version, $outpath, $restore );

Getopt::Long::GetOptions(
	"-organism=s" => \$organism,
	"-version=s"  => \$version,
	"-outpath=s"  => \$outpath,
	"-restore"    => \$restore,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $organism ) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version ) {
	$error .= "the cmd line switch -version is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
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
 command line switches for transfere_genome.pl

   -organism       :<please add some info!>
   -version       :<please add some info!>
   -outpath       :<please add some info!>
   -restore       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/transfere_genome.pl';
$task_description .= " -organism $organism" if ( defined $organism );
$task_description .= " -version $version"   if ( defined $version );
$task_description .= " -outpath $outpath"   if ( defined $outpath );
$task_description .= " -restore"   if ( defined $restore );

mkdir($outpath) unless ( -d $outpath );
open( LOG, ">$outpath/transfere_genome.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

my $genome = genomeDB->new();

if ($restore) {
	my $data_table = data_table->new(
		{ 'filename' => "$outpath/$organism.$version.files_description.xls" } );
	Carp::confess(
"I do not have the necessary information ('outpath/$organism.$version.files_description.xls')"
	) unless ( $data_table->Lines() > 0 );
	## first check whether the data is alread in the database!
	my $ok = 0;
	my $db_ok = 0;
	eval { 
		my $interface =
	  $genome->GetDatabaseInterface_for_Organism_and_Version( $organism,
		$version );
		$interface = $interface->get_rooted_to('gbFilesTable');
		my $data_table = $interface -> get_data_table_4_search( {
		     	'search_columns' => ['seq_id', 'acc'],
		     	'where' => [ [ref($interface).".id", '=', 'my_value'] ], }, 1);
		$db_ok = 1 if ( $data_table->Rows() );
		if ( -f "$interface->{'data_handler'}->{'external_files'}->{'data_path'}".@{@{$data_table->{'data'}}[0]}[0].".dta" ){
			open ( GOOD, "<$outpath/@{@{$data_table->{'data'}}[0]}[0].data");
			open ( TEST, "<$interface->{'data_handler'}->{'external_files'}->{'data_path'}".@{@{$data_table->{'data'}}[0]}[0].".dta" );
			$ok = 1 if ( join('', <GOOD>) eq join('',<TEST>) );
			close ( TEST);
			close ( GOOD );
		}
	};
	if ( $ok ) {
		print "The data is already in the database and the file doe exist - I do nothing here!\n";
		exit 0;
	}
	
	my ( $connection, $database_name ) = variable_table->getDBH_Connection();
	my $cmd =
"mysql -u$connection->{'dbuser'} -p$connection->{'dbPW'} $database_name < $outpath/create_genome_entry_2_$organism.$version.sql";
	if ($debug) {
		print $cmd. "\n";
	}
	else {
		system($cmd );
	}
	if ( $db_ok ) {
		print "The database structure seams to be OK - if I guess wrong please insert the $outpath/$organism.$version.sql manualy into the db\n".
		"mysql -u<user> -p $database_name < $outpath/$organism.$version.sql\n";
	}
	else {
	$cmd =
"mysql -u$connection->{'dbuser'} -p$connection->{'dbPW'} $database_name < $outpath/$organism.$version.sql";
	if ($debug) {
		print $cmd. "\n";
	}
	else {
		system($cmd );
	}
	}
	## now I need to relink the external files!
	my $interface =
	  $genome->GetDatabaseInterface_for_Organism_and_Version( $organism,
		$version );
	$interface = $interface->get_rooted_to('gbFilesTable');
	my $inpath =
	  $interface->{'data_handler'}->{'external_files'}->{'data_path'};
	my $id;
	for ( my $i = 0 ; $i < $data_table->Rows() ; $i++ ) {
		## get the file re-named
		$id = $interface->{'data_handler'}->{'external_files'}->AddDataset(
			{
				'filename' => "$outpath/@{@{$data_table->{'data'}}[$i]}[1]",
				'filetype' => 'data_file',
				'mode'     => 'text'
			}
		);
		print "Update ".$interface->TableName(). " set seq_id = $id where seq_id =  @{@{$data_table->{'data'}}[$i]}[0];\n";
		$interface-> {'dbh'} ->do("Update ".$interface->TableName(). " set seq_id = $id where seq_id =  @{@{$data_table->{'data'}}[$i]}[0]") or die $interface-> {'dbh'}->errstr();
	}
	print "Done\n";
}
else {
	$genome->{'use_this_sql'} = "show tables like '$organism%'";
	my $data_table = $genome->get_data_table_4_search(
		{
			'search_columns' => ['table.name'],
			'where'          => [],
		}
	);
	my ( $connection, $database_name ) = variable_table->getDBH_Connection();
	my $cmd =
"mysqldump -u$connection->{'dbuser'} -p$connection->{'dbPW'} $database_name "
	  . join( " ", @{ $data_table->GetAsArray('table.name') } )
	  . "> $outpath/$organism.$version.sql";
	if ($debug) {
		print $cmd . "\n";
	}
	else {
		system($cmd );
	}
	## now I need to get the insert genome and organism strings.
	open( OUT, ">$outpath/create_genome_entry_2_$organism.$version.sql" )
	  or die
"Could not create the file '$outpath/create_genome_entry_2_$organism.$version.sql'\n$!\n";
	$cmd = $genome->{'data_handler'}->{'organismDB'}
	  ->_create_insert_statement('organism_name');
	$cmd =~ s/\?/'$organism'/;
	$cmd .= ";\n";
	print $cmd if ($debug);
	print OUT $cmd;

	$cmd = $genome->_create_insert_statement('id');
	$cmd =~ s/\?/'$version'/;
	$cmd =~ s/\?/( select id from organism where organism_tag = '$organism' )/;
	my $tmp = root::Today();
	$cmd =~ s/\?/'$tmp'/;
	my $interface =
	  $genome->GetDatabaseInterface_for_Organism_and_Version( $organism,
		$version );
	$tmp = $interface->TableBaseName();
	$cmd =~ s/\?/'$tmp'/;
	print $cmd.";\n" if ($debug);
	print OUT $cmd.";\n";
	close(OUT);
	## and here comes the external files management problem....
	$interface = $interface->get_rooted_to('gbFilesTable');
	$interface->{'use_this_sql'} =
"select id, filename ,filetype, upload_time, mode from external_files where id IN ( select seq_id from "
	  . $interface->TableName() . ")";
	$data_table = $interface->get_data_table_4_search(
		{
			'search_columns' =>
			  [ 'id', 'filename', 'filetype', 'upload_time', 'mode' ],
			'where' => [],
		},
	);
	my $inpath =
	  $interface->{'data_handler'}->{'external_files'}->{'data_path'};
	for ( my $i = 0 ; $i < $data_table->Rows() ; $i++ ) {
		## get the file re-named
		$tmp = root->filemap( @{@{$data_table->{'data'}}[$i]}[1] ); 
		@{@{$data_table->{'data'}}[$i]}[1] = $tmp ->{'filename'};
		system(
"cp $inpath/@{@{$data_table->{'data'}}[$i]}[0].dta $outpath/@{@{$data_table->{'data'}}[$i]}[1]"
		) unless ( -f "$outpath/@{@{$data_table->{'data'}}[$i]}[1]" );
	}
	$data_table->write_file(
		"$outpath/$organism.$version.files_description.xls");
	print "Done\n";

}

