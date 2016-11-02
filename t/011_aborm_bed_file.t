#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

use stefans_libs::database::genomeDB;
use stefans_libs::file_readers::bed_file;
use stefans_libs::fastaDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $data_table = data_table->new();
my ($exp, $value, @values, $temp);
my $includes = "-I " . join( " -I ", @INC );
my $path     = $plugin_path . "/data";
my $outpath  = "$path/output";

#system("rm -R $path/output ");
mkdir($path)    unless ( -d $path );
mkdir($outpath) unless ( -d $outpath );

print "This script is meant to run with the e_coli genome .
Just ignore the results if you have installed a different version of the Mus musculus genome NC_008253.1 or none at all.\n";

## now I would need to create my bed file....

##lern some perl...
#my $seq = 'AGCT' x 30;
#print $seq."\n";
#print "And now replace the first 30 values by \n".('N' x 30)."\n";
#print "replaced_region: \n". substr ($seq,0, 30, 'N' x 30)."\n";
#print $seq."\n";
#die;

my $bed = stefans_libs::file_readers::bed_file->new({'filename' => $plugin_path."/data/e_coli_test_1_summit.bed"} ); # <- a problematic peakranger bed file I need to add support for

my $cmd = 
        "perl $includes $plugin_path/../bin/get_sequences_4_bed_file.pl "
	  . " -bed_file ".$plugin_path."/data/e_coli_test_1_summit.bed"
	  . " -outfile $outpath/e_coli_fastaDB.fa"
	  . " -organism 'E_coli'";
print $cmd."\n";
system(
	$cmd
	  #. " > /dev/null 2> /dev/null" 
);

open ( IN, "<$outpath/e_coli_fastaDB.fa" ) or die "Could not open the created fasta db '$outpath/e_coli_fastaDB.fa'\n$_\n";
is_deeply([map{chomp($_); $_;} <IN>], [split("\n", 
">gi|110640213|ref|NC_008253.1|:537357-537358
GC
>gi|110640213|ref|NC_008253.1|:1621010-1621011
GC
>gi|110640213|ref|NC_008253.1|:4824730-4824731
TT
>gi|110640213|ref|NC_008253.1|:777758-777759
AA
>gi|110640213|ref|NC_008253.1|:1761120-1761121
AT
>gi|110640213|ref|NC_008253.1|:3342849-3342850
CG
>gi|110640213|ref|NC_008253.1|:4864405-4864406
CC
")], "right fasta file" );






