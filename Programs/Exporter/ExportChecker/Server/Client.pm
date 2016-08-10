#-------------------------------------------------------------------------------------------#
# Description: Helper pro obecne operace se soubory
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Server::Client;

#3th party library
use strict;
 
use Config;
use Time::HiRes qw (sleep);

#use Try::Tiny;

use aliased 'Packages::InCAM::InCAM';
use Win32::Process;

#use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	my %server = ();
	$self->{"server"} = \%server;

	 

	return $self;        # Return the reference to the hash.
}

sub Connect {
	my $self    = shift;
	my $jobGUID = shift;
	
	my $server    = $self->{"server"};
	my $port = $server->{"port"};

	my $inCAM;

	my $maxTry = 3;
	my $tryCnt = 0;

	#wait, until server script is not ready
	while ( !defined $inCAM || !$inCAM->{"socketOpen"} || !$inCAM->{"connected"} ) {

		if ( $tryCnt >= $maxTry ) {

			print STDERR "CLIENT(parent): PID: $$  is not able to connect server on port: $port\n";

			return 0;
		}

		if ($inCAM) {

			# print RED, "Stop!\n", RESET;

			print STDERR "CLIENT(parent): PID: $$  try connect to server port: $port....failed\n";
			sleep(0.2);
		}
		
		$inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
		
		
		$tryCnt++;
	}

	#server seems ready, try send message and get server pid
	my $pidServer = $inCAM->ServerReady();

	#if ok, make space for new client (child process)
	if ($pidServer) {
		$inCAM->ClientFinish();
		$self->{"server"}->{"connected"} = 1;

		print STDERR "PORT: $port ......................................................is ready\n";

		return 1;

	}
	else {
		print STDERR "SERVER (parent): PID: $pidServer is not ready\n";
		return 0;
	}

}

sub SetServer {
	my $self = shift;
	my $port = shift;
	my $pid = shift;
	
	my %server = (

		"connected" => 0,
		"port"      => $port,    #random number
		#"pidInCAM"  => -1,
		"pidServer" => $pid
	);

	$self->{"server"} = \%server;
}

sub IsConnected {
	my $self = shift;
 
	return $self->{"server"}->{"connected"};
}

sub ServerPort {
	my $self = shift;
 
	return $self->{"server"}->{"port"};
}

sub SetConnected {
	my $self = shift;
 
	$self->{"server"}->{"connected"} = 0;
}

#sub GetInfoServers {
#	my $self = shift;
#
#	my $serverRef = $self->{"servers"};
#	my $str       = "";
#
#	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {
#
#		$str .= "port: " . ${$serverRef}[$i]{"port"} . "\n";
#		$str .= "- state: " . ${$serverRef}[$i]{"state"} . "\n";
#		$str .= "- pidInCAM: " . ${$serverRef}[$i]{"pidInCAM"} . "\n";
#		$str .= "- pidServer: " . ${$serverRef}[$i]{"pidServer"} . "\n\n";
#
#	}
#
#	return $str;
#}

sub DestroyServer {
	my $self   = shift;
 
	my $server = $self->{"server"};
	
	print STDERR "\n\nSERVER PID IS ".$server->{"pidServer"}."\n\n";

	Win32::Process::KillProcess( $server->{"pidServer"}, 0 );

	#Win32::Process::KillProcess( $server->{"pidInCAM"},  0 );

	print STDERR  "SERVER: PID: " . $server->{"pidServer"} . ", port:" . $server->{"port"} . "....................................was closed\n";

	#${$serverRef}[$idx]{"state"}     = FREE_SERVER;
	#${$serverRef}[$idx]{"pidInCAM"}  = -1;
	#${$serverRef}[$idx]{"pidServer"} = -1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $m     = Programs::Exporter::ServerMngr->new();
	#my $port1 = $m->GetServerPort();

	#sleep(500);

	#$m->ReturnServerPort($port1);

	#	my $port2 = $m->GetServerPort();
	#	my $port3 = $m->GetServerPort();
	#	my $port4 = $m->GetServerPort();
	#
	#	$m->ReturnServerPort($port1);
	#
	#	$port3 = $m->GetServerPort();
	#	$port4 = $m->GetServerPort();
	#
	#	$m->ReturnServerPort($port3);
	#	$port4 = $m->GetServerPort();
	#
	#	$m->ReturnServerPort($port4);
	#	$m->ReturnServerPort($port2);

	#$m->ReturnServerPort($port2);

	#	$m->ReturnServerPort($port3);
	#	$m->ReturnServerPort($port4);
	#	$m->ReturnServerPort($port5);
	#	$m->ReturnServerPort($port6);
	#	$m->ReturnServerPort($port7);
	#	$m->ReturnServerPort($port8);
	#	$m->ReturnServerPort($port9);

	#my $port2 = $m->GetServerPort();

	#$m->ReturnServerPort($port1);

	#$m->DestroyServersOnDemand();
	#sleep(10);
	#$m->DestroyServersOnDemand();
	#$m->ReturnServerPort($port3);
	#$m->ReturnServerPort($port1);

}

sub doExport {
	my ( $port, $id ) = @_;

	my $inCAM = InCAM->new( 'localhost', $port );

	$inCAM->VON();

	my $errCode = $inCAM->COM( "clipb_open_job", job => "F17116+2", update_clipboard => "view_job" );

	#
	#	$errCode = $inCAM->COM(
	#		"open_entity",
	#		job  => "F17116+2",
	#		type => "step",
	#		name => "test"
	#	);

	#return 0;
	#for ( my $i = 0 ; $i < 5 ; $i++ ) {

	$inCAM->COM(
				 'output_layer_set',
				 layer        => "top",
				 angle        => '0',
				 x_scale      => '1',
				 y_scale      => '1',
				 comp         => '0',
				 polarity     => 'positive',
				 setupfile    => '',
				 setupfiletmp => '',
				 line_units   => 'mm',
				 gscl_file    => ''
	);

	$inCAM->COM(
				 'output',
				 job                  => $id,
				 step                 => 'input',
				 format               => 'Gerber274x',
				 dir_path             => "c:/Perl/site/lib/TpvScripts/Scripts/data",
				 prefix               => "incam1_" . $id . "_i",
				 suffix               => "",
				 break_sr             => 'no',
				 break_symbols        => 'no',
				 break_arc            => 'no',
				 scale_mode           => 'all',
				 surface_mode         => 'contour',
				 min_brush            => '25.4',
				 units                => 'inch',
				 coordinates          => 'absolute',
				 zeroes               => 'Leading',
				 nf1                  => '6',
				 nf2                  => '6',
				 x_anchor             => '0',
				 y_anchor             => '0',
				 wheel                => '',
				 x_offset             => '0',
				 y_offset             => '0',
				 line_units           => 'mm',
				 override_online      => 'yes',
				 film_size_cross_scan => '0',
				 film_size_along_scan => '0',
				 ds_model             => 'RG6500'
	);

	#}

}

1;
