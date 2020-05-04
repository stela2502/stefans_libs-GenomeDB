package genomeImporter;

#  Copyright (C) 2008 Stefan Lang

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

use vars qw($VERSION);
use Net::FTP;
use stefans_libs::database::genomeDB;
use stefans_libs::database::genomeDB::genbank_flatfile_db;
use stefans_libs::database::genomeDB::genomeImporter::NCBI_genome_Readme;
use stefans_libs::database::genomeDB::genomeImporter::seq_contig;
use stefans_libs::database::genomeDB::gbFilesTable;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;

$VERSION = 0.01;

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a class to import NCBI refseq genomes from the internet and store it in a local database that can be interrogated by the lib file database::genomeDB. All files are handled as gbFiles.


=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class genomeImporter.

=cut

sub new {

	my ( $class, $databaseName, $debug ) = @_;

#	$debug = 1;
	my ($self);

	$self = {
		debug              => $debug,
		databaseDir        => "~/temp",
		NCBI_genome_Readme => NCBI_genome_Readme->new(),
		seq_contig         => seq_contig->new(),
		genomeDB           => genomeDB->new( variable_table->getDBH(),$debug ),
	};
	$self->{'database_name'} = $self->{'genomeDB'}->{'database_name'};
	$self->{'loggingTable'} =
	  stefans_libs::database::system_tables::loggingTable->new(
		$self->{'database_name'},
		$self->{'debug'} );
	$self->{'workingTable'} =
	  workingTable->new( $self->{'database_name'}, $self->{'debug'} );

#$self->{'errorTable'} = errorTable-> new( $self->{'database_name'}, $self->{'debug'});

	bless $self, $class if ( $class eq "genomeImporter" );

	return $self;

}

sub expected_dbh_type {

	#return 'dbh';
	return "not a database interface";

	#return "database";
}

sub genbank_flatfile_db {
	my ( $self ) = @_;
	unless ( defined $self->{genbank_flatfile_db} ) {
		$self->{genbank_flatfile_db} = genbank_flatfile_db->new( { 'debug' => $self->{'debug'}, 'tempPath' => "$self->{databaseDir}/originals" } );
	}
	return $self->{genbank_flatfile_db};
}

