 
#3th party library
use strict;
use warnings;
 use Config;
use Win32::Process;

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased "Helpers::FileHelper";
 

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
	
	my $batCmd = $inCAMPath." -s". GeneralHelper->Root() . "\\pom5.pl";
	$batCmd = "start $batCmd";

	# Create batc file (because we can provide direct incam NETWORK path starting with \\, psexec thit it is a computer name.
	# But computer name we didnt specify, because it is local computer)
	my $bat = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID().".bat";
	FileHelper->WriteString($bat,  $batCmd);
	print STDERR $batCmd;
	
	 
	#my $cmd = "psexec.exe -u spr\@gatema.cz -p Xprich04 -accepteula \\\\spr \\\\incam\\incam\\3.02\\bin\\InCAM.exe -s".GeneralHelper->Root() . "\\pom5.pl";
	my $cmd = "psexec.exe  -u GATEMA\tpvserver -p Po123  -h -i \\\\tpv-server \\\\incam\\incam\\3.02\\bin\\InCAM.exe -s". GeneralHelper->Root() . "\\pom5.pl"; #tot funguje kdyz prihlaseni ze vydalene plochy
	#$cmd = $inCAMPath;
	#my $cmd = "psexec.exe  -h -i $batCmd";
	

 	#my $fIndicator = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
 

	Win32::Process::Create( $processObj, "c:\\pstools\\psexec.exe",
							$cmd,
							0, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create ExportUtility process.\n";

	unlink($bat);
 
	$processObj->Wait(INFINITE);
	
	my $processErr =  Win32::GetLastError();
	print STDERR $processErr;
 
1;

