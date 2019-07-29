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
		#$stackText = __CreateStackTrace();
		$stackText = $errorText;
		
		print STDERR $errorText."\nStack trace:\n".$errorText;
		
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
		#$stackText = __CreateStackTrace();
		
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
#	my @btns = ( "Ukonèit", "Pokraèovat");
#
#	my @mess = ( "Nastala chyba Helios databáze. Pøejete si pøesto pokraèovat?\n\n", "Error Helios database:\n- ".$message );
#	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess, \@btns );
#	
#	if($messMngr->Result() == 1)
#	{
#		exit();
#	}
#}

sub __CreateStackTrace {
	my $formated = shift;

	my $str = "";

	my $trace = Devel::StackTrace->new();

	my $frOrder = 0;
	while ( my $frame = $trace->next_frame() ) {

		$frOrder++;

		next if ( $frOrder == 1 );    # skip first frame (function __CreateStackTrace)

		$str .= "Sub: " . ( $formated ? "<b>" : "" ) . $frame->subroutine() . "\n";

		if ( $frame->hasargs() ) {

			my @a = $frame->args();
			for ( my $i = 0 ; $i < scalar(@a) ; $i++ ) {

				$str .= "- arg $i: " . $a[$i] . "\n";
			}

		}

		$str .= ( $formated ? "</b>" : "" ) . "- File: " . $frame->filename() . "; ";
		$str .= "Line: " . $frame->line() . "\n\n";

	}

	return $str;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
