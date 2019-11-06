
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
use List::MoreUtils qw(uniq);

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Packages::CAMJob::Marking::Marking';
use aliased 'CamHelpers::CamStepRepeatPnl';

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

	if ( $defaultInfo->GetPressfitExist() || $defaultInfo->GetMeritPressfitIS() ) {

		$defPressfit = 1;
	}

	$groupData->SetPressfit($defPressfit);

	# Prepare tolerance hole
	my $defTolHole = 0;

	if ( $defaultInfo->GetToleranceHoleExist() || $defaultInfo->GetToleranceHoleIS() ) {

		$defTolHole = 1;
	}

	$groupData->SetToleranceHole($defTolHole);

	# Prepare chamfer edge
	$groupData->SetChamferEdges( $defaultInfo->GetChamferEdgesIS() ? 1 : 0 );

	# Prepare default selected quick notes
	my @quickNotes = ();

	# Set BGA if exists
	my $bgaExist  = 0;
	my @bgaLayers = ("c");
	push( @bgaLayers, "s" ) if ( $defaultInfo->LayerExist("s") );

	foreach my $s ( CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId ) ) {
		foreach my $l (@bgaLayers) {

			my %att = CamHistogram->GetAttHistogram( $inCAM, $jobId, $s->{"stepName"}, $l );
			if ( $att{".bga"} ) {

				push( @quickNotes, { "id" => 1, "selected" => 1 } );
				$bgaExist = 1;
				last;
			}
		}
		last if ($bgaExist);
	}

	$groupData->SetQuickNotes( \@quickNotes );

	$groupData->SetNotes("");

	# prepare datacode
	$groupData->SetDatacode( $self->__GetDacode( $inCAM, $jobId, $defaultInfo ) );

	# prepare ul logo
	$groupData->SetUlLogo( HegMethods->GetUlLogoLayer($jobId) );

	# Mask color

	#mask

	my %masks = HegMethods->GetSolderMaskColor($jobId);
	unless ( defined $masks{"top"} ) {
		$masks{"top"} = "";
	}
	unless ( defined $masks{"bot"} ) {
		$masks{"bot"} = "";
	}
	$groupData->SetC_mask_colour( $masks{"top"} );
	$groupData->SetS_mask_colour( $masks{"bot"} );

	#flex mask
	my %flexType = HegMethods->GetFlexSolderMask($jobId);
	my $flex     = "";

	if ( $flexType{"top"} && $flexType{"bot"} ) {

		$flex = "2";
	}
	elsif ( $flexType{"top"} && !$flexType{"bot"} ) {
		$flex = "C";
	}
	elsif ( !$flexType{"top"} && $flexType{"bot"} ) {
		$flex = "S";
	}

	$groupData->SetFlexi_maska($flex);

	#silk
	my %silk = HegMethods->GetSilkScreenColor($jobId);

	unless ( defined $silk{"top"} ) {
		$silk{"top"} = "";
	}
	unless ( defined $silk{"bot"} ) {
		$silk{"bot"} = "";
	}

	$groupData->SetC_silk_screen_colour( $silk{"top"} );
	$groupData->SetS_silk_screen_colour( $silk{"bot"} );

	#silk 2
	my %silk2 = HegMethods->GetSilkScreenColor2($jobId);
	unless ( defined $silk2{"top"} ) {
		$silk2{"top"} = "";
	}
	unless ( defined $silk2{"bot"} ) {
		$silk2{"bot"} = "";
	}

	$groupData->SetC_silk_screen_colour2( $silk2{"top"} );
	$groupData->SetS_silk_screen_colour2( $silk2{"bot"} );

	# Tenting 
	my $tenting = $self->__IsTenting( $inCAM, $jobId, $defaultInfo );

	$groupData->SetTenting($tenting);

	# Technology
	my $technology = $self->__GetTechnology( $inCAM, $jobId, $defaultInfo );

	$groupData->SetTechnology($technology);


	my $scoreChecker = $defaultInfo->GetScoreChecker();
	my $jump         = 0;
	if ($scoreChecker) {
		$jump = $scoreChecker->CustomerJumpScoring();
	}

	$groupData->SetJumpScoring($jump);

	# Dimension
	my %dim = JobDim->GetDimension( $inCAM, $jobId );

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
	my $self      = shift;
	my $dataMngr  = shift;    #instance of GroupDataMngr
	my $groupData = shift;    # default group data

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $nif = NifFile->new($jobId);

	return 0 unless ( $nif->Exist() );

	# Mask 0,1

	my $mask = $nif->GetValue("rel(22305,L)");
	if ( defined $mask && $mask !~ /\-/ ) {
		$groupData->SetMaska01(1);
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

			my $etch = $defaultInfo->GetDefaultEtchType("c");

			if ( $etch eq EnumsGeneral->Etching_TENTING ) {

				$tenting = 1;
			}
		}
	}

	return $tenting;
}

sub __GetTechnology {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;
 
 	my $tech = undef;
 
	 
	if ( $defaultInfo->GetLayerCnt() >= 2
		 && CamDrilling->GetNCLayersByTypes(
											 $inCAM, $jobId,
											 [
											   EnumsGeneral->LAYERTYPE_plt_nDrill,         EnumsGeneral->LAYERTYPE_plt_bDrillTop,
											   EnumsGeneral->LAYERTYPE_plt_bDrillBot,     EnumsGeneral->LAYERTYPE_plt_nFillDrill,
											   EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot,
											   EnumsGeneral->LAYERTYPE_plt_nMill,         EnumsGeneral->LAYERTYPE_plt_bMillTop,
											   EnumsGeneral->LAYERTYPE_plt_bMillBot
											 ]
		 )
	  )
	{

		$tech = 'G'; # galvanics
	}else{
		
		$tech = 'M'; # Resist
	}

	return ($tech);
}


# Merge information about datacode from IS with found datacodes in job
sub __GetDacode {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	my $dataCode = HegMethods->GetDatacodeLayer($jobId);
	$dataCode =~ s/\s//g;
	$dataCode = lc($dataCode);
	my @layerNames = split( ",", $dataCode );

	my $step = $defaultInfo->IsPool() ? "o+1" : "panel";

	my @layersJob = Marking->GetDatacodeLayers( $inCAM, $jobId, $step );

	push( @layerNames, @layersJob );
	@layerNames = uniq(@layerNames);

	my $str = uc( join( ",", @layerNames ) );

	return $str;

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

