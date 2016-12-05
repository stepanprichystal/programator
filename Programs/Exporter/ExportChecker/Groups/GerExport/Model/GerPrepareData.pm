
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamHelper';
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

	my $groupData = GerGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

 
	# 1) Prepare default layer settings
	my @baseLayers = $defaultInfo->GetBoardBaseLayers();
	$defaultInfo->SetDefaultLayersSettings(\@baseLayers);
	my @layers = $self->__GetFinalLayers( \@baseLayers );
	
	$groupData->SetLayers( \@layers );
	
	# 2) Prepare paste settings
	my %pasteInfo = $self->__GetPasteInfo( $inCAM, $jobId );

	if ( scalar(@layers) ) {
		$groupData->SetExportLayers(1);
	}
	else {
		$groupData->SetExportLayers(0);
	}

	$groupData->SetPasteInfo( \%pasteInfo );

	return $groupData;
}



sub __GetFinalLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @prepared = ();

	foreach my $l (@layers) {

		my %lInfo = ();

		$lInfo{"plot"}     = 1;
		$lInfo{"name"}     = $l->{"gROWname"};
		$lInfo{"polarity"} = $l->{"polarity"};
		$lInfo{"mirror"}   = $l->{"mirror"};
		$lInfo{"comp"}     = $l->{"comp"};
		
		push(@prepared, \%lInfo);
	}
	
	return @prepared;

}
#
#sub __GetLayers {
#	my $self        = shift;
#	my $defaultInfo = shift;
#
#	my @baseLayers = $defaultInfo->GetBoardBaseLayers();
#
#	my @layers = ();
#
#	foreach my $l (@baseLayers) {
#
#		my %info = ();
#
#		$info{"name"} = $l->{"gROWname"};
#		
#		#set compensation
#		
#		if ( $l->{"gROWlayer_type"} eq "signal" || $l->{"gROWlayer_type"} eq "power_ground" || $l->{"gROWlayer_type"} eq "mixed" ) {
#
#			$info{"comp"} = $defaultInfo->GetCompByLayer($l->{"gROWname"});
#		}
#		else {
#
#			$info{"comp"} = 0;
#		}
# 
# 
#		# set polarity
#
#		if ( $l->{"gROWlayer_type"} eq "silk_screen" ) {
#
#			$info{"polarity"} = "negative";
#
#		}
#		elsif ( $l->{"gROWlayer_type"} eq "solder_mask" ) {
#
#			$info{"polarity"} = "positive";
#
#		}
#		elsif ( $l->{"gROWlayer_type"} eq "signal" || $l->{"gROWlayer_type"} eq "power_ground" || $l->{"gROWlayer_type"} eq "mixed" ) {
#
#			my $etching = $defaultInfo->GetEtchType( $l->{"gROWname"} );
#
#			if ( $etching eq EnumsGeneral->Etching_PATTERN ) {
#				$info{"polarity"} = "positive";
#			}
#			elsif ( $etching eq EnumsGeneral->Etching_TENTING ) {
#				$info{"polarity"} = "negative";
#			}
#		}
#		else {
#
#			$info{"polarity"} = "positive";
#		}
#
#		# Set mirror
#
#		# whatever with "c" is mirrored
#		if ( $l->{"gROWname"} =~ /^[pm]*c$/i ) {
#
#			$info{"mirror"} = 1;
#
#		}
#
#		# whatever with "s" is not mirrored
#		elsif ( $l->{"gROWname"} =~ /^[pm]*s$/i ) {
#
#			$info{"mirror"} = 0;
#
#		}
#
#		# inner layers decide by stackup
#		elsif ( $l->{"gROWname"} =~ /^v\d+$/i ) {
#
#			my $side = $defaultInfo->GetSideByLayer( $l->{"gROWname"} );
#
#			if ( $side eq "top" ) {
#
#				$info{"mirror"} = 1;
#			}
#			else {
#
#				$info{"mirror"} = 0;
#			}
#		}
#
#
#		push( @layers, \%info );
#	}
#
#	return @layers;
#}

sub __GetPasteInfo {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my %pasteInfo = ();

	#my @layers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	my $sa_ori  = CamHelper->LayerExists( $inCAM, $jobId, "sa_ori" );
	my $sb_ori  = CamHelper->LayerExists( $inCAM, $jobId, "sa_ori" );
	my $sa_made = CamHelper->LayerExists( $inCAM, $jobId, "sa_made" );
	my $sb_made = CamHelper->LayerExists( $inCAM, $jobId, "sb_made" );
	my $mpanelExist = CamHelper->StepExists( $inCAM, $jobId, "mpanel" );

	my @layers = ();
	my $pasteExist = 1;

	if ( $sa_ori || $sb_ori ) {

		$pasteInfo{"notOriginal"} = 0;
		$pasteInfo{"export"}      = 1;
		
		
		push(@layers, "sa_ori") if $sa_ori;
		push(@layers, "sb_ori") if $sb_ori;

	}
	elsif ( $sa_made || $sb_made ) {

		$pasteInfo{"notOriginal"} = 1;
		$pasteInfo{"export"}      = 1;
		
		push(@layers, "sa_made") if $sa_made;
		push(@layers, "sb_made") if $sb_made;

	}
	else {

		$pasteInfo{"notOriginal"} = 0;
		$pasteInfo{"export"}      = 0;
	}
	
	 

	if ($mpanelExist) {
		$pasteInfo{"step"} = "mpanel";
	}
	else {
		$pasteInfo{"step"} = "o+1";
		$pasteInfo{"export"}      = 0;
	}

	$pasteInfo{"addProfile"} = 1;
	$pasteInfo{"zipFile"}    = 1;
	$pasteInfo{"layers"}    =  \@layers;#join(";", @layers);
	

	return %pasteInfo;

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

