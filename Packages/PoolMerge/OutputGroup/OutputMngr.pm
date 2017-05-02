
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for prepare "export file", outpur stackup, pool file, etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::OutputGroup::OutputMngr;
use base('Packages::PoolMerge::PoolMngrBase');

use Class::Interface;
&implements('Packages::PoolMerge::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";
use aliased 'Programs::PoolMerge::Enums'     => "EnumsPool";
use aliased 'Helpers::FileHelper';
use aliased 'Packages::PoolMerge::OutputGroup::Helper::OtherSettings';
use aliased 'Packages::PoolMerge::OutputGroup::Helper::ExportPrepare';
use aliased 'Packages::PoolMerge::OutputGroup::Helper::PoolFile';
use aliased 'Packages::PoolMerge::OutputGroup::Helper::DefaultStackup';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $inCAM    = shift;
	my $poolInfo = shift;
	my $self     = $class->SUPER::new( $poolInfo->GetInfoFile(), @_ );
	bless $self;

	$self->{"inCAM"}    = $inCAM;
	$self->{"poolInfo"} = $poolInfo;


	$self->{"otherSettings"} = OtherSettings->new( $inCAM, $poolInfo );
	$self->{"poolFile"} = PoolFile->new( $inCAM, $poolInfo );
	$self->{"poolFile"} = PoolFile->new( $inCAM, $poolInfo );
	$self->{"defaultStackup"} = DefaultStackup->new( $inCAM, $poolInfo );
	
	$self->{"exportPrepare"} = ExportPrepare->new( $inCAM, $poolInfo );
	$self->{"exportPrepare"}->{"onItemResult"}->Add( sub { $self->_OnPoolItemResult(@_) } );

	 

	return $self;
}

sub Run {
	my $self = shift;

	my $masterJob   = $self->GetValInfoFile("masterJob");
	my $masterOrder = $self->GetValInfoFile("masterOrder");

	# 1) Set mask, silk screens
	my $jobHeliosAttRes = $self->_GetNewItem("Set Helios attribute");
	my $mess            = "";

	unless ( $self->{"otherSettings"}->SetJobHeliosAttributes( $masterJob, \$mess ) ) {

		$jobHeliosAttRes->AddError($mess);
	}

	$self->_OnPoolItemResult($jobHeliosAttRes);

	# 2) Set layer attribute, pcb class, ..
	my $jobAttRes = $self->_GetNewItem("Set job attribute");
	$mess = "";

	unless ( $self->{"otherSettings"}->SetJobAttributes( $masterJob, \$mess ) ) {

		$jobAttRes->AddError($mess);
	}

	$self->_OnPoolItemResult($jobAttRes);

	# 3) Remove unused symbols, layers
	my $jobCleanupRes = $self->_GetNewItem("Job cleanup");
	$mess = "";

	unless ( $self->{"otherSettings"}->JobCleanup( $masterJob, \$mess ) ) {

		$jobCleanupRes->AddError($mess);
	}

	$self->_OnPoolItemResult($jobCleanupRes);


	# 4) Export default stackup

	if ( CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $masterJob ) > 2 ) {
		my $stackupRes = $self->_GetNewItem("Export stackup");
		$mess = "";

		unless ( $self->{"defaultStackup"}->CreateDefaultStackup( $masterJob, \$mess ) ) {

			$stackupRes->AddError($mess);
		}

		$self->_OnPoolItemResult($stackupRes);
	}


	# 5) do control before creating "export file"
	$self->{"exportPrepare"}->CheckBeforeExport($masterJob);

	# 6) Export "pool file"

	my $poolFileRes = $self->_GetNewItem("Export pool file");
	$mess = "";

	unless ( $self->{"poolFile"}->CreatePoolFile( $masterJob, $masterOrder, \$mess ) ) {

		$poolFileRes->AddError($mess);
	}

	$self->_OnPoolItemResult($poolFileRes);



	# 7) Prepare "export file"
	my $exportPath = GeneralHelper->GetGUID();
	$self->SetValInfoFile( "exportFile", $exportPath );
	$self->{"exportPrepare"}->PrepareExportFile( $masterJob, $masterOrder, $exportPath, \$mess );

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt +=  8;    														 # nubber of units which are checked
	$totalCnt += 6;                                                           # other checks..
	$totalCnt += 1;  # saving master job (doe in JobWorkerClass)
	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

