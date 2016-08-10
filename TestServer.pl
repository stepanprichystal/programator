#!/usr/bin/perl -w

use strict;
use warnings;

#use lib qw( C:\Perl\sissste\lib\TpvScripts\Scripts );

use aliased 'Packages::InCAM::InCAM';


use Win32::Process;
my ($processObj, $pid);



my $port = 3333;


Win32::Process::Create($processObj,
             'C:\opt\InCAM\2.31SP2\bin\InCAM.exe', 'InCAM.exe -sc:\Perl\site\lib\TpvScripts\Scripts\Programs\Exporter\ServerExporter.pl '.$port, 0, 
                   NORMAL_PRIORITY_CLASS,".")|| die "$!\n";
$pid = $processObj->GetProcessID();


print STDERR "INCAM:  PID:".$pid."................................................Launching\n";


#sleep (15);
my $inCAM ; 
my $serverPID;


#while (!($inCAM->{"connected"} && defined ($serverPID = $inCAM->ServerReady())) )
while (!defined $inCAM || !$inCAM->{"connected"})
{
	if($inCAM){
	print STDERR "CLIENT: PID: $$ try connect to server port: $port.............failed\n";
	}
	
	sleep(5);
	
	#print "Conncet FAIL\n";
	
	$inCAM = InCAM->new('localhost', $port);
}

		$serverPID = $inCAM->ServerReady();
		
	
		
		sleep (5);
		$serverPID = $inCAM->ClientFinish();
		#print $inCAM->CloseServer();
		sleep (10);
		 
		$inCAM = InCAM->new('localhost', $port);
		$serverPID = $inCAM->ServerReady();
	sleep (5);
	$inCAM->CloseServer();
	sleep(10);
		Win32::Process::KillProcess($pid,0);
		#Win32::Process::KillProcess($serverPID,0);
		
		
sub CloseInCAM{
	
	#check if server is properly closed, otherwise close
	#close InCAM 
	#Win32::Process::KillProcess($pid,0);
	
	
}
		
#		my $inCAM2 = InCAM->new();
		#
		#$ready = $inCAM2->ServerReady();
		
		#print $ready;
		
	#	if ($ready){
			
		#	last;
	#	}
		#sleep(1);
		
	#}
	
	
	
	