sub import_refSeq_genome_for_organism {
	my ( $self, $organism, $releaseDate, $version, $referenceTag,
		$even_spacing ) = @_;
	my (
		$files,     $table_string, $rv,       $gbFile, $dbLibFiles,
		$processed, $refTag,       $seq_file, $exists
	);
	$files =
	  $self->download_refseq_genome_for_organism( $organism, $version, $even_spacing );
	
	$self->{seq_contig} -> parse_order($self->Extract_gbFiles($files, $even_spacing), $even_spacing, $referenceTag ) 
	  unless ( -f "$self->{databaseDir}/originals/extracted.txt" ) ;
	  
	$self->{seq_contig}-> write_file ( "$self->{databaseDir}/originals/chr_ranges.txt" ) if ( @{$self->{seq_contig}->{'data'}} > 0 );
	if ( -f  "$self->{databaseDir}/originals/chr_ranges.txt" ){
		$self->{seq_contig}
	  ->readFile( "$self->{databaseDir}/originals/chr_ranges.txt" );
	}
	if ( -f $files->{seq_contig} ) {
		$self->{seq_contig}
	  ->readFile( $files->{seq_contig} );
	}
	
	unless ( defined $releaseDate ) {
		warn "You have not supplied a release data - I check whether I can identify it:\n";
		$self->{NCBI_genome_Readme}->readFile( $files->{readme} );
	}
	else {
		$self->{NCBI_genome_Readme}->ReleaseDate( $self->{NCBI_genome_Readme}
			  ->convert_NCBI_date_to_mysql($releaseDate) );
		$self->{NCBI_genome_Readme}->ReferenceTag($referenceTag);
		$self->{NCBI_genome_Readme}->Version($version);
	}

	if ( $self->{debug} ) {
		print ref($self) . " we have got ", $self->{seq_contig}->readLines(),
		  " lines in the seq_contig file\n";
	}
	unless ( $self->{seq_contig}->readLines() > 1 ) {
		Carp::confess ref($self),
		  ":import_refSeq_genome_for_organism -> problem:",
		  "we do not have entries in the seq_contig file (",
		  $self->{seq_contig}->readLines(), ")!";
	}

	## now we should have a pretty complete list of gbFiles for the refseq assemby (H_sapiens)
	## in the genbank_flatfile_db object

	#$self->{genomeDB}->create() unless ( $self->{genomeDB}->tableExists() );

	$table_string = $self->{genomeDB}->AddDataset(
		{
			'version'      => $self->{NCBI_genome_Readme}->Version(),
			'organism'     => { 'organism_tag' => $organism },
			'creationDate' => $self->{NCBI_genome_Readme}->{data}->{releaseDate}
		}
	);

	my $chromosm_interface =
	  $self->{genomeDB}->GetDatabaseInterface_for_Organism_and_Version($organism, $version);
	$chromosm_interface = $chromosm_interface->get_rooted_to('gbFilesTable');

	my ( $sth, $sql, $dataset );

	$sql = $chromosm_interface->create_SQL_statement(
		{
			'search_columns' => ['gbFilesTable.id'],
			'where'          => [ [ 'gbFilesTable.acc', '=', 'my_value' ] ]
		}
	);
	$sql =~ s/'\?'/?/;
	$sth = $chromosm_interface->{'dbh'}->prepare($sql);
	print "now we try to read all genomic regions using the object "
	  . ref( $self->{seq_contig} ) . "\n";
	$processed = 0;
	$refTag    = $self->{'NCBI_genome_Readme'}->ReferenceTag();

	while ( my $chrInfo = $self->{seq_contig}->getNext() ) {
		next
		  if ( $chrInfo->{feature_name} eq "start"
			|| $chrInfo->{feature_name} eq "end" );

		print ref($self)
		  . "_we try to match Version $chrInfo->{feature_name}; ReferenceTag:"
		  . $self->{NCBI_genome_Readme}->ReferenceTag() . " to "
		  . $chrInfo->{group_label}
		  . "\n";    # if ( $self->{'debug'});

		if ( defined $chrInfo->{group_label}
			&& $chrInfo->{group_label} =~ m/$refTag/ )
		{
			next if ( $chrInfo->{group_label} =~ m/PATCHES/ );
			$chrInfo->{group_label} = $refTag;
			## first we might check, if the file is already in the database - or?
			$processed++;
			if ( $chromosm_interface ->_exists(  $chrInfo->{feature_name} ) ) {
				print "this gbFile has already been imported ($chrInfo->{feature_name})\n";
				next;
			}

			$gbFile = $self->genbank_flatfile_db()->get_gbFile_obj_for_version($chrInfo->{feature_name} );
			
			unless ( ref($gbFile) eq "gbFile" ) {
				Carp::confess(
					root::print_hashEntries(
						$files,
						3,
"I could not find the gbFile $chrInfo->{feature_name} in these files!\n"
					)
				);
			}
			print ref($self) . ":we add the gbFile ". $gbFile->getAsGB() . " to the Database\n" if ( $self->{debug} );
			
			$self->Add_One_GB_file ( {'gbFile' => $gbFile,'chromosome' => $chrInfo,'sequence_file' => $seq_file},$chromosm_interface );
		
			$gbFile->DESTROY();
		}
		elsif ( $self->{debug} ) {
			print ref($self)
			  . " we do not insert the entry with group lable $chrInfo->{group_label}, ",
			  "as it does not match with the reference value ",
			  $self->{NCBI_genome_Readme}->ReferenceTag(), "\n";
		}

	}
	if ( $processed == 0 ) {
		warn
		  "Oh we had an issue here - we have not touched any sequence file!\n"
		  . "I suggest we have once more an issue with the ReferenceTag '"
		  . $self->{NCBI_genome_Readme}->ReferenceTag() . "'\n";
	}
	return 1;
}



