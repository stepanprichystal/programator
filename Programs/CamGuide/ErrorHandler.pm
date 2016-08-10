#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::ErrorHandler;

#3th party library
use strict;
use warnings;
use Win32;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless($self);

	return $self;
}

sub ShowExceptionMess {
	my $messMngr = shift;
	my $pcbId       = shift;
	my $actionStep  = shift;
	my $actionName  = shift;
	my $e = shift;
	my $errorType = shift;

	my $errorText = "";
	my $stackText = "";
	my $type;
	
	if($errorType eq "InCAM"){
		$type = "type = InCAM error.";
		$errorText = $e->{"mess"};
		$stackText = $e->{"stackTrace"};
		
	}
	elsif($errorType eq "Helios"){
		$type = "type = Helios database error.";
		$errorText = $e->{"mess"};
		$stackText = $e->{"stackTrace"};
		
	}else{
		$type = "type = Scripting error.";
		$errorText = $e;
		$stackText = GeneralHelper->CreateStackTrace();
		
		print STDERR $errorText."\nStack trace:\n".$stackText;
		
	}

	 

	my @btns = ( "Continue guide (own risk)", "Abort guide");
	my @mess1 = ( "Error in gude action. ($type): ", 
	"<b>Action name: </b>" . $actionName, 
	"<b>Action step: </b>" . $actionStep, 
	"<b>Error message: </b>\n\n" . $errorText,
	"<b>Stack trace: </b>\n\n" . $stackText);

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1, \@btns );
	
	
	if($messMngr->Result() == 2)
	{
		exit();
	}
}



sub WriteExceptionToLog {
	my $messMngr = shift;
	my $pcbId       = shift;
	my $actionStep  = shift;
	my $actionName  = shift;
	my $e = shift;
	my $errorType = shift;

	my $errorText = "";
	my $stackText = "";
	my $type;
	
	if($errorType eq "InCAM"){
		$type = "type = InCAM error.";
		$errorText = $e->{"mess"};
		$stackText = $e->{"stackTrace"};
		
	}
	elsif($errorType eq "Helios"){
		$type = "type = Helios database error.";
		$errorText = $e->{"mess"};
		$stackText = $e->{"stackTrace"};
		
	}else{
		$type = "type = Scripting error.";
		$errorText = $e;
		$stackText = GeneralHelper->CreateStackTrace();
		
	}

	 

#	my @btns = ( "Continue guide (own risk)", "Abort guide");
#	my @mess1 = "Error in gude action. ($type): ". 
#	"<b>Action name: </b>" . $actionName. 
#	"<b>Action step: </b>" . $actionStep.
#	"<b>Error message: </b>\n\n" . $errorText.
#	"<b>Stack trace: </b>\n\n" . $stackText);

	#wrtie to log_error table
	
}



#sub HeliosDatabase {
#	my $self       = shift;
#	my $message       = shift;
#
#	my $messMngr = MessageMngr->new();
#
#	print STDERR "Error Helios database:\n";
#	print STDERR $message. "\n";
#
#
#	my @btns = ( "Ukon�it", "Pokra�ovat");
#
#	my @mess = ( "Nastala chyba Helios datab�ze. P�ejete si p�esto pokra�ovat?\n\n", "Error Helios database:\n- ".$message );
#	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess, \@btns );
#	
#	if($messMngr->Result() == 1)
#	{
#		exit();
#	}
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
