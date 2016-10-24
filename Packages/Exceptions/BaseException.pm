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
	
	$self->{"exceptionId"} =   GeneralHelper->GetGUID();

	return $self;
}



sub GetTrace{
	my $self = shift;
	
	return $self->{"stackTrace"};
}

sub GetExceptionId{
	my $self = shift;
	
	return $self->{"exceptionId"};
}


sub Error{
	my $self = shift;
	
	return $self->{"mess"} . "\nStack trace:\n" . $self->{"stackTrace"}. "\n ExceptionId:".$self->{"exceptionId"}."\n";
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
