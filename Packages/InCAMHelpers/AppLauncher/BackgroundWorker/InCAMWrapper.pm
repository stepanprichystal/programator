
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

	$self->SUPER::VON(@params);

	$self->ClientFinish() if ($reconnect);
}

sub VOF {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	$self->SUPER::VOF(@params);

	$self->ClientFinish() if ($reconnect);
}

sub SU_ON {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	$self->SUPER::SU_ON(@params);

	$self->ClientFinish() if ($reconnect);
}

sub SU_OFF {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );
	$self->SUPER::SU_OFF(@params);

	$self->ClientFinish() if ($reconnect);
}

sub PAUSE {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	$self->SUPER::PAUSE(@params);

	$self->ClientFinish() if ($reconnect);
}

sub MOUSE {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	$self->SUPER::MOUSE(@params);

	$self->ClientFinish() if ($reconnect);
}

sub COM {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	$self->SUPER::COM(@params);

	$self->ClientFinish() if ($reconnect);

}

sub AUX {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	$self->SUPER::AUX(@params);

	$self->ClientFinish() if ($reconnect);
}

sub DO_INFO {
	my ($self) = shift;

	my @params = @_;

	my ($command) = @_;
	my $reconnect = 0;    # InCAM conenction stealed from background Worker, just after background worker finish
	$self->__CheckIsServerBusy( \$reconnect );

	$self->SUPER::DO_INFO(@params);

	$self->ClientFinish() if ($reconnect);
}

sub __CheckIsServerBusy {
	my $self      = shift;
	my $reconnect = shift;

	$$reconnect = 0;

	my $result = 1;

	# it means, InCAM is used bz background worker
	if ( !$self->{"connected"} && $self->{"waitWhenBusy"} ) {

		$self->{"inCAMServerBusyEvt"}->Do(1);    # raise event, server busy

		# Wait until InCAM library is connected
		my $i = 0;

		# Try to connect after background worker finish job
		while ( !$self->ServerReady() ) {

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

