
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::UnitFormEvtBase;

# Abstract class #

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"wrapper"} = shift;

	my @handlers = ();
	$self->{"handlers"} = \@handlers;

	my @events = ();
	$self->{"events"} = \@events;

	return $self;
}

sub GetEvents {
	my $self = shift;
	return @{ $self->{"events"} };
}

sub __GetHandler {
	my $self     = shift;
	my $evenType = shift;

	foreach my $hndl ( @{ $self->{"handlers"} } ) {

		if ( $hndl->{"eventType"} eq $evenType ) {
			return $hndl;
		}
	}

}

#sub __GetEvent {
#	my $self     = shift;
#	my $evenType = shift;
#}

# Connect events to handlers
sub ConnectEvents {
	my $self   = shift;
	my @events = @{ shift(@_) };

	foreach my $evt (@events) {

		my $h = $self->__GetHandler( $evt->{"eventType"} );
		if ($h) {
			
			$evt->{"event"}->Add( sub { $h->{"handler"}->($h->{"wrapper"}, @_) } );
			
		}
	}
}

sub _AddHandler {
	my $self      = shift;
	my $event   = shift;
	my $eventType = shift;

	my %info = ();
	$info{"wrapper"}   = $self->{"wrapper"};
	$info{"handler"}   = $event;
	$info{"eventType"} = $eventType;

	push( @{ $self->{"handlers"} }, \%info );
}

sub _AddEvent {
	my $self      = shift;
	my $event     = shift;
	my $eventType = shift;

	my %info = ();
	$info{"event"}     = $event;
	$info{"eventType"} = $eventType;

	push( @{ $self->{"events"} }, \%info );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
