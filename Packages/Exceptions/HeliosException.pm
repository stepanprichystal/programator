#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Exceptions::HeliosException;
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
	my $errorMess      = shift;
	my $errorDetail = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;
	
	
	$self->{"errorMess"} = $errorMess;
	$self->{"errorDetail"} = $errorDetail;
	
	my $mess = "";	
	$mess .= "----Helios DB error------------\n";
	$mess .= $self->{"errorMess"}."\n\n";
	$mess .= "----Helios DB error detail-----\n";
	$mess .= $self->{"errorDetail"}."\n\n";
	
	 $self->{"mess"} = $mess;
 
	
	bless($self);
 

	return $self;
}

 

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
