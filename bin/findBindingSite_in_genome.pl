#! /usr/bin/perl

use strict;
use warnings;
use stefans_libs::root;
use stefans_libs::gbFile;
use stefans_libs::fastaDB;
use stefans_libs::database::genomeDB;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use Getopt::Long;

my (
	$organism, $bindingSite, $name, $version, $cleanUp,
	$killall,  $database,    $help, $debug
);
my $true = 1 == 1;

# implementation of a search hash for iupac nucleotide codes against acgt
# iupac info site: http://www.bioinformatics.org/sms/iupac.html

my $matchHash = {
	'a' => { 'a' => 1, 'c' => 0, 'g' => 0, 't' => 0 },
	'c' => { 'a' => 0, 'g' => 0, 't' => 0, 'c' => 1 },
	'g' => { 'a' => 0, 'c' => 0, 't' => 0, 'g' => 1 },
	't' => { 'a' => 0, 'c' => 0, 'g' => 0, 't' => 1 },
	'm' => { 'g' => 0, 't' => 0, 'a' => 1, 'c' => 1 },
	'r' => { 'c' => 0, 't' => 0, 'a' => 1, 'g' => 1 },
	'w' => { 'c' => 0, 'g' => 0, 'a' => 1, 't' => 1 },
	's' => { 'a' => 0, 't' => 0, 'c' => 1, 'g' => 1 },
	'y' => { 'a' => 0, 'g' => 0, 'c' => 1, 't' => 1 },
	'k' => { 'a' => 0, 'c' => 0, 'g' => 1, 't' => 1 },
	'v' => { 't' => 0, 'a' => 1, 'c' => 1, 'g' => 1 },
	'h' => { 'g' => 0, 'a' => 1, 'c' => 1, 't' => 1 },
	'd' => { 'c' => 0, 'a' => 1, 'g' => 1, 't' => 1 },
	'b' => { 'a' => 0, 'c' => 1, 'g' => 1, 't' => 1 },
	'x' => { 'a' => 1, 'c' => 1, 'g' => 1, 't' => 1 }, 
	'n' => { 'a' => 1, 'c' => 1, 'g' => 1, 't' => 1 }  
};
my $complement = {
	'a' => 't',
	't' => 'a',
	'c' => 'g',
	'g' => 'c'
};

Getopt::Long::GetOptions(
	"-organism=s"         => \$organism,
	"-version=s"          => \$version,
	"-bindingSite=s"      => \$bindingSite,
	"-bindingSite_name=s" => \$name,
	"-clean_up=s"         => \$cleanUp,
	"-killall"            => \$killall,
	"-help"               => \$help,
	"-debug"              => \$debug

);

die &helpString("you wanted help?") if ($help);

die &helpString("we need a bindingSite!")      unless ( defined $bindingSite );
die &helpString("we need a bindingSite_name!") unless ( defined $name );
die &helpString("we need an organism!")        unless ( defined $organism );

sub helpString {
	my $error = shift;
	return $error . "
createListFromReadTable.pl returns a tab separated list of all table entries

    -organism            :the organism tag of the genome db
    -version             :the fersion of the genome db (latest version if unset)
    -bindingSite         :the sequence of the binding sites to be identified (IUPAC code)
    -bindingSite_name    :the name of the binding protein
    -clean_up            :clean up a previously killed process
    -killall             :remove all processes from the database and kill all processes
	";
}

my ( @gbArray, @gbFile_array );

my @bindingSite = split( "", lc($bindingSite) );
foreach my $base (@bindingSite) {
	die
"char $base in binding site is not compatible with the IUPAC code for DNA!\n"
	  unless ( $base =~ m/[acgtmrwsykvhdbxn]/ );
}

if ($killall) {
	warn
"now we kill all types of downstream processes. The most prominent and problematic at least...\n";
	exit;
}



unless ( defined $organism ) {
	print helpString(
"we definitly need to know which organism to use to get the sequence files!"
	);
	exit;
}

unless ( defined $version ) {
	$database = genomeDB->new()->GetDatabaseInterface_for_Organism($organism);
}
else {
	$database = genomeDB->new()
	  ->GetDatabaseInterface_for_Organism_and_Version( $organism, $version );
}

$version = "n.a." unless ( defined $version );

die
"Sorry, but we did not get a useful genome database for $organism and $version\n"
  unless ( ref($database) eq 'chromosomesTable' );

