#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAM::Helper;

#3th party library
use strict;
use warnings;

#local library
use Packages::InCAM::Errors;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetErrorTextById{
	my $self = shift;
	my $id = shift;
	
	 
	my $mess = $Packages::InCAM::Errors::errs{$id};
	
	unless($mess){
		
		$mess = "Error message from InCAM is not available.";
	}
	
	return $mess;
}




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

	 
	print  Packages::InCAM::Helper->GetErrorTextById("1012002");

}

1;