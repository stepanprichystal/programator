#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::MessageMngr::MessageParameter;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::MessageMngr::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless($self);

	$self->{"type"}     = shift;
	$self->{"title"}    = shift;
	$self->{"oriValue"} = shift;
	$self->{"options"}  = shift;

	# PROPERTIES

	$self->{"resultValue"} = undef;

	return $self;
}

sub GetParameterType {
	my $self = shift;

	return $self->{"type"};
}

sub GetOrigValue {
	my $self = shift;

	return $self->{"oriValue"};

}

sub GetResultValue {
	my $self       = shift;
	my $notChanged = shift;    # if ori value was not changed, return ori value

	if ( !$self->GetValueChanged() && $notChanged ) {

		return $self->{"oriValue"};
	}

	return $self->{"resultValue"};

}

sub GetTitle {
	my $self = shift;

	return $self->{"title"};

}

sub GetOptions {
	my $self = shift;

	return @{$self->{"options"}};
}

sub SetResultValue {
	my $self = shift;
	my $val  = shift;

	$self->{"resultValue"} = $val;
}

sub GetValueChanged {

	my $self = shift;

	my $changed = 0;

	if ( defined $self->{"resultValue"} ) {

		if ( ( $self->{"type"} eq Enums->ParameterType_TEXT 
		|| $self->{"type"} eq Enums->ParameterType_OPTION
		|| $self->{"type"} eq Enums->ParameterType_CHECK )
			 && $self->{"resultValue"} ne $self->{"oriValue"} )
		{

			$changed = 1;

		}
		elsif ( $self->{"type"} eq Enums->ParameterType_NUMBER && $self->{"resultValue"} != $self->{"oriValue"} ) {

			$changed = 1;
		}

	}

	return $changed;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

1;
