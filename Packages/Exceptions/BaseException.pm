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

	$self->{"stackTrace"} = $self->__CreateStackTrace();

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

	my $e = "==============================================\n";
	$e .= " MAIN EXCEPTION\n";
	$e .= "==============================================\n\n";
	$e .= $self->{"mess"} . "\n";

	$e .= "==============================================\n";
	$e .= " INNER EXCEPTION\n";
	$e .= "==============================================\n\n";

	if ( $self->{"innerException"} ) {

		# if exception is reference and implement IException
		if ( ref( $self->{"innerException"} ) ) {

			$e .= $self->{"innerException"}->Error() . "\n";
		}
		else {
			$e .= $self->{"innerException"} . "\n";
		}
	}
	else {
		$e .= "No inner exception\n";
	}

	$e .= "==============================================\n";
	$e .= " STACK TRACE\n";
	$e .= "==============================================\n\n";
	$e .= $self->{"stackTrace"} . "\n";

	$e .= "\n (ExceptionId:" . $self->{"exceptionId"} . ")";

	return $e;
}

sub __CreateStackTrace {
	my $self     = shift;
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

sub stringify {
	my ($self) = @_;
	return $self->Error();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

1;
