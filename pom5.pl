use Win32::Daemon;
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
    my $ServiceParams = 'c:\Perl\site\lib\TpvScripts\Scripts\pom6.pl -param1 -param2 "c:\\Param2Path"';
    
    
    my %service_info = (
        machine =>  '',
        name    =>  'PerlTest',
        display =>  'Oh my GOD, Perl is a service!',
        path    =>  $ServicePath,
        user    =>  '',
        pwd     =>  '',
        description => 'Some text description of this service',
        parameters => $ServiceParams
    );
    if( Win32::Daemon::CreateService( \%service_info ) )
    {
        print "Successfully added.\n";
    }
    else
    {
        print "Failed to add service: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n";
    }