
#-------------------------------------------------------------------------------------------#
# Description: Coupon layout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::BackgroundWorker::InCAMWrapper;
use base('Packages::InCAM::InCAM');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	# EVENTS

	# Raise if InCAM library wants execute command,
	# but inCAM library is disconected, because another InCAM Library in child thread
	# is connected and executing commands
	$self->{"inCAMServerBusyEvt"} = Event->new();

	return $self;
}

# -----------------------------------------------------------------------------
# Override method which directly communicate with server
# -----------------------------------------------------------------------------

sub VON {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::VON(@params);
}

sub VOF {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::VOF(@params);
}

sub SU_ON {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::SU_ON(@params);
}

sub SU_OFF {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::SU_OFF(@params);
}

sub PAUSE {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::PAUSE(@params);
}

sub MOUSE {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::MOUSE(@params);
}

sub COM {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::COM(@params);

}

sub AUX {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::AUX(@params);
}
sub DO_INFO {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	$self->__CheckIsServerBusy();

	$self->SUPER::DO_INFO(@params);
}


sub __CheckIsServerBusy {
	my $self = shift;

	unless ( $self->{"connected"} ) {

		$self->{"inCAMServerBusyEvt"}->Do(1); # raise event, server busy

		# Wait until InCAM library is connected
		while ( !$self->{"connected"} ) {
			sleep(1);
		}

		$self->{"inCAMServerBusyEvt"}->Do(0); # raise event, server not busy

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

