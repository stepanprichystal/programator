
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::UnitBase;

# Abstract class #

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;
	$self->{"title"} = shift;

	$self->{"groupWrapper"} = undef;    #wrapper, which form is placed in
	$self->{"form"}         = undef;    #form which represent GUI of this group
	                                    #$self->{"active"}       = undef;    # tell if group will be visibel/active
	$self->{"dataMngr"}     = undef;    # manager, which is responsible for create, update group data

	# Events

	$self->{"onChangeState"} = Event->new();

	return $self;
}

sub InitDataMngr {
	my $self       = shift;
	my $inCAM      = shift;
	my $storedData = shift;

	$self->{"dataMngr"}->{"inCAM"} = $inCAM;

	if ($storedData) {

		# Load group data (stored on disc)
		$self->{"dataMngr"}->SetStoredGroupData($storedData);
	}
	else {

		# Load default group data and state
		$self->{"dataMngr"}->PrepareGroupData();
		$self->{"dataMngr"}->PrepareGroupState();
	}
}

# tohle presunout do base class
sub CheckBeforeExport {
	my $self       = shift;
	my $inCAM      = shift;
	my $resultMngr = shift;

	# Necessery set new incam library
	$self->{"dataMngr"}->{"inCAM"} = $inCAM;

	my $succes = $self->{"dataMngr"}->CheckGroupData();

	$$resultMngr = $self->{"dataMngr"}->{'resultMngr'};

	return $succes;
}


#sub GetGroupDefaultState {
#	my $self  = shift;
#	my $inCAM = shift;
#
#	my $groupState = $self->{"dataMngr"}->GetGroupState();
#
#	return $groupState;
#
#}

sub GetGroupState {
	my $self  = shift;
	my $inCAM = shift;

	my $groupState = $self->{"dataMngr"}->GetGroupState();

	return $groupState;
}

sub SetGroupState {
	my $self       = shift;
	my $groupState = shift;

	$self->{"dataMngr"}->SetGroupState($groupState);

	#$self->{"groupWrapper"}->SetState($groupState);

	#refresh wrapper of form based on "group state"
	#$self->{"groupWrapper"}->Refresh();
}

sub GetExportData {
	my $self  = shift;
	my $inCAM = shift;

	# Necessery set new incam library
	$self->{"dataMngr"}->{"inCAM"} = $inCAM;

	return $self->{"dataMngr"}->ExportGroupData();

}


sub _RefreshWrapper {
	my $self  = shift;
	my $inCAM = shift;

	my $groupState = $self->{"dataMngr"}->GetGroupState();
	$self->{"groupWrapper"}->SetState($groupState);

	#refresh wrapper of form based on "group state"
	$self->{"groupWrapper"}->Refresh();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
