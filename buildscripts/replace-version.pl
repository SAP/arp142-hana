#! /usr/bin/perl
use strict;
use File::Copy;

#argv
my $origfile = $ARGV[0]; #'build/saphana-checks/bin/saphana-check.sh';
my $prog_vers = $ARGV[1];
chomp $origfile;
chomp $prog_vers;

my $gh_actions = $ENV{GITHUB_ACTIONS};
my $travis = $ENV{TRAVIS};

my $data = '';

if ( ! defined ${gh_actions} && ! defined ${travis} ) {
    #backup original File before editing in case of non CI/CD environment
    copy($origfile,"$origfile.bak") or die "Backup Copy failed: $!";
}

#DATE
my $prog_date = `date +"%Y-%b-%d"`;
chomp $prog_date;

#READ File
$data = read_file($origfile);

#REPLACE
$data =~ s/PROGVERSION=.*/PROGVERSION='${prog_vers}'/;
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


