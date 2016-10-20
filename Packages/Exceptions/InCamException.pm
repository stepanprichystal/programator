#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Exceptions::InCamException;
use base ("Packages::Exceptions::BaseException");

use Class::Interface;
&implements('Packages::Exceptions::IException');

#3th party library
use strict;
use warnings;
use Win32;

#local library
use aliased 'Packages::Exceptions::BaseException';
use aliased 'Packages::InCAM::Helper';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};

	my $id = shift;
	my $cmdHist = shift;
	
	  
	$self = 'Packages::Exceptions::BaseException'->new();

	bless($self);
	
	
	$self->{"cmdHistory"} = $self->__FormatHistory($cmdHist);
	$self->{"errorId"}   = $id;
	$self->{"errorMess"} = Helper->GetErrorTextById($id);
	
	
	

	my $mess =
	    "====InCAM error id====\n\n" 
	  . $id
	  . " \n\n====InCAM error description====\n\n"
	  . $self->{"errorMess"}
	  . "\n\n====InCAM command history====\n\n"
	  . $self->{"cmdHistory"} . "\n";
	
	$self->{"mess"} = $mess;

	#vztisknout nejakou yakladni chzbu
	$self->__PrintError();

	return $self;
}

sub __PrintError {
	my $self = shift;

	print STDERR $self->{"mess"} . "\nStack trace:\n" . $self->{"stackTrace"};

}

 
sub __FormatHistory {
		my $self = shift;
	my $refHist = shift;

	my $out = "";

	if ($refHist) {

		my @hist = @{$refHist};

		my $cnt = 0;

		for ( my $i = scalar( @{$refHist} ) - 1 ; $i >= 0 ; $i-- ) {

			if ( $cnt <= 2 ) {
				
				$out .= ($cnt + 1). ". " . @{$refHist}[$i] . "\n";

				$cnt += 1;
			}
		}

		$out .= ($cnt + 1). ". ...\n";
	}

	return $out;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
