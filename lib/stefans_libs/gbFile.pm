package gbFile;

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

use stefans_libs::gbFile::gbFeature;
use stefans_libs::fastaFile;
use stefans_libs::gbFile::gbHeader;
use stefans_libs::root;

use strict; 
use warnings;
=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

The class gbFile is used to handle genbank formated sequence files.

=head2 depends on

L<gbFile::gbFeature>,

L<::fastaFile>,

L<gbFile::gbHeader>

L<::root>

=head2 provides


L<openFile|"openFile">

L<Length|"Length">

L<Print|"Print">

L<gbSequence|"gbSequence">

L<WriteAsGB|"WriteAsGB">

L<getPureSequenceName|"getPureSequenceName">

L<Get_SubSeq|"Get_SubSeq">

L<WriteAsFasta|"WriteAsFasta">

L<Path|"Path">

L<Name|"Name">

L<Filename|"Filename">

L<Features|"Features">

L<getSequence_ForFeatureName|"getSequence_ForFeatureName">

L<AddGbfile|"AddGbfile">

L<AddFeature|"AddFeature">

L<EraseFeaturesContaingString|"EraseFeaturesContaingString">

L<AddSequence|"AddSequence">

L<Header|"Header">

=head1 METHODS

=head2 new

new returns a new object reference of the class gbFile.

If a valid path to a genbank formated sequence file is ommited as argument this sequence file is read 
using the method L<AddGbfile|"AddGbfile">.

=cut

sub new {

	my ( $class, $gbFile, $debug ) = @_;

	my ($self);
	$self = {
		debug             => $debug,
		name              => undef,
		path              => undef,
		filename          => $gbFile,
		feature_locations => {},
		seq_length        => 0,
		seq               => "",
		features          => [],
		header            => undef
	};

	bless( $self, "gbFile" );

	if ( defined $gbFile ) {
		Carp::confess "no usable file ($gbFile)" unless ( -f $gbFile );
		$self->AddGbfile($gbFile);
		unless ( defined $self->{header} ) {
			warn
"we have read the file '$gbFile', but could not parse an gbFile object from that, as the header information is empty!\n";
			return undef;
		}
	}
	return $self;
}

sub GetFeatureInRegion {
	my ( $self, $start, $end ) = @_;

	my ( $features, $gbFeature, @return, $i );
	$features = $self->Features();
	foreach $gbFeature (@$features) {
		$return[ $i++ ] = $gbFeature
		  if ( $gbFeature->Start < $end && $gbFeature->End() > $start );
	}
	return \@return;
}

sub getFeaturesThatOverlapp {
	my ( $self, $position ) = @_;
	my @return;
	foreach ( @{ $self->Features() } ) {
		push( @return, $_ )
		  if ( $_->Start <= $position && $_->End >= $position );
	}
	return \@return;
}

sub getClosestFeature {
	my ( $self, $position ) = @_;
	my @return = @{ $self->getFeaturesThatOverlapp($position) };
	if ( defined $return[0] ) {
		if ( scalar(@return) > 1 ) {
			foreach (
				sort {
					( $a->ExprStart - $position )
					  **2 <=> ( $b->ExprStart - $position )**2
				} @return
			  )
			{
				return $_;
			}
		}
		return $return[0];
	}
	foreach (
		sort {
			( $a->ExprStart - $position )**2 <=> ( $b->ExprStart - $position )
			  **2
		} @{ $self->Features() }
	  )
	{
		return $_;
	}
	warn "we have no gbFeatures in this gbFile!";
}

=head2 Header

Header is the wrapping class for the internal genbank formated header represented by a L<gbFile::gbHeader> object.

=head3 arguments

[0]: the info tag for this header entry as defined in the genbank format

[1]: the information string stored by this header tag in the genebank header

=head3 method

if tag ans string are defined thist information is added to the gbHeader by its L<gbFile::gbHeader/"HeaderEntry"> method.

=head3 return value

The internal gbHeader object is returned.

=cut

sub Header {
	my ( $self, $tag, $string ) = @_;
	if ( defined $tag ) {
		if ( defined $string ) {
			$self->{header} = gbHeader->new()
			  unless ( defined $self->{header} );
			$self->{header}->HeaderEntry( $tag, $string );
		}
		return $self->{header}->HeaderEntry($tag);
	}
	elsif ( defined $string ) {
		## that is new - might be, that we are using a string array or a string here
		warn "we are deleting a gbFile header here! ($self :: Header )\n"
		  if ( defined $self->{header} );
		if ( ref($string) eq "ARRAY" ) {
			$self->{header} = gbHeader->new($string);
		}
		else {
			$self->{header} = gbHeader->new( [ ( split( "\n", $string ) ) ] );
		}
	}
	else {
		warn ref($self), ":Header -> we have no header information\n"
		  unless ( defined $self->{header} );
	}
	return $self->{header};
}

=head2 AddSequence

