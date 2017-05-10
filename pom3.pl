#!/usr/bin/perl

use Net::Telnet;
use Time::HiRes;

# cisco phone host name
my $host='10.0.0.1';
# cisco phone password
my $password='cisco';
# mute on a dial 0/1
my $mute=0;

my $sleeptime=.2;
my $prompt='/> $/';
 
my $number=723;

if($number!~/^[0-9*#]+$/) {
    print "Error: wrong characters in the numer\n";
    exit 2;
}
$telnet = new Net::Telnet ( Timeout=>3, Errmode=>'die');
# connecting
$telnet->open($host);
$telnet->waitfor('/Password :$/i'); 
$telnet->print($password); 
$telnet->waitfor($prompt);

$telnet->print('test open');
$telnet->waitfor($prompt);
$telnet->print('test key spkr');
$telnet->waitfor($prompt);Time::HiRes::sleep($sleeptime);
if($mute){
    $telnet->print('test key mute');
    $telnet->waitfor($prompt);Time::HiRes::sleep($sleeptime);
}
$telnet->print("test key ".$number."#");
$telnet->waitfor($prompt);Time::HiRes::sleep((length($number)+1)*$sleeptime);
$telnet->print('test close');
$telnet->waitfor($prompt);
$telnet->close($host);