#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
use File::HomeDir;
my $home = File::HomeDir->my_home();

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $exp;
my $includes = "-I " . join( " -I ", @INC );
my $path     = $plugin_path . "/data";
my $outpath  = "$path/output";

#system("rm -R $path/output ");
mkdir($path)    unless ( -d $path );
mkdir($outpath)unless ( -d $outpath );
mkdir("$outpath/tmp/") unless ( -d  "$outpath/tmp/") ;

## run this script only if you really want to create a test install of the most actual human genome!!

#print "Now I try to install the actual human genome in your test database\n"."Should I really run this test script? (Y,n):\n";
#while (<STDIN>) {
#        last if ($_ =~ /^\s*$/); # Exit if it was just spaces (or just an enter)
#        exit 0 if ($_ =~ m/^[Nn]/ );
#        last if ( $_ =~ m/^[YJyj]/);
#        print "not undestood (Y,n): $_";
#}

system( "perl $includes $plugin_path/../scripts/get_NCBI_genome.t "
	  . " -organism_name H_sapiens "
	  . " -outdir $outpath/tmp "
	  . " -releaseDate July 31, 2009" ## some data - you need to get that from the NCBI web page for a real installation
	  . " -version 37.1" ## change that to something useful in your real run, too
	  . " -referenceTag HuRef");
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  