AddSequence is used to add Sequence at the end of the genbank file.

=head3 arguments

[0]: text formated sequence to add to the end of the internal genebank sequence

=head3 return value

1 if the sequence was added, 0 if not.

=cut

sub AddSequence {
	my ( $self, $sequence ) = @_;
	if ( defined $sequence ) {
		$self->{seq}        = "$self->{seq}$sequence";
		$self->{seq_length} = length( $self->{seq} );
		return 1;
	}
	return 0;
}

=head2 EraseFeaturesContaingString

=head3 arguments

[0]: the string that is part off all features that should be removed

=head3 return value

The count of removed features.

=cut

sub EraseFeaturesContaingString {
	my ( $self, $string ) = @_;
	my (
		$features,    @newFeatures,   $feature, @temp,
		$lastfeature, @featureString, $i,       $a,
		@strings,     $match
	);
	$features = $self->{features};
	$i        = $a = 0;
	@strings  = split( ";", $string );

	foreach $feature (@$features) {
		$match = 0;
		foreach $string (@strings) {
			$match = 1 if ( $feature->getAsGB() =~ m/$string/ );
			last if ( $match == 1 );
		}
		if ( $match == 1 ) {
			print "removed feature:\n", $feature->getAsGB(), "\n";
			next;
		}
		push( @newFeatures, $feature );
		$a++;
	}

	print "$i features from $a were used\n";
	$self->{features} = \@newFeatures;

	return $a - $i;
}

=head2 SelectMatchingFeaturesAsFasta

=head3 atributes

[0]: reference to an array of feature matching strings

[1]: sequence range in basepair that should be added to both sides of the feature sequence

=head3 return value

A reference to a hash with the structure { ">feature matching string" => 'feature sequence'}

=cut

sub SelectMatchingFeaturesAsFasta {

	my ( $self, $featureNames, $delta ) = @_;

	my ( $features, $fastaDB, $searchString );

	$features = $self->SelectMatchingFeatures($featureNames);

	foreach my $feature (@$features) {
		$fastaDB->{">$feature->{matches}"} =
		  $self->Get_SubSeq( $feature->Start() - $delta,
			$feature->End() + $delta );
	}
	return $fastaDB;
}

sub SelectNotMatchingFeatures {
	my ( $self, $featureNames ) = @_;

	my ( $features, @return, $i, $temp );

	$features = $self->{features};
	$i        = 0;
	foreach my $feature (@$features) {
		$temp = 0;
		foreach my $searchString (@$featureNames) {
			if ( $feature->getAsGB() =~ m/$searchString/ ) {
				$feature->{matches} = $searchString;
				$temp++;    #$return[$i++] = $feature;
			}
		}
		$return[ $i++ ] = $feature if ( $temp == 0 );
	}
	return \@return;
}

sub SelectMatchingFeatures_by_Tag {

	my ( $self, $featureNames ) = @_;

	my ( $features, @return, $i, $temp );

	$features = $self->{features};
	$i        = 0;
	foreach my $feature (@$features) {
		$temp = 0;
		foreach my  $searchString (@$featureNames) {

#       print "Searching for search string $searchString in ", $feature->Tag(), "\n";
			if ( $feature->Tag() =~ m/$searchString/ ) {
				$feature->{matches} = $searchString;

				#             $return[$i++] = $feature;
				$temp++;
			}
		}
		$return[ $i++ ] = $feature if ( $temp > 0 );
	}
	return \@return;
}

sub SelectMatchingFeatures_by_Name {

	my ( $self, $featureNames ) = @_;

	my ( $features, @return, $i, $temp );

	$features = $self->{features};
	$i        = 0;
	foreach my $feature (@$features) {
		$temp = 0;
		foreach my  $searchString (@$featureNames) {

			#print "Searching for search string $searchString\n";
			if ( $feature->Name() =~ m/$searchString/ ) {
				$feature->{matches} = $searchString;

#print "Matched ",$feature->Name()," ($self->SelectMatchingFeatures_by_Name)\n";
#             $return[$i++] = $feature;
				$temp++;
			}
		}
		$return[ $i++ ] = $feature if ( $temp > 0 );
	}
	return \@return;
}

sub SelectMatchingFeatures {
	my ( $self, $matchingArray ) = @_;
	my ( @tempArray, $result, @returnArray, $string );

	print "$self DEBUG function SelectMatchingFeatures:\n";
	foreach my $matchingString (@$matchingArray) {
		$tempArray[0] = $matchingString;
		$result = $self->SelectMatchingFeatures_by_Tag( \@tempArray );
		if ( defined @$result[0] ) {
			push( @returnArray, @$result );
			$string = "$string\t$matchingString matched to gbFeature tags\n";
			next;
		}
		$result = $self->SelectMatchingFeatures_by_Name( \@tempArray );
		if ( defined @$result[0] ) {
			push( @returnArray, @$result );
			$string = "$string\t$matchingString matched to gbFeature names\n";
			next;
		}
		$result = $self->SelectMatchingFeatures_all( \@tempArray );
		if ( defined @$result[0] ) {
			push( @returnArray, @$result );
			$string = "$string\t$matchingString matched to gbFeature body\n";
			next;
		}
		$string = "$string\t$matchingString did not match!\n";
	}
	print $string;
	return \@returnArray;
}

