use Win32::Daemon;



# pokud nejde ukon4it, tak taskkill /F /PID 56788

 
if ( Win32::Daemon::DeleteService("", 'ServiceTest') ){
	print "Successfully removed.\n";
}
else {
	print "Failed to remove service: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n";
}