sub Add_One_GB_file {
	my ( $self, $dataset, $chromosm_interface ) = @_;
	#print "\$exp = ".root->print_perl_var_def( $dataset ).";\n";
	#print  join(", ", keys %{$chromosm_interface->{'data_handler'}})."\n";
	my $chr_id = $chromosm_interface ->{'data_handler'} -> {chromosomesTable} -> AddDataset(  $dataset->{chromosome}  );
	## now I can add the gbFile sequence
	my $seq_file =  "$self->{databaseDir}/tmp/" .$dataset->{gbFile}->Version() . ".data";
	open( OUT, ">$seq_file" ) or die "I can not create the temp data file '$seq_file'\n";
	print OUT $dataset->{gbFile}->Sequence();
	close(OUT);	
	my $file_id = $chromosm_interface ->{'data_handler'} -> {external_files} -> AddDataset ( {'mode' => 'text', 'filetype' => 'data_file', 'filename' => $seq_file } );
	unlink ( $seq_file ); ## the data has already been copied to the database!
	my $gbFile_id = $chromosm_interface->AddDataset( { 
		'acc' => $dataset->{'gbFile'}->Version(),
		'header' => $dataset->{'gbFile'}->{header}->getAsGB(),
		'seq_id' => $file_id,
		'chromosome_id' => $chr_id,
		'masked_seq_id' => 0,
	} );
	$chromosm_interface->Add_all_gbFeatures($gbFile_id, {'gbFile' => $dataset->{'gbFile'} } );
	return $gbFile_id;
}