sub SelectMatchingFeatures_all {

	my ( $self, $featureNames ) = @_;

	my ( $features, @return, $i, $temp );

	$features = $self->{features};
	$i        = 0;
	foreach my $feature (@$features) {
		$temp = 0;
		foreach my $searchString (@$featureNames) {

			#print "Searching for search string $searchString\n";
			if ( $feature->getAsGB() =~ m/$searchString/ ) {

	 #print "Matches ",$feature->getAsGB(),"in $self->SelectMatchingFeatures\n";
				$feature->{matches} = $searchString;

				#             $return[$i++] = $feature;
				$temp++;
			}
		}
		$return[ $i++ ] = $feature if ( $temp > 0 );
	}
	return \@return;
}

=head2  AddFeature

depricated use L<Features|"Features"> instead

=cut

sub AddFeature {
	my ( $self, $feature ) = @_;
	if ( defined $feature
		&& ( $feature =~ m/gbFeature/ || $feature =~ m/deepSequencingRegion/ ) )
	{
		print "gbFile AddFeature adds feature $feature\n";
		my $features = $self->{features};
		push( @$features, $feature );
	}
	return 1;
}

=head2 AddGbfile

AddGbfile is used to read a genbank formated sequence file into a gbFile object.

=head3 arguments

[0]: absolute location of a genbank formated sequence file

=head3 method

(1) Parse the genebank sequence file using the method L<openFile|"openFile">.

(2) store sequence name and sequence path using L<getPureSequenceName|"getPureSequenceName">.

=head3 return values

[ the gbHeader,  the gbFeature array(ref),  the sequence as unformated txt , the length of the sequence ]

=cut

sub AddGbfile {
	my ( $self, $gbFile ) = @_;

	#warn "DEBUG $self->AddGbfile opens the gbFile $gbFile\n";
	$self->openFile($gbFile);

	$self->getPureSequenceName($gbFile);

	return ( $self->{header}, $self->{features}, $self->{seq},
		$self->{seq_length} );
}

=head2 getSequence_ForFeatureName

getSequence_ForFeatureName does pretty mutch what can be expected. It returns the sequence corresponding to a given feature name if such a feature exists.
Otherwise it returns the undefined value.

=head3 arguments

[0]: the name-string or a name-substring of the wanted feature

[1]: the amount of sequence to add on both sides of the feature in basepairs

=head3 return value

the text formated sequence containing the feature. Only the sequence corresponding to the first matching feature is returned! 

=cut

sub getSequence_ForFeatureName {
	my ( $self, $featureName, $delta ) = @_;

	my ($features);
	$features = $self->Features();

	foreach my $feature (@$features) {
		if ( $feature->Name() =~ m/$featureName/ ) {
			print "Found V_segment Nr $featureName = ", $feature->Name(), "\n";
			print "substr(\$self->{seq},", $feature->Start(), " - $delta, ",
			  $feature->End(), " - ", $feature->Start(), " + $delta );\n";
			return substr(
				$self->{seq},
				$feature->Start() - $delta,
				$feature->End() - $feature->Start() + $delta
			);
		}
	}
	return undef;
}

=head2 Features

The method Features is a wrapper arround the internal gbFeatures array.

=head3 arguments

[0]: either a gbFeature or the reference to an array of gbFeatures or the undefined value

=head3 method

If a gbFeature or a array of gbFeatures given, these gbFeatures get added to the internal feature array.

A reference to the internal feature array is returned. 

=head3 return value

The reference to the internal feature array is returned. Do not mess with it as it will also influence the internal features!

=cut

sub Features {
	my ( $self, $feature, $force ) = @_;

	my $features = $self->{features};

	#print "gbFeature Feature = $features\n";

	if ( defined $feature ) {
		if ( lc($feature) =~ m/array/ ) {
			foreach my $f (@$feature) {
				next unless ( ref($f) eq "gbFeature" );
				if ( !defined $f->Tag() || !defined $f->Start() ) {
					warn
					  "gbFile Features has got a incomplete gbFeature! name= ",
					  $f->Tag(), " and start = ", $f->Start(), "\n",
					  $f->getAsGB(), "\n";
				}
				unless (
					defined $self->{feature_locations}->{ $f->Tag() }
					->{ $f->Start() } )
				{
					#print "I adda new feature!\n";
					my $temp = gbFeature->new( 'test', '1..2' );
					$temp->parseFromString( $f->getAsGB() )
					  ;    ## copy the gbFeature!
					push( @$features, $temp );
				}
				unless ( defined $self->{feature_locations}->{ $f->Tag() } ) {
					$self->{feature_locations}->{ $f->Tag() } = {};
				}
				$self->{feature_locations}->{ $f->Tag() }->{ $f->Start() } = 1;
			}
		}
		elsif ( ref($feature) eq "gbFeature" ) {
			push( @$features, $feature )
			  unless (
				defined $self->{feature_locations}->{ $feature->Tag() }
				->{ $feature->Start() } );
			unless ( defined $self->{feature_locations}->{ $feature->Tag() } ) {
				my %temp;
				$self->{feature_locations}->{ $feature->Tag() } = \%temp;
			}
			$self->{feature_locations}->{ $feature->Tag() }
			  ->{ $feature->Start() } = 1;
		}
	}
	return $self->{features};
}

