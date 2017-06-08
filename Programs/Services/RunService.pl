#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use Win32::Service;


RunService("TpvLogService");
RunService("TpvCustomService");



sub RunService {
	my $name = shift;

	my %status = ();

	Win32::Service::GetStatus( "", $name, \%status );

	if ( $status{"CurrentState"} == 1 ) {

		Win32::Service::StartService( "", $name );
	}

}