my (
	$workingTable, $loggingTable, $errorTable, $evaluation_string,
	$description,  $workload,     $next,       $gbFile,
	$splitValue,   $binding, $we_have_work_to_do, $gbFeature
);

$workingTable = workingTable->new();
$loggingTable = loggingTable->new();
$errorTable   = errorTable->new();

if ( defined $cleanUp ) {
	## Ups - we need to clean up behind an old instance....
	&remove_ThreadProblem($cleanUp, $database, $workingTable);
	exit;
}

$evaluation_string = "findBindingSite_in_genome";
$splitValue        = 30000;
my $gbFile_identiNr = 0;
$we_have_work_to_do = 1;

while ( $we_have_work_to_do ) {
	## now we have to
	## 1. set the workload table after we have checked that ;-)
	$gbFile_identiNr++;
	$next = 0;
	$description =
"organism $organism version $version gbfile_id $gbFile_identiNr add 'misc_binding' for protein $name; site = '$bindingSite'";
	$workload = $workingTable->select_workloads_for_program($evaluation_string);
	foreach my $work (@$workload) {
		if ( $work->{'description'} eq $description ) {
			print
"process $work->{'PID'} is evaluating gbFile $gbFile_identiNr at the moment\n"
			  if ($debug);
			$next = 1;    ## another process is actually working on that gbFile
		}
	}
	next if ($next);
	$workingTable->set_workload(
		{
			'programID'   => $evaluation_string,
			'description' => $description,
			'PID'         => $$
		}
	);
	## 2. check if the results are already in the DB (select all 'fulfilled_task' gbFeatures and search if ours is there
	if (
		$database->hasBeenDone(
			{
				'programID'   => $evaluation_string,
				'description' => $description
			}
		)
	  )
	{
		print "findBindingSte_in_genome -> the gbFile_id $gbFile_identiNr is already evaluated!\n";
		$workingTable->delete_workload_for_PID($$);
		next;
	}
	## 3. get the gbFile object and start to search for the interesting feature.
	$gbFile = $database->get_gbFile_for_gbFile_id( undef, $gbFile_identiNr );
	unless ( defined $gbFile ){
		$workingTable->delete_workload_for_PID($$);
		$we_have_work_to_do = 0;
		next;
	}
	warn "not a gbFile object ( $gbFile ) " unless ( ref($gbFile) eq "gbFile" );

	for ( my $i = 0 ; $i < $gbFile->Length() ; $i += $splitValue ) {
		print "we look for the binding site @bindingSite\n";
		$binding = &evaluateSeq(
			lc(
				$gbFile->Get_SubSeq(
					$i, $i + $splitValue + scalar(@bindingSite) - 1
				)
			),
			@bindingSite
		);
		## 4. add all matches to the database
		foreach my $hit (@$binding) {
			print "we got a match : $hit\n" if ($debug);
			$gbFeature = gbFeature->new( split( / +/, $hit ) );
			$gbFeature->Region()->ChangeRegion_Add( $i + 1 );
			$gbFeature->AddInfo( 'bound_moiety', $name );
			## 4.1. we need the median nucleosome positioning probability for that region!
			$gbFeature->AddInfo( 'gene', $name );
			$gbFeature->AddInfo(
				'note',
				"median probability for a nucleosome over this region = "
				  . root->median(
					$database->Get_Nulcl_prob_overall_for_region(
						{
							'gbFile_id' => $gbFile_identiNr,
							'start'     => $gbFeature->Start(),
							'end'       => $gbFeature->End()
						}
					)
				  )
			);

			if ($debug) {
				## we do not add to the databse!
				print "we would try to add the gbFeature \n",
				  $gbFeature->getAsGB(), " to the database.\n",
				  "binding seq = ",
				  $gbFile->Get_SubSeq( $gbFeature->Start(), $gbFeature->End() ),
				  "\n";
			}
			else {
				$database->AddDataset(
					{
						'gbFile' => { 'id' => $gbFile_identiNr },
						'gbFeature' => $gbFeature
					}
				);
			}
			
		}
		print "we are at the moment at $i bp\n";
	}
	## 5. add a fulfilled_task to the database
	$database->set_fulfilledTask(
		{
			'programID'   => $evaluation_string,
			'description' => $description
		}
	) unless ($debug);
	## 6. remove from the workload table
	$workload = $workingTable->select_workloads_for_PID($$);
	$workingTable->delete_workload_for_PID($$);
	## 7. add to the log table
	$loggingTable->set_log(
		{
			'programID'   => @$workload[0]->{'programID'},
			'start_time'  => @$workload[0]->{'timeStamp'},
			'description' => @$workload[0]->{'description'} . " PID $$"
		}
	) unless ($debug);
	die "we are in debug mode - exiting after one file!\n"
	  if ($debug);
}