=head2 get_Features_as_BedFile ( $feature_tag )
You as script writer need to use the 'stefans_libs::database::genomeDB' or the 
'stefans_libs::file_readers::bed_file';
=cut

sub get_Features_as_BedFile {
	my ( $self, $chr, $tag ) = @_;
	$tag = '.' unless ( defined $tag );
	my $bed_file = stefans_libs_file_readers_bed_file->new();
	foreach ( @{ $self->Features() } ) {
		if ( $_->Tag() =~ m/$tag/ ) {
			push( @{ $bed_file->{'data'} }, [ $chr, $_->Start(), $_->End() ] );
		}
	}
	return $bed_file;
}

sub ChangeRegion_Add {
	my ( $self, $bp_to_add ) = @_;
	foreach ( @{ $self->Features() } ) {
		$_->ChangeRegion_Add($bp_to_add);
	}
	return 1;
}

=head2 Filename

Filename is the warpper method of the internal filename representation.

=head3 arguments

[0]: the filename to acces the genbank formated sequence file or undefined

=head3 retrun values

It returns the internal filename or the undefined value.

=cut

sub Filename {
	my ( $self, $filename ) = @_;
	$self->{filename} = $filename if ( defined $filename );
	return $self->{filename};
}

=head2 Name

Name is the warpper method of the internal name representation (root->getPureSequenceName->{MySQL_entry}).

=head3 arguments

[0]: the name to acces the genbank formated sequence MySQL entry or undefined

=head3 retrun values

It returns the internal name (MySQL entry tag) or the undefined value.

=cut

sub Name {
	my ( $self, $name ) = @_;
	$self->{name} = $name if ( defined $name );
	$self->{name} = $self->{header}->HeaderEntry("ACCESSION")
	  unless ( defined $self->{name} );
	print "DEBUG gbFile name = '$self->{name}'\n" if ( $self->{debug} );
	return $self->{name};
}

=head2 Path

Path is the warpper method of the internal path representation.

=head3 arguments

[0]: the path where the genbank formated sequence file is stored or undefined

=head3 retrun values

It returns the internal path or the undefined value.

=cut

sub Path {
	my ( $self, $path ) = @_;
	$self->{path} = $path if ( defined $path );
	return $self->{path};
}

=head2 WriteAsFasta

WriteAsFasta wirtes the internal sequence representation in fasta format.

=head3 arguments

[0]: the absolute filename to write the sequence to. 

[1]: the accesion string of the written fasta file

[2]: position in basepairs where the sequence should start

[3]: position in basepairs where the sequence should end

=cut

sub WriteAsFasta {
	my ( $self, $file, $accession, $startSeq, $endSeq ) = @_;

	my $seqInfo = root->getPureSequenceName($file);

	print ref($self),
":WriteAsFasta -> filename = $file\nWriteAsFasta path = $seqInfo->{path}\n"
	  if ( $self->{debug} );
	root->CreatePath( $seqInfo->{path} );
	open( OUT, ">$file" ) or die "Konnte Datei $file nicht anlegen!\n";

	print OUT ">$accession\n" if ( defined $accession );
	print OUT ">$self->{name}\n" unless ( defined $accession );

	my $seq = $self->Get_SubSeq( $startSeq, $endSeq );
	for ( my $start = -1 ; $start < length($seq) ; $start += 60 ) {
		print OUT substr( $seq, $start + 1, 60 ), "\n";
	}
	close OUT;
	return 1;
}

sub setLocus {
	my ( $self, $string ) = @_;
	return $self->{header}->setLocus($string);
}

=head2 Get_SubSeq

=head3 arguments 

[0]: position in basepairs where the substring of the seqiuence should start

[1]: position in basepairs where the substring of the seqiuence should end

=head3 return values

the substring of the sequence ore the whole sequence if start and end where not defined

=cut

