#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use Win32::Service;
use Config;
use Win32::Process;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Programs::Exporter::ExportUtility::RunExport::RunExportUtility';
use aliased 'Helpers::GeneralHelper';

# ======= InCAMServer =============================================

RunInCAMServer();
 
# ======= TPVCustomService =========================================

RunService("TpvLogService");    # Run tpv service

# ======= TPVLogService =========================================

RunService("TpvCustomService");    # Run log service

# ======= Export utility =========================================

my $exporter = RunExportUtility->new(0);    # Run exporter

# Helper methods

sub RunService {
	my $name = shift;

	my %status = ();

	Win32::Service::GetStatus( "", $name, \%status );

	if ( $status{"CurrentState"} == 1 ) {

		Win32::Service::StartService( "", $name );
	}
}

sub RunInCAMServer {

	my $perl = $Config{perlpath};
	my $processObj1;
	Win32::Process::Create( $processObj1, $perl, "perl " . GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\InCAMServer\\Server\\InCAMServerScript.pl -h yes",
							0, NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE,  "." )
	  || die "Failed to run InCAMServerScript \n";
 
	  
 
}