print "we are done - all binding sites should be identified!\n";

sub evaluateSeq {
	my ( $seq, @bindingSite ) = @_;

#print "we start with seq (1-100) '",substr($seq,0,100),"' and the binding site: '",join(";",@bindingSite),"'\n";
	my ( @seq, $matching, @returnStrings, $start );    #

	@seq           = split( "", $seq );
	$matching      = 0;
	@returnStrings = ();

	#	for ( my $i = 0; $i < @bindingSite ;$i++) {
	#		print "bindingSite $i = $bindingSite[$i]\n";
	#	}

	for ( my $i = 0 ; $i < @seq ; $i++ ) {

#print "we try to match \@bindingSite[$matching] ",$bindingSite[$matching]," to \$seq[$i] $seq[$i]\n";
		if ( &match_IUPACbase_to_base( $bindingSite[$matching], $seq[$i] ) ) {

			#print "we found a forward match!\n";
			$start = $i - 1 if ( $matching == 0 );
			$matching++;
			if ( $matching == scalar(@bindingSite) ) {    ## complete match!
				print "we found a complete match: misc_binding $start..$i\n";
				push( @returnStrings, "misc_binding $start..$i" );
				$i -= $matching - 1;
				$matching = 0;
			}
		}
		else {
			$i -= $matching;
			$matching = 0;
		}
	}
	$matching = 0;
	for ( my $i = @seq - 1 ; $i >= 0 ; $i-- ) {

		if (
			&match_IUPACbase_to_base(
				$bindingSite[$matching], &complement( $seq[$i] )
			)
		  )
		{
			$start = $i if ( $matching == 0 );
			$matching++;
			if ( $matching == @bindingSite ) {    ## complete match!
				push( @returnStrings,
					"misc_binding complement(" . ( $i - 1 ) . "..$start)" );
				$i += $matching - 1;
				$matching = 0;
			}
		}
		else {
			$i += $matching;
			$matching = 0;
		}
	}
	return \@returnStrings;
}

sub remove_ThreadProblem{
	my ( $PID, $database, $workingTable ) = @_;
	my $workload = $workingTable->select_workloads_for_PID ( $PID );
	foreach my $work ( @$workload) {
		#organism $organism version $version gbfile_id $gbFile_identiNr add 'misc_binding' for protein $name; site = '$bindingSite'
		$work->{'description'} =~ m/organism $organism version $version gbfile_id (\d+) add '(.+)' for protein (.+); site = '(.+)'/;
		my  ( $gbFile_id, $tag, $name, $site ) = ( $1, $2, $3, $4 );
		unless ($database -> delete_gbFeatures_by_tag_name( { 'gbFile_id' => $gbFile_id, 'tag' => $tag, 'name' => $name } )){
			warn "we got an error while removing a dies PID:\n",$database ->{error};
			return 0;
		};
		$workingTable->delete_workload_for_PID($PID);
	}
	return 1;
}

sub complement {
	my ($base) = @_;

	return $complement->{$base};
}

sub match_IUPACbase_to_base {
	my ( $IUPACbase, $base ) = @_;

	die "not an IUPAC base ($IUPACbase)\n"
	  unless ( defined $matchHash->{ lc($IUPACbase) } );

	#print "match_IUPACbase_to_base: we try to match $IUPACbase to $base\n";
	return 0 if ( lc($base) eq 'n' || lc($base) eq 'x');
	return 0 unless ( defined $base);
	return 0 unless ( defined $complement->{$base} );
	die "OOOOOPS!! we have a unrecognized base here :'$base'\n" unless ( defined $matchHash->{ lc($IUPACbase) }->{$base} );
	return $matchHash->{ lc($IUPACbase) }->{$base};

	my $match = $matchHash->{ lc($IUPACbase) };

	#return 1 == 1 if ( lc($base) =~ m/$match/ );
	if ( lc($base) =~ m/$match/ ) {

		#print "got a match! base $base matches to $match\n";
		return 1 == 1;
	}

	#print "NO match! base $base matches to $match\n";
	return 1 == 0;
}