sub Get_SubSeq {
	my ( $self, $start, $end ) = @_;
	## in case I am a non standard chromosomal part instead of a gbFile I need to care about a potential offset!
	if ( defined $self->{'SEQ_offset'} ) {
		$start += $self->{'SEQ_offset'};
		$end   += $self->{'SEQ_offset'};
	}

	#1..3

	if ( defined $start ) {
		if ( defined $end ) {
			return
			  substr( $self->Sequence(), $start - 1, $end - ( $start - 1 ) );
		}
		else {
			return
			  substr( $self->Sequence(), $start, $self->Length() - $start );
		}
	}
	return $self->{seq};
}

=head2 drop_features_that_do_not_match_to ( $start, $end )

This function has become necessary with the chromosomal regions.
It can be used to remove gbFeatures from the gbFile that are located before $start on the sequence.

=cut

sub drop_features_that_do_not_match_to {
	my ( $self, $start, $end ) = @_;
	my $features_array = $self->Features();

	#	print "The features array: $features_array\n";
	#	my $i = 0;
	#	foreach (@$features_array ) {
	#		print "gbFeature ".$i++." = ".$_->getAsGB()."\n";
	#	}
	for ( my $i = @$features_array - 1 ; $i >= 0 ; $i-- ) {

		#print "I am processing the gbFeature nr $i\n";
		unless ( ref( @$features_array[$i] ) eq "gbFeature" ) {
			splice( @$features_array, $i, 1 );

			#print "Spliced id $i as it is no gbFeature!\n";
			next;
		}
		if ( @$features_array[$i]->Start() > $end ) {
			splice( @$features_array, $i, 1 );

			#print "Spliced id $i as it is located after the ROI!\n";
			next;
		}
		if ( @$features_array[$i]->End() < $start ) {
			splice( @$features_array, $i, 1 );

			#print "Spliced id $i as it is located before the ROI!\n";
			next;
		}
	}
	return $self;
}

=head2 getPureSequenceName

getPureSequenceName is a wrapper around L<root/"getPureSequenceName">.

=head3 arguments

[0]: the filename to split up

=head3 method

$self->{name} = root->getPureSequenceName->{MySQL_entry} and $self->{path} = root->getPureSequenceName->{path}

=head3 return value

$self->{name}, $self->{path}

=cut

sub getPureSequenceName {

	my ( $self, $filename ) = @_;

	return ( $self->{name}, $self->{path} ) unless ( defined $filename );

	my $data = root->getPureSequenceName($filename);

	$self->{path} = $data->{path};
	$self->{name} = $data->{'MySQL_entry'};
	return $self->{name}, $self->{path};
}

=head3 WriteAsGB_toFile

Write the sequence in genbank format.

=head3 atributes

[0]: the filename to write the file to

[1]: the strt position in the sequence in basepair

[2]: the end position in the sequence in basepair
 
=cut

sub WriteAsGB_toFile {

	my ( $self, $filename, $start, $end, $addToName ) = @_;

	my ( $temp, $line );

	open( OUT, ">$filename" ) or die "konnte file $filename nicht anlegen!\n";

	print OUT $self->{header}->getAsGB();

	$temp = $self->Features();
	foreach my $feature ( sort FeatureByStart @$temp ) {
		if ( defined $start && defined $end ) {
			print OUT $feature->getAsGB( $start, $end )
			  if ( $feature->End > $start && $feature->Start < $end );
		}
		else {
			print OUT $feature->getAsGB( 0, $self->{seq_length} );
		}
	}

	$temp = $self->gbSequence( $start, $end );
	print OUT "ORIGIN\n";
	foreach $line (@$temp) {
		print OUT $line;
	}
	print "genbank file written as $filename\n";
	close OUT;

}

sub getAsGB {
	my ( $self, $Include, $start, $end) = @_;

	$start = 1 unless ( defined $start);
	$end = $self->Length() unless ( defined $end );
	my $string = '';
	$Include = 'header features sequence' unless ( defined $Include );

	#print "I plot in the region of $start to $end\n";
	if ( $Include =~ m/header/ ) {
		$string .= $self->{header}->getAsGB();
	}

	if ( $Include =~ m/features/ ) {
		my $temp = $self->Features();
		foreach my $feature ( sort FeatureByStart @$temp ) {

			if ( defined $start && defined $end ) {
				$string .= $feature->getAsGB( $start, $end )
				  if ( $feature->End > $start && $feature->Start < $end );
			}
			else {
				$string .= $feature->getAsGB( 0, $self->{seq_length} );
			}
		}
	}
	if ( $Include =~ m/sequence/ ) {
		$string .= "ORIGIN\n";

		my $temp = $self->gbSequence( $start, $end );
		foreach my $line (@$temp) {
			$string .= $line;
		}
	}
	return $string;
}

=head3 WriteAsGB

Write the sequence in genbank format.

=head3 atributes

[0]: the filename to write the file to

[1]: the strt position in the sequence in basepair

[2]: the end position in the sequence in basepair
 
=cut

