#-------------------------------------------------------------------------------------------#
# Description: Base class, keep ob task data for one job, which fill be processed by "abstract job queue"
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Task::TaskData::TaskData;

#3th party library
use strict;
use warnings;
use File::Copy;
use Wx;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %units = ();
	$self->{"units"} = \%units;

	my %settings = ();
	$self->{"settings"} = \%settings;

	# TASK PROPERTIES
	$self->{"settings"}->{"time"}           = undef;
	$self->{"settings"}->{"mode"}           = undef;    # synchronousTask/ asynchronousTask
	$self->{"settings"}->{"port"}           = undef;    # if task is synchronous, port of server script
	$self->{"settings"}->{"mandatoryUnits"} = undef;    # units, which has to be tasked
	$self->{"settings"}->{"formPosX"}       = undef;    # position of export cheker form
	$self->{"settings"}->{"formPosY"}       = undef;    # position of export cheker form
	my @o = ();
	$self->{"settings"}->{"orders"} = \@o;              # Orders, where export utility set state "hotovo-zadat"

	return $self;                                       # Return the reference to the hash.
}

sub GetTaskTime {
	my $self = shift;

	return $self->{"settings"}->{"time"};
}

sub GetTaskMode {
	my $self = shift;

	return $self->{"settings"}->{"mode"};
}

sub GetPort {
	my $self = shift;

	return $self->{"settings"}->{"port"};
}

sub GetMandatoryUnits {
	my $self = shift;

	my @units = @{ $self->{"settings"}->{"mandatoryUnits"} };
	return @units;
}

sub GetOrderedUnitKeys {
	my $self = shift;
	my $desc = shift;

	my %unitsData = %{ $self->{"units"} };
	my @keys      = ();
	if ($desc) {
		@keys = sort { $unitsData{$b}->{"data"}->{"__UNITORDER__"} <=> $unitsData{$a}->{"data"}->{"__UNITORDER__"} } keys %unitsData;
	}
	else {
		@keys = sort { $unitsData{$a}->{"data"}->{"__UNITORDER__"} <=> $unitsData{$b}->{"data"}->{"__UNITORDER__"} } keys %unitsData;
	}

	return @keys;
}

# Tenting
sub GetUnitData {
	my $self   = shift;
	my $unitId = shift;

	my $taskData = $self->{"units"}->{$unitId};
	return $taskData;
}

sub GetAllUnitData {
	my $self = shift;

	return %{ $self->{"units"} };
}

sub GetFormPosition {
	my $self = shift;

	my $pos = Wx::Point->new( $self->{"settings"}->{"formPosX"}, $self->{"settings"}->{"formPosY"} );
	return $pos;
}

sub GetOrders {
	my $self = shift;

	return @{$self->{"settings"}->{"orders"}};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

