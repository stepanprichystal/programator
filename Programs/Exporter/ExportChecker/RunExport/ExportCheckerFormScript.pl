#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportChecker';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';

#use aliased 'Programs::Exporter::ExportChecker::Server::Client';

# First argument shoul be jobId
my $jobId = shift;

# Second should be portt
my $port = shift;

# third should be pid of server
my $pid = shift;

# pid of loading form
my $pidLoadFrm = shift;

eval {

	my $form = ExportChecker->new( $jobId, $port, $pid, $pidLoadFrm );

};
if ($@) {

	my $messMngr = MessageMngr->new($jobId);

	my @mess1 = ( "ExportChecker fail:  " . $@ . "\n" );
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );


	if ($pidLoadFrm) {
		Win32::Process::KillProcess( $pidLoadFrm, 0 );
	}

	if ($pid) {
		Win32::Process::KillProcess( $pid, 0 );
	}

	die "ExportChecker error: \n" . $@;

}