sub WriteAsGB {

	my ( $self, $filename, $start, $end, $addToName ) = @_;

	my ( $temp, $line );

	my ( $seqName, $path ) = $self->getPureSequenceName($filename);
	print "filename = $seqName.gb\nWriteAsGB path = $path\n";

	$path = "$path/modified" if ( -f "$path/$seqName.gb" );

	root->CreatePath($path);
	$seqName  = "$seqName-$addToName" if ( defined $addToName );
	$filename = "$path/$seqName.gb";

	open( OUT, ">$filename" ) or die "konnte file $filename nicht anlegen!\n";

	print OUT $self->{header}->getAsGB();

	$temp = $self->Features();
	foreach my $feature ( sort FeatureByStart @$temp ) {
		if ( defined $start && defined $end ) {
			print OUT $feature->getAsGB( $start, $end )
			  if ( $feature->End > $start && $feature->Start < $end );
		}
		else {
			print OUT $feature->getAsGB( 0, $self->{seq_length} );
		}
	}

	$temp = $self->gbSequence( $start, $end );
	print OUT "ORIGIN\n";
	foreach $line (@$temp) {
		print OUT $line;
	}
	print "genbank file written as $filename\n";
	close OUT;

}

sub FeatureByStart {

	#    print $a->Start()," <=> ",$b->Start(),"\n";
	return $a->Start() <=> $b->Start();
}

=head2 gbSequence

gbSequence formated the internal sequence sting to the genbank sequence format

=head3 atributes

[0]: position in basepairs where the sequence should start

[1]: position in basepairs where the sequence should end

=head3 return values

The reference to a sequence array containing the sequence line by line.

=cut

sub gbSequence {

	##   create and return SequenceArray GB formated

	my ( $self, $startSeq, $endSeq ) = @_;
	my ( @lines, $line, @line, $anfang, $anfangLaenge, $temp, $s, $a, $b,
		$sequence );

	$sequence = $self->Get_SubSeq( $startSeq, $endSeq );

	my $end = length($sequence);

	foreach ( my $start = 0 ; $start < $end ; $start = $start + 60 ) {
		$anfang = $start + 1 - $self->{'SEQ_offset'};
		$temp   = "";
		for (my $i = 9 - length($anfang) ; $i > 0 ; $i-- ) {
			$temp = "$temp ";
		}
		$line = "$temp$anfang";
		for (
			$s = $start ;
			( $s < $start + 60 && $s < length($sequence) ) ;
			$s = $s + 10
		  )
		{

			$temp = substr( $sequence, $s, 10 );
			$line = "$line $temp";    #sequence[$i]";
		}
		push( @lines, "$line\n" );
	}
	push( @lines, "//\n" );
	return \@lines;
}

=head2 Print

Print the gbHeader and the Features by there getAsGB methods.

=head3 atributes 

none

=cut

sub Print {
	my $self = shift;

	my ( $temp, $fun );
	print "Hier kommt der Header:\n";

	print $self->{header}->getAsGB() if ( defined $self->{header} );

	$fun = $self->{features};
	print "Hier kommen die Featurs:\n";
	foreach my $temp (@$fun) {
		print $temp->getAsGB(), "\n";
	}
}

=head2 Length

Length is a wrapper around the internal sequence length.
It can not handle sequences, only integers.

=cut

sub Length {
	my ( $self, $length ) = @_;
	#Carp::confess ( "I need to set up this fucntion rigth!\n");
	unless ( defined $length ) {
		return $self->{seq_length} if ( $self->{seq_length} );
		$self->{'SEQ_offset'} |= 0;
		$self->{seq_length} = length( $self->{'seq'} ) - $self->{'SEQ_offset'}; 
			##'SEQ_offset' is a value that was intruduced because I used this class as chromosome slice
		#print "I have set the lengt to $self->{seq_length}\n";
	}
	else {
		$self->{seq_length} = $length
	}
	return $self->{seq_length};

}

sub Version {
	my ( $self, $version ) = @_;
	unless ( defined $self->{'header'} ) {
		die ref($self)
		  . " the gbFile $self does not have a header entry!\n"
		  . root::get_hashEntries_as_string( $self, 3,
			"the entries of \$self:" ), "$!";
	}
	my $string = $self->{'header'}->HeaderEntry("VERSION");
	my @string = split( / +/, $string );
	return $string[0];
}

sub isVersion {
	my ( $self, $version ) = @_;
	return $self->Version() =~ m/$version/;
}

sub isMultilineStart {
	my ( $self, $string, $qchars ) = @_;

	my ( $qL, $qR );    # left and right quote chars, like ' or ()
	my ($quote_level);  # current quote level
	my ( $myValue, $temp );

	( $qL, $qR ) = split( "", $qchars );

	$myValue = $quote_level = 0;
	my @string = split( "", $string );
	$temp = @string;
	foreach $temp (@string) {
		if ( $temp eq $qL ) {
			$myValue++;
		}
		if ( $temp eq $qR && !( $qR eq '"' ) ) {
			$myValue--;
		}
	}
	if ( $qchars =~ m/"/ ) {    #"
		return 0 if ( $myValue / 2 == int( $myValue / 2 ) );
		return 1;
	}
	return 0 if ( $myValue == 0 );
	return 1;
}

