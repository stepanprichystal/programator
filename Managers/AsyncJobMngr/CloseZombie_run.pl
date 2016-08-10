
use strict;
use warnings;
use Config;
use Win32::Process;

my $processObj;

my $perl = $Config{perlpath};
 

Win32::Process::Create( $processObj,
                        $perl,
                        "perl c:\\Perl\\site\\lib\\TpvScripts\\Scripts\\Programs\\Exporter\\CloseZombie.pl -i 1001",
                         1,
                         NORMAL_PRIORITY_CLASS,
                         "." ) ||  die "Failed to create process.\n";
                         
                         
         print "zacatek cekani";
         
         $processObj->Wait(INFINITE);
         
       
       #  while (1){
       #  	 my $ex;
       #  $processObj->GetExitCode($ex);
         
       #  print $ex;
       #  sleep(1);
       #  }
        
         
         print "konec cekani";
                #   $processObj->GetExitCode($ret);                
                        
                         
                         
