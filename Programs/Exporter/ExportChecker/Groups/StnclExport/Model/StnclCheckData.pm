
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::StnclExport::Model::StnclCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;
use List::MoreUtils qw(uniq);

#local library
use aliased 'CamHelpers::CamJob';

#use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper';
use aliased 'Programs::Stencil::StencilCreator::Enums' => 'StnclEnums';
use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;

	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $groupData = $dataMngr->GetGroupData();

	my $defaultInfo  = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	my %stencilInfo = Helper->GetStencilInfo($jobId);

	my $workLayer = "ds";

	if ( $stencilInfo{"tech"} eq StnclEnums->Technology_DRILL ) {
		$workLayer = "flc";
	}

	# 1) test if thickness is not null
	my $thickness = $groupData->GetThickness();

	if ( !defined $thickness || $thickness eq "" || $thickness == 0 ) {

		$dataMngr->_AddErrorResult( "Stencil thickness", "Stencil thickness is not defined." );
	}

	# 2) test if stencil layer exist
	unless ( $defaultInfo->LayerExist($workLayer) ) {
		$dataMngr->_AddErrorResult( "Layer error", "Layer \"$workLayer\" is missing. Stencil data has to be prepared in this layer." );
	}

	# 3) test on drill  stencils
	if ( $stencilInfo{"tech"} eq StnclEnums->Technology_DRILL ) {

		my @layers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );

		if ( scalar(@layers) > 1 ) {

			my $str = join( ",", map { $_->{"gROWname"} } grep { $_->{"gROWname"} ne "flc" } @layers );

			$dataMngr->_AddErrorResult( "Layer error", "Only NC board layer can be \"flc\". Delete $str." );
		}
	}

	# 4) If half fiducial checked, find in layer bz atribute fiducial_layer
	my $inf = $groupData->GetFiducialInfo();
	if ( $inf->{"halfFiducials"} ) {

		my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, "o+1", $workLayer );
		my $attVal = $attHist{".fiducial_name"};

		unless ($attVal->{"_totalCnt"}) {
			$dataMngr->_AddErrorResult(
				"Fiducials",
				"Je zvolená volba vypálení fiduciálních značek do poloviny, ale značky nebyly nalezeny (vrstva: $workLayer)."
				  . " Přidej požadovaným značkám atribut \".fiducial_name\"."
			);
		}

		if ( $attVal->{"_totalCnt"} > 0 && $attVal->{"_totalCnt"} != 2 && $attVal->{"_totalCnt"} != 3 ) {

			$dataMngr->_AddWarningResult( "Fiducials", "Byl nalezen netypický počet fiduciálních značek: ".$attVal->{"_totalCnt"}." (vrstva: $workLayer). Je to ok?" );
		}
		
		if($inf->{"fiducSide"} ne "readable" && $inf->{"fiducSide"} ne "nonreadable"){
			
			$dataMngr->_AddErrorResult(
				"Fiducials", "Není uvedeno z jaké strany vypálit fiduciální značky" );
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