=head2 parseString

openFile pareses the genbank formated sequence file into the internal sequence representation.

=head3 atributes

[0]: the absolute location of the sequence file

=head3 return values

(1) if success

=cut

sub parseString($) {

	my ( $self, $gbString ) = @_;

	my (
		$line,        @line,   $value,     $descriptor,
		@feature,     @return, $multiline, $iterator,
		$orientation, $last,   @sequence,  @preamble
	);
	my $i = $iterator = $multiline = 0;
	my $Ri       = 0;
	my $header   = 0;
	my $sequence = "";
	if ( $gbString =~ m/^>/ ) {
		close(GBfile);
		return undef;
	}
	foreach ( split( "\n", $gbString ) ) {
		$last = $line;
		$line = $_;

		if ( $header == 0 ) {    ## Preamble
			chomp $line;
			$preamble[ $i++ ] = "$line";
			if ( $line =~ m/^FEATURES/ ) {

				#              print "FeatureTag erkannt!\n";
				$header = 1;
				$i      = 0;
			}
		}

		#        else { print "readGBfile_1 -> $line\n";#}
		if ( $header == 1 ) {
			chop $line;

			#        print $iterator,"\tAnfang readGBfile:$line\n";
			#        if ( isMultilineStart($line,"()") == 1){
			if (   $line =~ m/ +\w+ +[\w(]*.?\d+[<>]?\.?\.?/
				&& $self->isMultilineStart( $line, "()" ) )
			{
				die "we have a multiline start!!\n";
				while (<GBfile>) {
					m/         *(.*)$/;
					$line = "$line $1";
					if (   $self->isMultilineStart( $line, "()" ) == 0
						|| $_ eq "" )
					{
						last;
					}
				}

			}
			elsif ( $self->isMultilineStart( $line, '""' ) == 1 ) {
				while (<GBfile>) {
					m/          *(.*)$/;
					$line = "$line $1";
					if (   $self->isMultilineStart( $line, '""' ) == 0
						|| $_ eq "" )
					{
						last;
					}
				}
			}

			if ( $line =~ m/^     (\w+) *(.*)/ ) {
				my $feature = gbFeature::new( "gbFeature", $1, $2 );

				#print "gbFile -> openFile () new gbFeature $1,$2\n";
				$return[ $Ri++ ] = $feature;
				next;
			}
			if ( $line =~ m/ *.(\w*)=(".+")/ ) {
				$return[ $Ri - 1 ]->AddInfo( $1, $2 );

				#   print "AddInfo($1,$2)\n";
				next;

			}
			if ( $line =~ m/ *i.(\w+)=(.+)/ ) {
				$return[ $Ri - 1 ]->AddInfo( $1, $2 );
				next;
			}
			if ( $line =~ m/ORIGIN/ ) {

		   #print "Feature einlesen ist fertig: $Ri features wurden gelesen!\n";
				$header = 2;
				$i      = 0;
				next;
			}
		}
		if ( $line =~ m/ORIGIN/ && $header == 0 ) {
			$header = 2;
		}
		if ( $header == 2 && !( $line =~ m/ORIGIN/ ) ) {

#            print "read_GBfile_1 -> bin an der Sequenz angekommen!\n$Ri Features\n";
			if ( $line =~ m/ *\d+ *(\w[\w ]*)/ ) {
				$line     = $1;
				@line     = split( " ", $line );
				$line     = join( "", @line );
				$sequence = "$sequence$line" unless ( $1 eq "//" );
			}

		}
	}

	$self->{header} = gbHeader->new( \@preamble );
	$self->Sequence($sequence);
	$self->{features} = \@return;
	return 1;
}

sub Sequence {
	my ( $self, $sequence ) = @_;
	if ( defined $sequence ) {
		my @seq;
		if ( $sequence =~ m/ *\d+ *(\w[\w ]*)/ ) {

			# oops we got a genbank sequence string!!

			$sequence = '';
			foreach my $line ( split( "\n", $sequence ) ) {

				#print "process sequence line\n";
				if ( $line =~ m/ *\d+ *(\w[\w ]*)/ ) {
					$sequence .= join( "", ( split( " ", $1 ) ) );
				}
				else {
					die ref($self), ":Sequence -> ",
"sorry, but we did not get a useful sequence here! (gbFile Sequences())\n";
				}
			}
		}
		$sequence = uc($sequence);
		$sequence =~ s/U/T/g;
		$sequence =~ s/X/N/g;

#print ref($self),":Sequence -> we added a new sequence of length ",length( $sequence ) ,"\n ";#,"$sequence\n";
		$self->{seq} = $sequence;
		$self->Length( );
	}
	elsif ( !defined $self->{seq} ) {
		warn ref($self), ":Sequence -> we have no sequence information!\n";
	}
	return $self->{seq};
}

sub DESTROY {
	my ($self) = @_;
	foreach my $key ( values %$self ) {
		$key = undef;
	}
}

=head2 openFile

openFile pareses the genbank formated sequence file into the internal sequence representation.

=head3 atributes

[0]: the absolute location of the sequence file

=head3 return values

(1) if success

=cut

sub openFile {

	my ( $self, $gbFile ) = @_;

	#    print "open file  $gbFile\n";
	my (@gbFile_lines);

	open( GBfile, "<$gbFile" )
	  or die "gbFile.pm::openFile could not open $gbFile\n";

	my (
		$line,        @line,   $value,     $descriptor,
		@feature,     @return, $multiline, $iterator,
		$orientation, $last,   @sequence,  @preamble
	);
	my $i = $iterator = $multiline = 0;
	my $Ri       = 0;
	my $header   = 0;
	my $sequence = "";
	print "We open the file $gbFile\n" if ( $self->{debug} );
  FileIterator: while (<GBfile>) {
		$last = $line;
		$line = $_;
		if ( $line =~ m/^>/ ) {
			close(GBfile);
			return undef;
		}

		if ( $header == 0 ) {    ## Preamble
			chomp $line;
			$preamble[ $i++ ] = "$line";
			if ( $line =~ m/^FEATURES/ ) {
				print "we hit the Features start\n" if ( $self->{'debug'} );
				$header = 1;
				$i      = 0;
			}

			#print "this line was added to the headers:\n$line\n";
		}
		if ( $header == 1 ) {
			chomp $line;
			if (   $line =~ m/\d+\.\.\d+/
				&& $self->isMultilineStart( $line, "()" ) == 1 )
			{
				while (<GBfile>) {
					m/                     (.*)$/;
					$line = "$line $1";
					last
					  if ( $self->isMultilineStart( $line, "()" ) == 0
						|| $_ eq "" );
				}

			}
			elsif ( $self->isMultilineStart( $line, '""' ) == 1 ) {
				while (<GBfile>) {

					#                chop $_;
					m/                     (.*)$/;
					$line = "$line $1";

					#                print "\tfeature Tag\t";
					last
					  if ( $self->isMultilineStart( $line, '""' ) == 0
						|| $_ eq "" );
				}
			}

			#print "gbFile openFile after multiline dtection line =\n$line\n";
			if ( $line =~ m/^     (\w+) *(.*)/ ) {
				print "gbFile -> openFile () new gbFeature $1,$2\n"
				  if ( $self->{'debug'} );
				my $feature = gbFeature::new( "gbFeature", $1, $2 );
				$return[ $Ri++ ] = $feature;
				next;
			}
			if ( $line =~ m/ *.(\w*)=(".+")/ ) {
				$return[ $Ri - 1 ]->AddInfo( $1, $2 );

				#   print "AddInfo($1,$2)\n";
				next;

			}
			if ( $line =~ m/ *i.(\w+)=(.+)/ ) {
				$return[ $Ri - 1 ]->AddInfo( $1, $2 );
				next;
			}
			if ( $line =~ m/ORIGIN/ ) {

				print
				  "Feature einlesen ist fertig: $Ri features wurden gelesen!\n"
				  if ( $self->{'debug'} );
				$header = 2;
				$i      = 0;
				next;
			}
		}
		if ( $line =~ m/ORIGIN/ && $header == 0 ) {
			$header = 2;
		}
		if ( $header == 2 && !( $line =~ m/ORIGIN/ ) ) {

#            print "read_GBfile_1 -> bin an der Sequenz angekommen!\n$Ri Features\n";
			if ( $line =~ m/ *\d* *(\w[\w ]*)/ ) {
				$line     = $1;
				@line     = split( " ", $line );
				$line     = join( "", @line );
				$sequence = "$sequence$line" unless ( $1 eq "//" );
			}

		}
	}
	close(GBfile);
	print "we have closed the file $gbFile\n" if ( $self->{debug} );
	$self->{header} = gbHeader->new( \@preamble );
	print "Header is ready ("
	  . substr( $self->{header}->getAsGB, 0, 40 )
	  . "...) \n"
	  if ( $self->{debug} );
	$self->Name();
	$self->Sequence($sequence);
	print "seqeunce is ready(", substr( $sequence, 0, 20 ) . "...)\n"
	  if ( $self->{debug} );
	$self->Features( \@return );
	print "features are included (n=" . scalar(@return) . ")\n"
	  if ( $self->{debug} );

	#$self->Length( length($sequence) );
	warn root::get_hashEntries_as_string( $self, 5,
		ref($self) . ":openFile - is everything OK?" )
	  if ( $self->{debug} );
	return 1;
}

1;
