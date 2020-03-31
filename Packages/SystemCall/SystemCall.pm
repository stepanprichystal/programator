
#-------------------------------------------------------------------------------------------#
# Description: Class allow run code in another perl instance
# Class take arguments: path of script  and array of parameters, which script consum
# All marameters are serialized to file ande than deserialized and pass to script
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::SystemCall::SystemCall;

#3th party library
use strict;
use warnings;
use JSON;
use Win32::Process;
use Config;

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

	$self->{"scriptPath"} = shift;    # path of script which will be execute

	# all parameters, which srcipt above consum
	while ( my $p = shift ) {

		$self->_AddParameter($p);

	}

	$self->{"runScrpit"}  = GeneralHelper->Root() . "\\Packages\\SystemCall\\Run.pl";
	$self->{"output"}     = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
	$self->{"outputData"} = undef;

	return $self;
}

# Execute perl script and return 0/1 depand if script fail(script died)/succes
sub Run {
	my $self       = shift;
	my $newConsole = shift;    # if yes, script will run in new perl console, instead of current console window

	my $result = 1;

	unless ( -e $self->{"scriptPath"} ) {

		die "Script " . $self->{"scriptPath"} . " doesn't exist\n";
	}

	my $filesStr = join( " ", @{ $self->{"params"} } );

	my $processObj;
	my $perl = $Config{perlpath};

	my @cmd = ("perl");
	push( @cmd, $self->{"runScrpit"} );
	push( @cmd, $self->{"scriptPath"} );
	push( @cmd, $self->{"output"} );
	push( @cmd, $filesStr );

	my $cmdStr = join( " ", @cmd );

	Win32::Process::Create( $processObj, $perl, $cmdStr, 0, ( $newConsole ? CREATE_NO_WINDOW : THREAD_PRIORITY_NORMAL ), "." )
	  || die "$!\n";

	$processObj->Wait(INFINITE);
	

	# read output

	if ( -e $self->{"output"} ) {

		my $serializeData = FileHelper->ReadAsString( $self->{"output"} );

		my $json = JSON->new();

		$self->{"outputData"} = $json->decode($serializeData);
		
		unlink($self->{"output"});

	}
	else {

		$result = 0;
	}

	# Test if custom package was run properly
	if ( $self->{"outputData"}->{"__SystemCallResult"} == 0 ) {

		print STDERR "Error during system-call: " . $self->{"outputData"}->{"__SystemCallResult"} . "\n";
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

}

1;

