 
#3th party library
use strict;
use warnings;
 use Config;
use Win32::Process;

use aliased 'Helpers::GeneralHelper';
 

	#print STDERR "\n\ncommand: $cmdStr\n\n";
	#my $result = system($cmdStr);
 	my $processObj;
	#my $perl = $Config{perlpath};

	# CREATE_NEW_CONSOLE - script will run in completely new console - no interaction with old console
 
 
 	my $inCAMPath = GeneralHelper->GetLastInCAMVersion();
	$inCAMPath .= "bin\\InCAM.exe";

	unless ( -f $inCAMPath )    # does it exist?
	{
		die "InCAM does not exist on path: " . $inCAMPath;
	}

	#my $cmd = "psexec.exe ".$inCAMPath. " -s". GeneralHelper->Root() . "\\pom2.pl";
	my $cmd = "psexec.exe y:\\3.02\\bin\\InCAM.exe -s".GeneralHelper->Root() . "\\pom5.pl";

	#$cmd = $inCAMPath;

 	#my $fIndicator = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
 

	Win32::Process::Create( $processObj, "c:\\pstools\\psexec.exe",
							$cmd,
							0, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create ExportUtility process.\n";

 
	$processObj->Wait(INFINITE);
	
	my $processErr =  Win32::GetLastError();
	print STDERR $processErr;
 
1;

