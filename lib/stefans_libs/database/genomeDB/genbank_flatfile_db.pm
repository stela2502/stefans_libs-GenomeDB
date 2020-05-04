package genbank_flatfile_db;

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

use strict;
use warnings;
use stefans_libs::gbFile;
use stefans_libs::flexible_data_structures::data_table;


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a wrapper around a genbank flatfile to be used to import the database

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class genbank_flatfile_db.

=cut

sub new {

	my ( $class, $hash ) = @_;

	my ($self);
	unless ( ref($hash) eq "HASH") {
		$hash = { 'debug' => $hash };
	}
	$self = {
		debug    => $hash->{'debug'},
		tempPath => $hash->{'tempPath'},
		files    => {},
	};
	$self->{'tempPath'} ||= "/home/stefan_l/temp";
	unless ( -d $self->{'tempPath'} ){
		mkdir ( $self->{'tempPath'} );
	}
	bless $self, $class if ( $class eq "genbank_flatfile_db" );

	return $self;

}

sub expected_dbh_type {

	#return 'dbh';
	return "not a database interface";
	return "database";
}

sub loadFlatFile {
	my ( $self, $flatfile, $even_spacing ) = @_;
	return () if ($flatfile =~ m/.filelist$/ );
	$even_spacing |= 100
	  ; ## the new H_Sapiens database has a 100bp spacing of the gb files, but no seq_contig file.
	print "$self tries to read the flatfile '$flatfile'\n"
	  if ( $self->{debug} );
	my @order;

	if ( -f $flatfile . ".filelist" ) {
		print
"I suppose we already have processed this file '$flatfile'!\nReading from log\n";
		open( LOG, "<$flatfile.filelist" )
		  or die "I could not open the log file $flatfile.filelist\n$!\n";
		my @tmp;
		foreach (<LOG>) {
			chomp($_);
			@tmp = split( "\t", $_ );
			$self->{files}->{ $tmp[0] } = $tmp[1];
			push( @order, $tmp[0] );
		}
		close(LOG);
	}
	else {
		open( LOG, ">$flatfile.filelist" )
		  or die "I could not create the log file '$flatfile.filelist'\n$!\n";

		if ( $flatfile =~ m/\.gz$/ ) {
			## we have a gzipped file!
			open( IN, "gunzip $flatfile |" )
			  or die
			  "problem with the gunzip layer ('$flatfile')?\n$!\n";
		}
		else {
			open( IN, "<$flatfile" )
			  or die "can not read the genbank flatfile $flatfile\n";
		}
		my ( @gbFile, $version, $mode, $line );

		$mode = 0;   # 0 == search for gbEntry start; 1 == colectionO_of_GbEntry
		$line = 0;
		my $chromosome = $1 if ( $flatfile =~ m/[Cc]hr([\w\d]+)\.gbk/ );
		Carp::confess(
"Not a suitable file: '$flatfile'\nI was unable to identify the chromosome!\n"
		) unless ($chromosome);
		while (<IN>) {
			$line++;
			if ( $mode == 0 ) {
				die "strange line in gbFlatfile $flatfile in line $line\n$_"
				  unless ( $_ =~ m/^LOCUS/ );
				$mode = 1;
			}
			if ( $_ =~ m/^LOCUS\s+([\w_\d+\.]*)\s+(\d+) bp/ ) {
				push( @order, [ $chromosome, $1, $2 ] );
			}
			push( @gbFile, $_ );
			if ( $_ =~ m/^VERSION +([\w\d\.]+) +.+/ ) {
				$version = $1;
				@{ @order[ @order - 1 ] }[1] = $version;
				if ( -f ">$self->{tempPath}/$version.gb" ) {
					warn
"ups - the file was processed earlier? aborting the export of gbFiles.\nThis saves a lot of time!\n";
					opendir( DIR, $self->{tempPath} );
					my @dir = readdir(DIR);
					foreach my $filename (@dir) {
						if ( $filename =~ m/([\w\d]+)\.gb/ ) {
							$version = $1;
							$self->{files}->{$version} =
							  "$self->{tempPath}/$version.gb";
						}
					}
					closedir(DIR);
					last;
				}
			}
			if ( $_ =~ m!^ *// *$! ) {
				## end of one gbEntry!
				open( GBfile, ">$self->{tempPath}/$version.gb" )
				  or die
"could not open temporary file $self->{tempPath}/$version.gb\n$!\n";
				print GBfile join( "", @gbFile );
				close(GBfile);
				print LOG $version . "\t$self->{tempPath}/$version.gb\n";
				$self->{files}->{$version} = "$self->{tempPath}/$version.gb";
				@gbFile                    = ();
				$version                   = "";
			}
		}
		close(IN);
		if ( $version =~ m/\w/ ) {
			open( GBfile, ">$self->{tempPath}/$version.gb" )
			  or die
"could not open temporary file $self->{tempPath}/$version.gb\n$!\n";
			print GBfile join( "", @gbFile );
			close(GBfile);
			print LOG $version . "\t$self->{tempPath}/$version.gb\n";
			$self->{files}->{$version} = "$self->{tempPath}/$version.gb";
		}
		close(LOG);
	}
	return @order;
}

sub getInfo_as_data_table {
	my ( $self ) = @_;
	my $result = data_table->new();
	$result -> Add_2_Header ( ['name','filename', 'size'] );
	foreach my $version ( sort keys %{ $self->{files} } ) {
		$result -> AddDataset( { 'name' => $version, 'filename' => $self->{files}->{$version}, 'size' => -S $self->{files}->{$version} });
	}
	return $result;
}


sub getAll_files_as_String {
	my ($self) = @_;
	my $string = "version\tfile\n";
	foreach my $version ( sort keys %{ $self->{files} } ) {
		$string .= "$version\t$self->{files}->{$version}\n";
	}
	return $string;
}

sub get_gbFile_obj_for_version {
	my ( $self, $version ) = @_;

#print ref($self).":get_gbFile_obj_for_version -> we have the filename '$self->{files}->{$version}' for the version $version\n";
	return gbFile->new( $self->{files}->{$version} )
	  if ( defined $self->{files}->{$version} );
	if ( -f "$self->{tempPath}/$version.gb" ) {
		warn ref($self)
		  . ":get_gbFile_obj_for_version OOPS - we might have an bug in loadFlatFile as we had to create the filename from scratch, but we have found the file!\n";
		$self->{files}->{$version} = "$self->{tempPath}/$version.gb";
		return gbFile->new( $self->{files}->{$version} )
		  if ( -f $self->{files}->{$version} );
	}
	Carp::confess(
		ref($self)
		  . ":get_gbFile_obj_for_version -> we do not know the file \$self->{files}->{$version} ($self->{tempPath})\n"
	);
	return undef;
}

1;
