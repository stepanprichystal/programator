use Win32::AdminMisc;
use Win32;

$Domain   = 'con';
$User     = 'administrator';
$Password = '**********';

$Process = "cmd /c \"type c:\\autoexec.bat\"";
if ( Win32::AdminMisc::LogonAsUser( $Domain, $User, $Password, LOGON32_L +OGON_INTERACTIVE ) ) {
	print "Successfully logged on.\n";
	print "\nLaunching ...\n";

	$Result = Win32::AdminMisc::CreateProcessAsUser(
		$Process,
		"Flags",   CREATE_NEW_CONSOLE,
		"XSize",   640,
		"YSize",   400,
		"X",       200,
		"Y",       175,
		"XBuffer", 80,
		"YBuffer", 175,
		"Title",   "Title: $User" . "'s $Pr
+ocess program",
		"Fill", BACKGROUND_BLUE |
		  FOREGROUND_RED |
		  FOREGROUND_BLUE |
		  FOREGROUND_INTENSITY |
		  FOREGROUND_GREEN,
	);
	if ($Result) {
		print "Successful! The new PID is $Result.\n";
	}
	else {
		print "Failed.\n\tError: " . Win32::FormatMessage( Win32::Admin +Misc::GetError() ) . "\n";
	}
}
else {
	print "Failed to logon.\n\tError" . Win32::AdminMisc::GetError();
}
