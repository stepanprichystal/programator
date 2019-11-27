
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

	# Pre group has to be aways exported
	return Enums->GroupState_ACTIVEALWAYS;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = PreGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();


	# Prepare technology CS
	
	
	# Prepare tenting CS


	# Prepare signal layer for settings
 
	my @sigLayers = $self->__GetSignalLayersSett( $defaultInfo );
	$groupData->SetSignalLayers( \@sigLayers );
	
	# Prepare other layer for settings
	
	my @otherLayers = $self->__GetOtherLayersSett( $defaultInfo );
	$groupData->SetOtherLayers( \@otherLayers );

	return $groupData;
}

sub __GetSignalLayersSett {
	my $self   = shift;
	my $defaultInfo = shift;
	
	my @signalLayers = ();
	push(@signalLayers, $defaultInfo->GetSignalLayers());
	push(@signalLayers, $defaultInfo->GetSignalExtLayers());	

	# if No copper, remove layer C
	
	@signalLayers = () if($defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER);

	my @prepared = ();

	foreach my $l (@signalLayers) {
		 
		 my %lInfo = $defaultInfo->GetDefSignalLSett($l);
		 
	 
		push( @prepared, \%lInfo );
	}

	return @prepared;
}

sub __GetOtherLayersSett {
	my $self   = shift;
	my $defaultInfo = shift;
	
	my @otherLayer = $defaultInfo->GetBoardBaseLayers();

	@otherLayer =   grep { 
	  	 $_->{"gROWlayer_type"} eq "solder_mask" 
	  || $_->{"gROWlayer_type"} eq "silk_screen" 
	  || $_->{"gROWname"} =~ /^((gold)|([gl]))[cs]$/ }
	  @otherLayer;

	my @prepared = ();

	foreach my $l (@otherLayer) {
		 
		 my %lInfo = $defaultInfo->GetNonSignalLSett($l);
 
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

