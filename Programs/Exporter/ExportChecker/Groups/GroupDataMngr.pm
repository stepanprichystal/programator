
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::GroupDataMngr;

# Abstract class #

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Packages::ItemResult::ItemResultMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"prepareData"} = shift;    # prepare "model" group data, which are source for group GUI form
	$self->{"checkData"}   = shift;    # check "model" group data, if is possible start export
	$self->{"exportData"}  = shift;    # create export data (from prepared group data), which will consume exporter utility

	$self->{"groupData"} = undef;
	$self->{"inCAM"}     = undef;      # inCam will be passed to each available method as new instance
	                                   # Because some of this method are processed in child thread and inCAM
	                                   # is connected to specific InCAM editor

	$self->{'defaultInfo'} = undef;    # Contain default info about pcb, which is computed (only once) when export start

	$self->{'resultMngr'} = ItemResultMngr->new();

	return $self;                      # Return the reference to the hash.
}



sub PrepareGroupData {
	my $self = shift;

	if ( $self->{"prepareData"}->can("OnPrepareGroupData") ) {

		$self->{"groupData"} = $self->{"prepareData"}->OnPrepareGroupData($self);

	}
	else {
		die "PrepareData.pm has to implemetn OnPrepareGroupData method.";
	}
}

# Set default group state
sub PrepareGroupState {
	my $self = shift;

	if ( $self->{"prepareData"}->can("OnGetGroupState") ) {

		$self->{"groupData"}->{"state"} = $self->{"prepareData"}->OnGetGroupState($self);

	}
	else {
		die "PrepareData.pm has to implemetn OnGetGroupState method.";
	}
}

sub SetStoredGroupData {
	my $self = shift;

	#optional
	# if data settings is stored in file
	my $groupData = shift;

	if ($groupData) {
		$self->{"groupData"} = $groupData;
	}
	else {

		die "Group dataa are not defined";
	}
}


sub GetGroupState {
	my $self = shift;

	if ( $self->{"groupData"} ) {
		return $self->{"groupData"}->{"state"};
	}

}

sub SetGroupState {
	my $self       = shift;
	my $groupState = shift;

	$self->{"groupData"}->{"state"} = $groupState;
}
 

sub CheckGroupData {
	my $self = shift;

	if ( $self->{"checkData"}->can("OnCheckGroupData") ) {
		$self->{"checkData"}->OnCheckGroupData($self);

		return $self->{'resultMngr'}->Succes();

	}
	else {
		die "CheckData.pm has to implemetn OnCheckGroupData method.";
	}
}

sub ExportGroupData {
	my $self = shift;

	if ( $self->{"exportData"}->can("OnExportGroupData") ) {

		return $self->{"exportData"}->OnExportGroupData($self);

	}
	else {
		die "ExportData.pm has to implemetn OnExportGroupData method.";
	}

}

sub GetGroupData {
	my $self      = shift;
	my $groupData = $self->{"groupData"};

	return $groupData;
}

sub GetFailResults {
	my $self = shift;

	return $self->{'resultMngr'}->GetFailResults();
}


sub SetDefaultInfo {
	my $self       = shift;
	my $defaultInfo      = shift;

	$self->{'defaultInfo'} = $defaultInfo;
}

sub GetDefaultInfo {
	my $self       = shift;

	return $self->{'defaultInfo'};
}


sub _AddErrorResult {
	my $self    = shift;
	my $errItem = shift;    # error title (such as name of layer, name of drill etc..)
	my $error   = shift;

	my $item = $self->{'resultMngr'}->GetNewItem($errItem);

	$item->AddError($error);

	$self->{'resultMngr'}->AddItem($item);
}

sub _AddWarningResult {
	my $self     = shift;
	my $warnItem = shift;    # error title (such as name of layer, name of drill etc..)
	my $warning  = shift;

	my $item = $self->{'resultMngr'}->GetNewItem($warnItem);

	$item->AddWarning($warning);

	$self->{'resultMngr'}->AddItem($item);
}
 

#
sub _OnItemResultHandler {
	my $self       = shift;
	my $itemResult = shift;

	#raise onJobStarRun event
	my $onItemResult = $self->{'onItemResult'};
	if ( $onItemResult->Handlers() ) {
		$onItemResult->Do($itemResult);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

