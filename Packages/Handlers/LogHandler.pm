#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Handlers::LogHandler;

#3th party library
use strict;
use warnings;
use Win32;
use aliased 'Devel::StackTrace';

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::LogConnector::LogMethods';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Package LogMethods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless($self);

	return $self;
}

sub WriteAction {
	my $pcbId       = shift;
	my $childPcbId  = shift;
	my $actionStep  = shift;
	my $actionCode  = shift;
	my $actionOrder = shift;

	LogMethods->InsertActionLog( $pcbId, $childPcbId, Win32::LoginName, $actionStep, $actionCode, $actionOrder );
}

sub WriteMessage {
	my $pcbId      = shift;
	my $childPcbId = shift;
	my $messCode   = shift;
	my $messType   = shift;
	my $messResult = shift;

	my $trace   = Devel::StackTrace->new();
	my $oriPath = $trace->frame( $trace->frame_count() - 1 )->{"filename"};
	my $oriFile = FileHelper->GetFileName($oriPath);

	LogMethods->InsertMessageLog( $pcbId, $childPcbId, Win32::LoginName, $messCode, $messType, $messResult, $oriFile );

}

sub WriteExceptionToLog {
	my $messMngr = shift;
	my $pcbId    = shift;

	#my $actionStep  = shift;
	#my $actionName  = shift;
	my $e         = shift;
	my $errorType = shift;

	my $errorText = "";
	my $stackText = "";
	my $type;

	my $trace   = Devel::StackTrace->new();
	my $oriPath = $trace->frame( $trace->frame_count() - 1 )->{"filename"};
	my $oriFile = FileHelper->GetFileName($oriPath);

	if ( $errorType eq "InCAM" ) {
		$type      = "type = InCAM error.";
		$errorText = $e->{"mess"};
		$stackText = $e->{"stackTrace"};

	}
	elsif ( $errorType eq "Helios" ) {
		$type      = "type = Helios database error.";
		$errorText = $e->{"mess"};
		$stackText = $e->{"stackTrace"};

	}
	else {
		$type      = "type = Scripting error.";
		$errorText = $e;
		$stackText = GeneralHelper->CreateStackTrace();

	}
	
}

	#-------------------------------------------------------------------------------------------#
	#  Place for testing..
	#-------------------------------------------------------------------------------------------#

	#print @INC;

	if (0) {

	}

	1;
