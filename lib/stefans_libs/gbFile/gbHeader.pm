package gbHeader;
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
#use gbHeaderEntry;

sub new {

   my ( $class, $headerArray ) = @_;

   my ( $self, %features);

   $self = {
      entries => \%features,
      gbText => ''
   };

   bless ($self , $class ) if ( $class eq "gbHeader");

   if ( defined $headerArray){
      $self->AddHeaderArray($headerArray);
   }
   else {
      $self->{entries}->{"FEATURES"} = "Location/Qualifiers";
   }
   return $self;
}

sub AddHeaderArray{

  my ($self,$headerArray) = @_;

  my ( @features, $tempLine, $tag , $string );
  unless ( ref($headerArray) eq "ARRAY"){
  	if ( defined $headerArray){
  		$headerArray = [ split("\n", $headerArray)];
  	}
  	else {
  		Carp::confess( "I can not parse the header data '$headerArray'\n");
  	}
  }
  foreach my $line ( @$headerArray){
    chomp $line;
    $self->{gbText} .= "$line\n";
    unless ( $line =~ m/^            /){ ## HeaderEntry start
       if ( defined $features[0] ){
           $tempLine = join(" ",@features);
           next if ( $tempLine  =~ m/^ +FEATURES/);
           $tempLine =~ m/^ *(\w+) +(.*)/;
           $self->HeaderEntry($1, $2);
       }
       @features = ();
    }
    else {
       $line =~ m/^            (.+)/;
       $line = $1;
    }
    push (@features, $line);
  }
  if ( defined $features[0] ){
     $tempLine = join(" ",@features);
     $tempLine =~ m/(^ *\w*) *(.*)/;
     ($tag , $string ) = ( $1, $2);
     return 1 if ( $tag  =~ m/FEATURES/);
     $self->HeaderEntry($tag, $string);
  }
  return $self;
}

sub HeaderEntry {
  my ( $self, $tag, $string) = @_;
	return undef unless ( defined $tag);
  $self->{entries}->{$tag} = $string if (defined $string);
  return $self->{entries}->{$tag};
} 

sub setLocus {
  my ( $self, $string) = @_;
  return $self->HeaderEntry("LOCUS",$string);
}

sub gbFile_length {
	my ( $self ) = @_;
	if ( $self->HeaderEntry('LOCUS') =~ m/ (\d\d+) bp/){
		return $1;
	}
	return undef;
}

sub getAsGB{

  my ( $self ) = @_;
  return $self->{gbText};
  my (@orderOfTags, $temp, @return, @tags, $tag);
  @orderOfTags = ("LOCUS", "DEFINITION","ACCESSION","VERSION", "KEYWORDS", "SOURCE", "  ORGANISM",
  				"REFERENCE", "  AUTHORS", "  TITLE", "  JOURNAL",  "COMMENT", "   PUBMED",
				"FEATURES","ORIGIN", "BASE", " ORIGIN" );
  $temp = $self->{entries};
  @tags = keys %$temp;

  for (my $i = 0; $i < 6; $i++){
    push (@return, $self->FormatAsGB($orderOfTags[$i]));
  }
 
  $temp = join("",@orderOfTags);
  foreach $tag (@tags){
     unless ( $temp =~ m/$tag/){ ## Tag war noch nicht fest definiert!
        push (@return, $self->FormatAsGB($tag));
     }
  }
#  push (@return, $self->FormatAsGB($orderOfTags[12]));
#  push (@return, $self->FormatAsGB($orderOfTags[16]));
  push (@return, $self->FormatAsGB($orderOfTags[13]));
  return join("",@return);
}

sub FormatAsGB {
  my ( $self, $tag ) = @_;

  my ($string, $line, $tempLine, @string, @return);

  return "FEATURES             Location/Qualifiers\n" if ( $tag =~ m/FEATURES/);

  $string = $self->HeaderEntry($tag);
  $string = '.' unless (defined $string) ;

#  print "FormatAsGB $tag -> $string\n";
  $line = "$tag";
  @string = split(" +",$string);
#  $string = shift (@string);
  $line = $self->FillStringWithSpaces($line,10);

  foreach $string (@string){
    $tempLine = "$line $string";
    if ( $tag =~ m/ORGANISM/ && $string =~ m/Eukaryota/){
      push (@return, "$line\n");
      $line = $self->FillStringWithSpaces("",10);
      $tempLine = "$line $string";
    }
    if ( length($tempLine) > 82 ){
      
      push ( @return, "$line\n");
      $line = $self->FillStringWithSpaces("",10);
      $line = "$line $string";
    }
    else {
      $line = $tempLine;
    }
  }
  push (@return,"$line\n");
  
  return join ("",@return);
}

sub FillStringWithSpaces {

  my ( $self, $string, $limit ) = @_;

  for (my $i = length($string); $i <= $limit; $i++){
    $string = "$string ";
  }
  return $string;
}

1;
