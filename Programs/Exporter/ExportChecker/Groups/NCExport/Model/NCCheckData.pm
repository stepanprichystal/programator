
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCCheckData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Packages::Drilling::DrillChecking::LayerCheckError';
use aliased 'Packages::Drilling::DrillChecking::LayerCheckWarn';
use aliased 'Packages::Routing::RoutLayer::RoutChecks::RoutCheckTools';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# Checking group data before final export
# Errors, warnings are passed to <$dataMngr>
sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $groupData = $dataMngr->GetGroupData();
	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $stepName  = "panel";

	my $exportSingle = $groupData->GetExportSingle();
	my $pltLayers    = $groupData->GetPltLayers();
	my $npltLayers   = $groupData->GetNPltLayers();

	# 1) Check inf export single and no layers selected
	if ($exportSingle) {

		if ( scalar( @{$pltLayers} ) + scalar( @{$npltLayers} ) == 0 ) {

			$dataMngr->_AddErrorResult( "Export single layers", "No single layers was selected." );
		}
	}

	# 2) Checking NC layers
	my $mess = "";    # errors

	unless ( LayerCheckError->CheckNCLayers( $inCAM, $jobId, $stepName, undef, \$mess ) ) {
		$dataMngr->_AddErrorResult( "Checking NC layer", $mess );
	}

	my $mess2 = "";    # warnings

	unless ( LayerCheckWarn->CheckNCLayers( $inCAM, $jobId, $stepName, undef, \$mess2 ) ) {
		$dataMngr->_AddWarningResult( "Checking NC layer", $mess2 );
	}

	# 3) If panel contain more drifrent step, check if fsch exist
	my @uniqueSteps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

	if ( scalar(@uniqueSteps) > 1 && !$defaultInfo->LayerExist("fsch") ) {

		$dataMngr->_AddErrorResult( "Checking NC layer",
									"Layer fsch doesn't exist. When panel contains more different steps, fsch must be created." );
	}

	# 4) Check if contain only one kind of nested step but with various rotation

	if ( scalar(@uniqueSteps) == 1 ) {

		my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, "panel" );

		my $angle = $repeatsSR[0]->{"angle"};
		my @diffAngle = grep { $_->{"angle"} != $angle } @repeatsSR;

		if ( scalar(@diffAngle) && !$defaultInfo->LayerExist("fsch") ) {
			$dataMngr->_AddErrorResult( "Checking NC layer",
								 "Layer fsch doesn't exist. When panel contains one type of step but with various rotations, fsch must be created." );
		}
	}

	# 5) Check if outline chain are last in chain list
	my $checkLayer = "f";
	my @checkSteps = ();

	if ( $defaultInfo->LayerExist("fsch") ) {

		$checkLayer = "fsch";
		push( @checkSteps, "panel" );
	}
	else {

		my @uniqNestSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );
		@checkSteps = map { $_->{"stepName"} } @uniqNestSteps;
	}

	foreach my $s (@checkSteps) {

		my $messOutline = "";
		unless ( RoutCheckTools->OutlineToolIsLast( $inCAM, $jobId, $s, $checkLayer, \$messOutline ) ) {
			$dataMngr->_AddErrorResult( "Checking NC layer - outlines", $messOutline );
		}

	}

	# 6) Check foot down attributes
	
	my $routLayer = "f";
	my $tmpLayer = undef;
	my $checkL = undef;

	if ( $defaultInfo->LayerExist("fsch") ) {
		$routLayer = "fsch";
		$checkL = $routLayer;
	}else{
		
		# need faltten before check outline chains
		$tmpLayer = GeneralHelper->GetGUID();
		$inCAM->COM('flatten_layer', "source_layer" => $routLayer, "target_layer" => $tmpLayer );
		$checkL = $tmpLayer;
	}
 
	my $rtm = UniRTM->new($inCAM, $jobId, "panel", $checkL, 1);
	
	my @outline = $rtm->GetOutlineChains();

	my %hist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, "panel", $checkL, 1 );

	my $footCnt = 0;
	if ( defined $hist{".foot_down"}{""} ) {
		$footCnt = $hist{".foot_down"}{""};
	}
	
	if ( $footCnt != scalar(@outline) ) {
		$dataMngr->_AddWarningResult( "Checking foots",
									  "Number of 'foot_down' ($footCnt) doesn't match with number of outline routs (".scalar(@outline).") in layer: $routLayer" );
	}
	
	if($tmpLayer){
		$inCAM->COM('delete_layer', layer => $tmpLayer );
	}
	

	# 7) Check, when ALU material, if all plated holes aer in "f" layer

	if ( $defaultInfo->GetMaterialKind() =~ /al/i ) {

		my @uniqueSteps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

		foreach my $step (@uniqueSteps) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step->{"stepName"}, "m" );

			if ( $hist{"total"} != 0 ) {

				$dataMngr->_AddErrorResult(
											"Drilling",
											"Step: "
											  . $step->{"stepName"}
											  . " contains drilling in layer 'm'. When material is ALU, all drilling should be moved to layer 'f'."
				);

			}

		}

	}

	# 8) Check if fsch exist, and if "f" was changed if "fsch" was changed too
	if ( $defaultInfo->LayerExist("fsch") ) {

		my @uniqueSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );

		my $fschCreated = 0;

		# check if fsch was created

		foreach my $step (@uniqueSteps) {
			my @f = ( $step->{"stepName"}, "fsch" );
			if ( CamHelper->EntityChanged( $inCAM, $jobId, "created", \@f ) ) {
				$fschCreated = 1;
				last;
			}
		}

		# if fsch was created after open job, do not control
		unless ($fschCreated) {

			my $fModified = 0;
			foreach my $step (@uniqueSteps) {

				my @f = ( $step->{"stepName"}, "f" );
				if ( CamHelper->EntityChanged( $inCAM, $jobId, "modified", \@f ) ) {
					$fModified = 1;
					last;
				}
			}

			# if f modified, check if
			if ($fModified) {
				my @fsch = ( "panel", "fsch" );
				unless ( CamHelper->EntityChanged( $inCAM, $jobId, "modified", \@fsch ) ) {
					$dataMngr->_AddWarningResult( "Old 'fsch' layer",
												 "Layer 'f' was changed, but layer 'fsch' not. If necessary, change 'fsch' layer in 'panel' too.\n" );

				}
			}

		}
	}
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

