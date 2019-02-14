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
use overload '""' => \&stringify;

sub new {

	my $self = shift;
	$self = {};
	bless($self);

	$self->{"mess"}           = shift;
	$self->{"innerException"} = shift;

	$self->{"stackTrace"} = GeneralHelper->CreateStackTrace();

	$self->{"exceptionId"} = GeneralHelper->GetGUID();

	return $self;
}

sub GetTrace {
	my $self = shift;

	return $self->{"stackTrace"};
}

sub GetExceptionId {
	my $self = shift;

	return $self->{"exceptionId"};
}

sub Error {
	my $self = shift;

	my $e = $self->{"mess"} . "\nStack trace:\n" . $self->{"stackTrace"} . "\n ExceptionId:" . $self->{"exceptionId"} . "\n";

	if ( $self->{"innerException"} ) {

		# if exception is reference and implement IException
		if ( ref( $self->{"innerException"} ) ) {

			$e .= $self->{"innerException"}->Error();
		}
		else {
			$e .= $self->{"innerException"};
		}
	}

	return;
}

sub stringify {
	my ($self) = @_;
	return $self->Error();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

}

1;
