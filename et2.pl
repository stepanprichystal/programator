#!/usr/bin/perl-w
#################################
use POSIX qw(mktime);
use Time::Local;


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Connectors::HeliosConnector::HegMethods';




my $parametrPath = "c:/Pcb/statistika/data";

my $exportPath = "c:/Pcb/statistika/data";

my %allJobs = ();

	opendir TESTOPE,"$parametrPath";
			my @polScore = grep { /\.[Tt][Xx][Tt]$/ } readdir(TESTOPE);
	closedir TESTOPE;

my $jobID = 0;
my %CURR = ();
my $time = 0;
my $datum = 0;
my $start = 'false';

my $job = 0;

open (PROSTOJE,">$exportPath/prostoje.txt");
open (VRTANI,">$exportPath/vrtani.txt");

open (GLOBAL,">$exportPath/global.txt");
print GLOBAL "DATUM;CAS;PROSTOJ;VRTANI;ZAKAZNIK\n";

	foreach my $onefile (@polScore) {
					

					
					open (FILE,"$parametrPath/$onefile");
							while(<FILE>) {
								my %LAST = ();
								
								if($start eq 'false'){
											if($_ =~ /Start/){
														my @fieldSplit = split/\s/, $_;
														$datum = $fieldSplit[0];
														$time = $fieldSplit[1];
														my @fieldTmp = split/,/, $fieldSplit[2];
												
														$job = $fieldTmp[2];
													
														$start = 'true';
												
										
											}
									
								}elsif($start eq 'true') {
												if ($_ =~ /End/) {

														my @fieldSplit = split/\s/, $_;
														
														my @fieldZbytek = split/,/,$fieldSplit[2];
														
														

														$job=~ /(D\d{6})/;
														my $jobName = $1;

													$start = 'false';	
														
														my @pole = HegMethods->GetAllByPcbId("$jobName");
														my $customer = $pole[0]->{'customer'};
														
														$jobID++;
														$CURR{$jobID} = {
																	"programNum" => $job,
																	"startTime" => $datum . " " . $time,
																	"endTime" => $fieldSplit[0] . " " . $fieldSplit[1],
																	"job" => $jobName,
																	"start" => $time,
																	"end" => $fieldSplit[1],
																	"datum" => $datum,	
																	"otvoru" => $fieldZbytek[2],
																	"cust" => $customer,
																	
																	};
												}
									}
							}
					close FILE; 
	}
	
	
_Process(%CURR);

close PROSTOJE;
close VRTANI;
close GLOBAL;

sub _TranslateTime {
		my $number = shift;
		
		
		my $day = int($number / 86400);
		  $number -= ($day * 86400);	
		my $hour = int($number / 3600);
		  $number -= ($hour * 3600);
		my $min = int($number / 60);
		  $number -= ($min * 60);
		my $sec = $number % 60;
		
	return ((sprintf "%02s",$day) . " days / " .(sprintf "%02s",$hour) . ":" . (sprintf "%02s",$min) . ":" . (sprintf "%02s",$sec));
}


#sub _GetNumberOfTerm {
#		my $date = shift;
#		
#		my ($h,$min,$s,$d,$m,$y) = $date =~ m|(\d+):(\d+):(\d+)\s(\d+)\.(\d+)\.(\d+)|;
#		my $timet = timelocal($s,$min,$h, $d, $m-1, $y);
#		
#	return ($timet);
#} 
sub _GetNumberOfTerm {
		my $date = shift;
		
		my ($d,$m,$y,$h,$min,$s) = $date =~ m|(\d+)\.(\d+)\.(\d+)\s(\d+):(\d+):(\d+)|;
		my $timet = timelocal($s,$min,$h, $d, $m-1, $y);
		
	return ($timet);
} 

