#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportChecker';
use aliased 'Packages::InCAM::InCAM';
#use aliased 'Programs::Exporter::ExportChecker::Server::Client';

# First argument shoul be jobId
my $jobId = shift;

# Second should be portt
my $port = shift;

# third should be pid of server
my $pid = shift;

unless($jobId){
	
	$jobId = "f13609";
	
}



my $form = ExportChecker->new($jobId, $port, $pid);
 
#Win32::OLE->new
 
 




