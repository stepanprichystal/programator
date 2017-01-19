#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Exceptions::TpvDbException;
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
	
	
	$self->{"errorMess"} = shift;
	$self->{"errorDetail"} = shift;
	
	my $mess = "====Tpv database error====\n\n".$self->{"errorMess"}.",\n\n====Tpv database error details====\n\n".$self->{"errorDetail"};
	$self = 'Packages::Exceptions::BaseException'->new($mess);
	
	bless($self);
	
	#vztisknout nejakou yakladni chzbu
	$self->__PrintError();
	

	return $self;
}

sub __PrintError{
	my $self = shift;
	
	print STDERR $self->{"mess"}."\nStack trace:\n\n".$self->{"stackTrace"};
	
	
}

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
