
#-------------------------------------------------------------------------------------------#
# Description: Class allow run code in another perl instance
# Class take arguments: path of script  and array of parameters, which script consum
# All marameters are serialized to file ande than deserialized and pass to script
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMCall::InCAMCall;

#3th party library
use strict;
use warnings;
use JSON;
use Win32::Process;
 

#local library
use aliased 'Helpers::JobHelper';
use aliased "Helpers::FileHelper";
use aliased "Helpers::GeneralHelper";
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my @params = ();
	$self->{"params"} = \@params;

	$self->{"packageName"} = shift;    # path of script which will be execute

	# all parameters, which srcipt above consum
	while ( my $p = shift ) {

		$self->_AddParameter($p);

	}

	$self->{"runScrpit"}  = GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\InCAMCall\\Run.pl";
	$self->{"output"}     = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
	$self->{"outputData"} = undef;

	return $self;
}

# Execute perl script and return 0/1 depand if script fail(script died)/succes
sub Run {
	my $self = shift;
	
	my $result = 1;

	if ( !defined $self->{"packageName"} || $self->{"packageName"} eq "" ) {

		die "Package name is not defined\n";
	}

	my $filesStr = join( " ", @{ $self->{"params"} } );

	my $inCAMPath = GeneralHelper->GetLastInCAMVersion();
	$inCAMPath .= "bin\\InCAM.exe";

	unless ( -f $inCAMPath )    # does it exist?
	{
		die "InCAM does not exist on path: " . $inCAMPath;
	}

 	my $fIndicator = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
 
 
 	$self->{"runScrpit"} = 'c:\Perl\site\lib\TpvScripts\Scripts\pom5.pl';
 
	my @cmd = ("InCAM.exe -s".$self->{"runScrpit"});

	push( @cmd, $self->{"packageName"} );
	push( @cmd, $self->{"output"} );
	push( @cmd, $fIndicator );                 # file, where run.pl store its PID in order kill if something go wrongs
	push( @cmd, $filesStr );

	my $cmdStr = join( " ", @cmd );
 

	#print STDERR "\n\ncommand: $cmdStr\n\n";
	#my $result = system($cmdStr);
  	my $f;
 	open($f, '+>', "c:\\tmp\\TpvService\\test" );
	print $f "Su zde 1 $inCAMPath $cmdStr\n";
	close $f;
	
	#use Config;
	#my $perl = $Config{perlpath};
 
 	#$inCAMPath = 'c:\opt\InCAM\3.01SP1\bin\InCAM.exe';
 
	my $processObj;
	Win32::Process::Create( $processObj, $inCAMPath, $cmdStr, 0, THREAD_PRIORITY_NORMAL | CREATE_NEW_CONSOLE, "." )
	  || die " run process $!\n";

	my $pidInCAM = $processObj->GetProcessID();

	$processObj->Wait(INFINITE);
	
	open( my $f2, '+>', "c:\\tmp\\TpvService\\test" );
	print $f2 "Su zde 2\n";
	close $f2;
	
	
	# if something goes wrong and inCAM or Run.pl script are still running, kill
	Win32::Process::KillProcess( $pidInCAM, 0 );
	Win32::Process::KillProcess( FileHelper->ReadAsString($fIndicator), 0 );
	
	if(-e $fIndicator){
		unlink ($fIndicator);
	}

	# read output

	if ( -e $self->{"output"} ) {

		my $serializeData = FileHelper->ReadAsString( $self->{"output"} );

		my $json = JSON->new();

		$self->{"outputData"} = $json->decode($serializeData);

		unlink( $self->{"output"} );
	}else{
		
		$result = 0
	}
	
	# Test if custom package was run properly
	if($self->{"outputData"}->{"__InCAMCallResult"} == 0){
		$result = 0;
	}

	#print STDERR "Result system call: $result\n\n";

	return $result;

}

# Script can retun output.
sub GetOutput {
	my $self = shift;

	return %{ $self->{"outputData"} };
}

sub _AddParameter {
	my $self = shift;
	my $ref  = shift;

	my $json = JSON->new()->allow_nonref();

	my $serialized = $json->pretty->encode($ref);

	my $paramId = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	push( @{ $self->{"params"} }, $paramId );

	open( my $f, '>', $paramId );
	print $f $serialized;
	close $f;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAMCall::InCAMCall';



	my $paskageName = "Packages::InCAMCall::Example";
	my @par1        = ( "k" => "1" );
	my %par2      = ( "par1", "par2" );
	

	my $call = InCAMCall->new( $paskageName, \@par1, \%par2 );
	
	my $result = $call->Run();
	my %result = $call->GetOutput();


	print "result $result";

}

1;

