#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use Win32::Service;
 
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Programs::Exporter::ExportUtility::RunExport::RunExportUtility';


RunService("TpvLogService");  # Run tpv service

RunService("TpvCustomService");	# Run log service	

my $exporter = RunExportUtility->new(0); # Run exporter



sub RunService {
	my $name = shift;

	my %status = ();

	Win32::Service::GetStatus( "", $name, \%status );

	if ( $status{"CurrentState"} == 1 ) {

		Win32::Service::StartService( "", $name );
	}

}