sub download_refseq_genome_for_organism {
	my ( $self, $organism, $version, $even_spacing, $file_match ) = @_;
	my ( @directory, @CHR_dir, $return, $already_read, @wget );
	$file_match ||= 'gbk.gz';
	$self->{databaseDir} .= "/$organism";
	print "Database Dir = $self->{databaseDir} \n" if ( $self->{debug} );
	if ( -d "$self->{databaseDir}" ) {
		warn "the dataset has already been downloaded!\nSTOP?\n";
		opendir( DIR,  "$self->{databaseDir}/" );
		my @entries = grep !/.filelist$/,readdir(DIR);
		closedir(DIR);

		foreach my $file (@entries) {
			$return->{seq_contig} = "$self->{databaseDir}/$file"
			  if ( $file eq "seq_contig.md.gz" );
			$return->{readme} = "$self->{databaseDir}/$file"
			  if ( $file eq "README_CURRENT_BUILD" );
			if ( $file =~ m/$file_match/ ) {
				push( @{ $return->{gbLibs} }, "$self->{databaseDir}/$file" );
				$already_read->{"$self->{databaseDir}/$file"} = 1;
			}
		}

	}
	else {
		system("mkdir -p $self->{databaseDir}") unless ( -d $self->{databaseDir});
	}
	if ( $self->{'noDownload'} ) {
		Carp::confess(
"Sorry - I got the noDownload option and did not find the gbFiles in the folder '$self->{databaseDir}'.\n"
			  . "Please make sure I find all important files there and re-run.\n"
		) unless ( scalar( @{ $return->{gbLibs} } ) > 0 );
		$self->Extract_gbFiles($return) if ($file_match eq 'gbk.gz' );
		return $return;
	}
	my $ftp = Net::FTP->new( 'ftp.ncbi.nlm.nih.gov', Debug => 1 )
	  or die "Cannot connect to some.host.name: $@";

	$ftp->login( "anonymous", 'st.t.lang@gmx.de' )
	  or die "Cannot login ", $ftp->message;

	$ftp->cwd("/genomes/$organism/ARCHIVE/$version/")
	  or die "Cannot change working directory ", $ftp->message;
	system( "wget ftp.ncbi.nlm.nih.gov/genomes/$organism/ARCHIVE/$version/README_CURRENT_BUILD -O $self->{databaseDir}/README_CURRENT_BUILD" );
	unless ( -f "$self->{databaseDir}/README_CURRENT_BUILD" ){
		## OK M_musculus uses a 'README_CURRENT_RELEASE' file instead
		system( "wget ftp.ncbi.nlm.nih.gov/genomes/$organism/ARCHIVE/$version/README_CURRENT_RELEASE -O $self->{databaseDir}/README_CURRENT_RELEASE" );
		$return->{readme} = "$self->{databaseDir}/README_CURRENT_RELEASE";
	}
	else {
		$return->{readme} = "$self->{databaseDir}/README_CURRENT_BUILD";
	}

	$ftp->binary();
	unless ( defined $even_spacing ) {
		unless ( -f "$self->{databaseDir}/seq_contig.md.gz"
			|| -f "$self->{databaseDir}/seq_contig.md" )
		{
			$ftp->get( "mapview/seq_contig.md.gz",
				"$self->{databaseDir}/seq_contig.md.gz" )
			  or die "Cannot load the file mapview/seq_contig.md.gz ",
			  $ftp->message;
			$return->{seq_contig} = "$self->{databaseDir}/seq_contig.md.gz";
		}
	}
	my $rv;
	@directory = $ftp->ls();
	$return->{'gbLibs'} = [];
	foreach my $entry (@directory) {

		if ( $entry =~ m/(CHR_)([\d\w]+)/ ) {
			$ftp->cwd("$1$2");
			@CHR_dir = $ftp->ls();
			foreach my $file (@CHR_dir) {
				if ( $file =~ m/ref/ ) {
					if ( $file =~ m/$file_match/ ) {
						unless ( -f  "$self->{databaseDir}/$file" ) {
							#die "Does the file $self->{databaseDir}/$file really not exists?\n";
							my $cmd = "wget  ftp.ncbi.nlm.nih.gov/genomes/$organism/ARCHIVE/$version/$entry/$file -O $self->{databaseDir}/$file\n";
							print  $cmd ;
							system( $cmd );
							push (@wget, $cmd );
						}
						push ( @{ $return->{'gbLibs'} }, "$self->{databaseDir}/$file"  ) if ( -f "$self->{databaseDir}/$file" );
					}
				}
			}
			$ftp->cwd('../');
		}
	}
	$ftp->quit;
	## now I started to use bacteria genomes too. They can not easily be imported using this tool and I only need one of them for test purposes.
	## hence I implement that quick and dirty - and I case a waring!
	if ( scalar( @{ $return->{'gbLibs'} } ) == 0 ) {
		warn
"WARNING: I was unable to download any data!\nI try to recover using the output path you gave me ($self->{databaseDir})!\n";
		opendir( DIR, "$self->{databaseDir}" ) or die "$!\n";
		foreach ( grep { /(CHR_)([\d\w]+)/ } readdir(DIR) ) {
			push( @{ $return->{'gbLibs'} }, "$self->{databaseDir}/$_" )
			  if ( -f "$self->{databaseDir}/$_" );
		}
		close(DIR);
	  Carp: confess("I was unable to identify the requitred sequence data!\n")
		  unless ( scalar( @{ $return->{'gbLibs'} } ) > 0 );
	}
## now we have to import the info into the database!!
	#$self->Extract_gbFiles($return);

	return $return;
}

sub Extract_gbFiles {
	my ( $self, $files, $even_spacing, $reference_tag ) = @_;
	## now we have to import the info into the database!!
	my $dbLibFiles = 0;
	my @order;
	foreach my $gbLibFile ( @{ $files->{gbLibs} } ) {
		$dbLibFiles++;
		push(@order, $self->genbank_flatfile_db()->loadFlatFile($gbLibFile, $even_spacing,$reference_tag ) );
	}
	if ( defined $even_spacing ) {
		
	}
	open( LOG, ">$self->{databaseDir}/originals/extracted.txt" );
	print LOG "No problems\n";
	close(LOG);
	return \@order;
}

1;
