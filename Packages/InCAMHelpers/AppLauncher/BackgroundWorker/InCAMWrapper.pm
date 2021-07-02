
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

	# Properties
	$self->{"waitWhenBusy"} = 0;

	# EVENTS

	# Raise if InCAM library wants execute command,
	# but inCAM library is disconected, because another InCAM Library in child thread
	# is connected and executing commands
	$self->{"inCAMServerBusyEvt"} = Event->new();

	return $self;
}

sub SetWaitWhenBusy {
	my $self = shift;
	my $val  = shift;

	$self->{"waitWhenBusy"} = $val;
}

# -----------------------------------------------------------------------------
# Override method which directly communicate with server
# -----------------------------------------------------------------------------

sub VON {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::VON(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub VOF {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::VOF(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub SU_ON {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::SU_ON(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub SU_OFF {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );
	my $result = $self->SUPER::SU_OFF(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub PAUSE {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::PAUSE(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub MOUSE {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::MOUSE(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub COM {
	my ($self) = shift;

	my @params = @_;    # Command

	my ($command) = @_;
	my $reconnect = 0;  # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::COM(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub AUX {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::AUX(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub DO_INFO {
	my ($self) = shift;

	my @params = ( shift(@_), %{@_} );
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::DO_INFO(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub INFO {
	my ($self) = shift;

	my @params    = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	my $result = $self->SUPER::INFO(@params);

	$self->ClientFinish() if ($reconnect);

	return $result;
}

sub __CheckIsServerBusy {
	my $self      = shift;
	my $reconnect = shift;

	$$reconnect = 0;

	my $result = 1;

	# it means, InCAM is used bz background worker
	if ( !$self->{"connected"} && $self->{"waitWhenBusy"} ) {

		# Wait until InCAM library is connected
		my $i = 0;

		# Try to connect after background worker finish job
		my $evtRaised = 0;
		$self->Reconnect();
		while ( !$self->ServerReady() ) {

			# raise event, server busy. Just after first incam connection test, not unnecessarily earlier
			unless ($evtRaised) {
				$self->{"inCAMServerBusyEvt"}->Do(1);
				$evtRaised = 1;
			}

			print STDERR "\nWait on INCAM\n";
			sleep(1);

			$self->Reconnect();
		}

		# If connection succes, process Command and than do CLientFinish()
		# Than background worker class raise event background work finished and reconnect incam itself
		$$reconnect = 1;

		$self->{"inCAMServerBusyEvt"}->Do(0);    # raise event, server not busy
		print STDERR "InCAM library is RECONNECTED";

	}
	elsif ( !$self->{"connected"} ) {

		die "InCAM library is not connected";

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

