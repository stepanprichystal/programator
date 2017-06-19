
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnGetGroupState
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::NifFile::NifFile';

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

	my $groupData = NifGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# Controls when step panel not exist
	$groupData->SetMaska01(0);
	
	# Preapre pressfit
	my $defPressfit = 0;

	if ( $defaultInfo->GetPressfitExist() || $defaultInfo->GetMeritPressfitIS()) {

		$defPressfit = 1;
	}
 
	$groupData->SetPressfit($defPressfit);
	$groupData->SetNotes("");

	# prepare default selected quick notes
	my @quickNotes = ();
	$groupData->SetQuickNotes( \@quickNotes );

	# prepare datacode
	$groupData->SetDatacode( HegMethods->GetDatacodeLayer($jobId) );
	$groupData->SetUlLogo( HegMethods->GetUlLogoLayer($jobId) );

	# Mask color

	#mask
	my %masks2 = HegMethods->GetSolderMaskColor($jobId);
	unless ( defined $masks2{"top"} ) {
		$masks2{"top"} = "";
	}
	unless ( defined $masks2{"bot"} ) {
		$masks2{"bot"} = "";
	}
	$groupData->SetC_mask_colour( $masks2{"top"} );
	$groupData->SetS_mask_colour( $masks2{"bot"} );

	#silk
	my %silk2 = HegMethods->GetSilkScreenColor($jobId);

	unless ( defined $silk2{"top"} ) {
		$silk2{"top"} = "";
	}
	unless ( defined $silk2{"bot"} ) {
		$silk2{"bot"} = "";
	}

	$groupData->SetC_silk_screen_colour( $silk2{"top"} );
	$groupData->SetS_silk_screen_colour( $silk2{"bot"} );

	my $tenting = $self->__IsTenting( $inCAM, $jobId, $defaultInfo );

	$groupData->SetTenting($tenting);

	my $scoreChecker = $defaultInfo->GetScoreChecker();
	my $jump         = 0;
	if ($scoreChecker) {
		$jump = $scoreChecker->CustomerJumpScoring();
	}

	$groupData->SetJumpScoring($jump);

	# Dimension
	my %dim = JobDim->GetDimension( $inCAM, $jobId);

	$groupData->SetSingle_x( $dim{"single_x"} );
	$groupData->SetSingle_y( $dim{"single_y"} );
	$groupData->SetPanel_x( $dim{"panel_x"} );
	$groupData->SetPanel_y( $dim{"panel_y"} );
	$groupData->SetNasobnost_panelu( $dim{"nasobnost_panelu"} );
	$groupData->SetNasobnost( $dim{"nasobnost"} );

	return $groupData;
}

# Default "group data" for REORDER are prepared in this method
sub OnPrepareReorderGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr
	my $groupData = shift; # default group data

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();
	
	my $nif = NifFile->new($jobId);
	
	return 0 unless($nif->Exist());
	
	# Mask 0,1

	my $mask = $nif->GetValue("rel(22305,L)");
	if ( $mask !~ /\-/ ) {
		$groupData->SetMaska01(1);
	}

	# Datacodes
	my $datacode = $nif->GetValue("datacode");
	$datacode =~ s/\s//g if ( defined $datacode );    # remove spaces

	if ( defined $datacode && $datacode ne "" ) {

		$datacode = uc($datacode);
		$groupData->SetDatacode($datacode);
	}
	
	# UL logo
	my $ul = $nif->GetValue("ul_logo");
	$ul =~ s/\s//g if ( defined $ul );    # remove spaces

	if ( defined $ul && $ul ne "" ) {

		$ul = uc($ul);
		$groupData->SetUlLogo($ul);
	}
	
	# Note
	my $note = $nif->GetValue("poznamka");
	 
	if ( defined $note && $note ne "" ) {
		
		$note =~ s/;/\n/g;
		$groupData->SetNotes($note);
	}
 
}

sub __IsTenting {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	unless ($defaultInfo) {
		return 0;
	}

	my $tenting = 0;

	# if layer cnt > 1
	if ( $defaultInfo->GetLayerCnt() >= 1 ) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {

			my $etch = $defaultInfo->GetEtchType("c");

			if ( $etch eq EnumsGeneral->Etching_TENTING ) {

				$tenting = 1;
			}
		}
	}

	return $tenting;
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

