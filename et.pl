#!/usr/bin/perl

use warnings;

use Tk;
use Tk::BrowseEntry;
use Tk::LabEntry;
use Tk::LabFrame;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path qw( rmtree );

#use LoadLibrary;
#use GenesisHelper;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::HeliosConnector::HelperWriter';

use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerWarnInfo';
use aliased 'Packages::Input::HelperInput';
use aliased 'Packages::GuideSubs::Netlist::NetlistControl';

use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamFilter';

use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Packages::ProductionPanel::PoolStepPlacement';
use aliased 'Packages::ProductionPanel::CheckPanel';
use aliased 'Packages::ProductionPanel::CounterPoolPcb';

use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';
use aliased 'Packages::Routing::PilotHole';
use aliased 'Packages::Routing::PlatedRoutAtt';
use aliased 'Packages::Routing::PlatedRoutArea';
 
use aliased 'Packages::GuideSubs::Scoring::DoFlattenScore';
use aliased 'Packages::Stackup::StackupDefault';
use aliased 'Packages::GuideSubs::Routing::CheckRout';
use aliased 'Packages::Compare::Layers::CompareLayers';
use aliased 'Packages::CAMJob::SolderMask::PreparationLayout';
use aliased 'Packages::GuideSubs::Drilling::BlindDrilling::BlindDrillTools';
use aliased 'Packages::GuideSubs::Drilling::BlindDrilling::CheckDrillTools';

use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';

use aliased 'Enums::EnumsProducPanel';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmpPool';

use aliased 'Managers::MessageMngr::MessageMngr';

my $inCAM = InCAM->new();
	
my $jobId = "$ENV{JOB}";



	foreach my $l (CamJob->GetBoardBaseLayers( $inCAM, $jobId )) {

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "o+1", $l->{"gROWname"}, 1 );

		if ( $attHist{".rout_chain"} || $attHist{".comp"} ) {
			
				$inCAM->PAUSE("obsahuje");
		}
	}
	
	
	
	
	
	
	