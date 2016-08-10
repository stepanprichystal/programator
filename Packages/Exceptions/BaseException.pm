#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Exceptions::BaseException;


#3th party library
use strict;
use warnings;
use Win32;


#local library
use aliased 'Helpers::GeneralHelper';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless($self);
	
	$self->{"mess"} = shift;
	$self->{"stackTrace"} = GeneralHelper->CreateStackTrace();

	return $self;
}



sub GetTrace{
	my $self = shift;
	
	return $self->{"stackTrace"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
