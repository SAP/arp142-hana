#! /usr/bin/perl
use strict;
use File::Copy;

#argv
my $origfile = $ARGV[0]; #'build/saphana-checks/bin/saphana-check.sh';
my $branchname = $ARGV[1];
my $prog_vers = $ARGV[2];
chomp $origfile;
chomp $branchname;
chomp $prog_vers;

my $data = '';

#BACKUP - make a backup of original File before editing
#copy($origfile,"$origfile.bak") or die "Backup Copy failed: $!";

#DATE
my $prog_date = `date +"%Y-%b-%d"`;
chomp $prog_date;

#READ File
$data = read_file($origfile);

#REPLACE
 if ( "${branchname}" eq "master" ) {
	#PROGVERSION='v0.3-dev-50-gb9359c2' --> PROGVERSION="v0.3" ???
	$data =~ s/PROGVERSION='(.*?)(-.*)?'/PROGVERSION='$1-${prog_vers}'/;
 }
 else {
	#PROGVERSION='v0.3-dev-50-gb9359c2'
	$data =~ s/PROGVERSION='(.*?)(-.*)?'/PROGVERSION='$1-dev-${prog_vers}'/;
 }

 #PROGDATE
 $data =~ s/PROGDATE=.*/PROGDATE='${prog_date}'/;
 
#Write File 
write_file("$origfile", $data);

exit;
	
#http://perlmaven.com/how-to-replace-a-string-in-a-file-with-perl
sub read_file {
    my ($filename) = @_;

    open (my $in, '<:encoding(UTF-8)', $filename) || die "Could not open '$filename' for reading $!";
    local $/ = undef;
    my $all = <$in>;
    close $in;

    return $all;
}
sub write_file {
    my ($filename, $content) = @_;

    open (my $out, '>:encoding(UTF-8)', $filename) || die "Could not open '$filename' for writing $!";;
    print $out $content;
    close $out;

    return;
}


