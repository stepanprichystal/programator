
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnGetGroupState
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';

use aliased 'CamHelpers::CamDrilling';

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

	my $groupData = NCGroupData->new();

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	$groupData->SetExportSingle(0);

	my @plt = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	@plt = map { $_->{"gROWname"} } @plt;

	$groupData->SetSingleModePltLayers( \@plt );

	my @nplt = CamDrilling->GetNPltNCLayers( $inCAM, $jobId );
	@nplt = map { $_->{"gROWname"} } @nplt;

	$groupData->SetSingleModeNPltLayers( \@nplt );

	my @NClayers = $self->__GetNCLayersSett($defaultInfo);
	$groupData->SetAllModeLayers( \@NClayers );

	return $groupData;
}

sub __GetNCLayersSett {
	my $self        = shift;
	my $defaultInfo = shift;

	my @NCLayers = $defaultInfo->GetNCLayers();

	my @prepared = ();
	foreach my $l (@NCLayers) {

		my %lInfo = $defaultInfo->GetNCLSett($l);

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