sub _Process {
		my %current = @_;
		
			my $countOFhash = (keys %current);
			print $countOFhash,  "\n";
			
			for (my $i=1; $i <= $countOFhash;$i++) {
				
				
				
				if ($i > 1) {
			
						print $current{$i}->{"startTime"} ," , ", $current{$i-1}->{"endTime"} ,  ", Prostoje = " ,  _TranslateTime(_GetNumberOfTerm($current{$i}->{"startTime"}) - _GetNumberOfTerm($current{$i-1}->{"endTime"})) ,  "\n";
						print $current{$i}->{"endTime"} ," , ", $current{$i}->{"startTime"} , ", Vrtani   = " ,  _TranslateTime(_GetNumberOfTerm($current{$i}->{"endTime"}) - _GetNumberOfTerm($current{$i}->{"startTime"})) , "  " , $current{$i}->{"job"} , " Poc.Otvoru = " , $current{$i}->{"otvoru"}, "\n";
						
						print PROSTOJE $current{$i}->{"startTime"} ,";", $current{$i-1}->{"endTime"} ,";", $current{$i}->{"datum"} , ";Prostoje = ;" ,  _GetNumberOfTerm($current{$i}->{"startTime"}) - _GetNumberOfTerm($current{$i-1}->{"endTime"}) ,  "\n";
						#print VRTANI $current{$i}->{"endTime"} ,";", $current{$i}->{"startTime"} ,";", $current{$i}->{"datum"} , ";Vrtani = ;" ,  _GetNumberOfTerm($current{$i}->{"endTime"}) - _GetNumberOfTerm($current{$i}->{"startTime"}) ,  ";" ,$current{$i}->{"otvoru"} , "\n";
						
						print VRTANI $current{$i}->{"endTime"} ,";", $current{$i}->{"startTime"} ,";", $current{$i}->{"datum"} , ";Vrtani = ;" ,  _GetNumberOfTerm($current{$i}->{"endTime"}) - _GetNumberOfTerm($current{$i}->{"startTime"}) ,  ";" ,$current{$i}->{"programNum"} , ";" , _GetTimeNif($current{$i}->{"job"}) , "\n";
						
						
						#print GLOBAL $current{$i}->{"startTime"} ," ; ", $current{$i-1}->{"endTime"} ,  "; Prostoje ;" ,  _GetNumberOfTerm($current{$i}->{"startTime"}) - _GetNumberOfTerm($current{$i-1}->{"endTime"})  ,  "\n";
						#print GLOBAL $current{$i}->{"endTime"} ," ; ", $current{$i}->{"startTime"} , "; Vrtani   ;" ,  _GetNumberOfTerm($current{$i}->{"endTime"}) - _GetNumberOfTerm($current{$i}->{"startTime"}) , " ;" , $current{$i}->{"job"} , "; Poc.Otvoru ; " , $current{$i}->{"otvoru"}, "\n";
						
						my @startTime = split /\s/,$current{$i}->{"startTime"};
						my @endTime = split /\s/,$current{$i-1}->{"endTime"};
						
						
						
						#Prostoje
						print GLOBAL $endTime[0] , ";" . $endTime[1] , ";" , _GetNumberOfTerm($current{$i}->{"startTime"}) - _GetNumberOfTerm($current{$i-1}->{"endTime"})  , ";" , "0" ,  ";" , $current{$i}->{"cust"} , "\n";
						
						
						#Vrtani
						print GLOBAL $startTime[0] , ";" , $startTime[1] , ";" , "0" , ";" , _GetNumberOfTerm($current{$i}->{"endTime"}) - _GetNumberOfTerm($current{$i}->{"startTime"}) , ";" , $current{$i}->{"cust"} , "\n";
						
						
						
				}
				
			}
}

sub _GetTimeNif {
		my $pcbId = lc shift;
		my $timeNif = 0;
		my $nas = 0;
		
		my @pole = HegMethods->GetAllByPcbId("$pcbId");
		my $outputDir = $pole[0]->{'archiv'};
   			$outputDir =~ s/\\/\//g;
   			
   			open (FILE,"$outputDir/$pcbId.nif");
					while(<FILE>) {
						if($_=~ /nasobnost=(\d{1,})/){
							$nas = $1;
						}
						
   						if($_=~ /tac_vrtani_${pcbId}_c.\.=(\d{0,}\.\d{0,})/ ){
   								$timeNif = $1 * $nas * 60;
   						}
					}
   		
   	return($timeNif);
	
}