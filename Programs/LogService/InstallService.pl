
use Win32::Daemon;

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use lib qw( y:\server\site_data\scripts );
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Helpers::GeneralHelper';

# If using a compiled perl script (eg. myPerlService.exe) then
# $ServicePath must be the path to the .exe as in:
#    $ServicePath = 'c:\CompiledPerlScripts\myPerlService.exe';
# Otherwise it must point to the Perl interpreter (perl.exe) which
# is conviently provided by the $^X variable...
my $ServicePath = $^X;

# If using a compiled perl script then $ServiceParams
# must be the parameters to pass into your Perl service as in:
#    $ServiceParams = '-param1 -param2 "c:\\Param2Path"';
# OTHERWISE
# it MUST point to the perl script file that is the service such as:
my $ServiceParams = GeneralHelper->Root() . "\\Programs\\LogService\\Service.pl";

# Login has to be filled, for that service can attemt to o=ODBC connection

my %service_info = (
					 machine     => '',
					 name        => 'TPVLogService',
					 display     => 'TPV logging service',
					 path        => $ServicePath,
					 user        => 'tpv-server@gatema.cz',
					 password    => 'Po123',
					 description => 'Send log emails to tpv workers from automation',
					 parameters  => $ServiceParams
);


# 1) First remove service before if exist
if ( Win32::Daemon::DeleteService("", 'TPVLogService') ){
	print "Successfully removed.\n";
}
else {
	print "Failed to remove service: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n";
}


# 2) Install service
if ( Win32::Daemon::CreateService( \%service_info ) ) {
	print "Successfully added.\n";
	
	 
}
else {
	print "Failed to add service: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n";
}
