#!/usr/bin/perl -w

# Script parse file, found url adres and do get. 1 request per 1 second

use aliased 'Helpers::FileHelper';
use LWP::Simple;

my $p = "c:\\Export\\test\\d.txt";

my @lines = @{FileHelper->ReadAsLines($p)};

@lines = grep { $_ =~ /http/ } @lines;

@lines = map { ( $_ =~ /complete request: (.*)\n/ )[0] } @lines;

foreach my $l (@lines) {
	my $content = get $l;
	unless ( defined $content ) {
		die "could not get $l\n";
	}else{
		print "Response for: $l => ".$content."\n";
	}
	
	sleep(1);

}

