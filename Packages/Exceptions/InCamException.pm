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
	my $class = shift;
	my $id      = shift;
	my $cmdHist = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;


	$self->{"cmdHistory"} = $self->__FormatHistory($cmdHist);
	$self->{"errorId"}    = $id;
	$self->{"errorMess"}  = Helper->GetErrorTextById($id);

	my $mess = "";

	$mess .= "----InCAM error id-------------\n";
	$mess .= $id . "\n\n";
	$mess .= "----InCAM error description----\n";
	$mess .= $self->{"errorMess"} . "\n\n";
	$mess .= "----InCAM command history------\n";
	$mess .= $self->{"cmdHistory"} . "\n\n";

	$self->{"mess"} = $mess;
 
	return $self;
}
 

sub __FormatHistory {
	my $self    = shift;
	my $refHist = shift;

	my $out = "";

	if ($refHist) {

		my @hist = @{$refHist};

		my $cnt = 0;

		for ( my $i = scalar( @{$refHist} ) - 1 ; $i >= 0 ; $i-- ) {

			if ( $cnt <= 2 ) {

				$out .= ( $cnt + 1 ) . ". " . @{$refHist}[$i] . "\n";

				$cnt += 1;
			}
		}

		$out .= ( $cnt + 1 ) . ". ...\n";
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
