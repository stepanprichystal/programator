#!/usr/bin/perl
use Net::Telnet;
use Sys::Hostname;
use Socket;
use warnings;

my $localStation = hostname();
my $ipName = gethostbyname($localStation);
my $localIP = inet_ntoa($ipName);
my $userName = "pci";
my $userPassword = "goldi";
my $imStation = "192.168.2.60";
#system ("xhost +$imStation");
my $tnet = new Net::Telnet(-timeout=>20);
$tnet->open ("$imStation");
$tnet->login ("$userName","$userPassword");

print $tnet->cmd ("setenv DISPLAY $localIP:0");
print $tnet->cmd ("/pci/ver/CURRENT/pammonitor.csh lll &");

