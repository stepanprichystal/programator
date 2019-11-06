
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnGetGroupState
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::Model::PrePrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreGroupData';

use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# This method decide, if group will be "active" or "passive"
# If active, decide if group will be switched ON/OFF
# Return enum: Enums->GroupState_xxx
sub OnGetGroupState {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	#we want nif group allow always, so return ACTIVE ON
	return Enums->GroupState_ACTIVEON;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = PreGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# Prepare default layer settings
	my @signalLayers = $defaultInfo->GetSignalLayers();

	$defaultInfo->SetDefaultLayersSettings( \@signalLayers );

	my @layers = $self->__GetFinalLayers( \@signalLayers );

	$groupData->SetSignalLayers( \@layers );

	return $groupData;
}

sub __GetFinalLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @prepared = ();

	foreach my $l (@layers) {
		my %lInfo = ();

		$lInfo{"plot"}        = 1;
		$lInfo{"name"}        = $l->{"gROWname"};
		$lInfo{"polarity"}    = $l->{"polarity"};
		$lInfo{"etchingType"} = $l->{"etchingType"};
		$lInfo{"mirror"}      = $l->{"mirror"};
		$lInfo{"comp"}        = $l->{"comp"};

		push( @prepared, \%lInfo );
	}

	return @prepared;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

