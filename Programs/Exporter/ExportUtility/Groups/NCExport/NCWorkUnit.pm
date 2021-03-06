#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NCExport::NCWorkUnit;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');

#3th party library
use strict;
use warnings;

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Packages::Events::Event';
use aliased 'Packages::Export::NCExport::ExportMngr';

#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $unitId = shift;

	my $self = {};

	$self = $class->SUPER::new($unitId);
	bless $self;

	# PROPERTIES

	# EVENTS

	return $self;
}

sub Init {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $taskData = $self->{"taskData"};

	my $exportMode             = $taskData->GetExportMode();
	my $exportModeExportPnl    = $taskData->GetAllModeExportPnl();
	my $exportModeExportPnlCpn = $taskData->GetAllModeExportPnlCpn();
	my $pltLayers              = $taskData->GetSingleModePltLayers();
	my $npltLayers             = $taskData->GetSingleModeNPltLayers();
	my $modeAllLayers          = $taskData->GetAllModeLayers();

	my $mngr =
	  ExportMngr->new( $inCAM, $jobId, "panel", $exportMode, $exportModeExportPnl, $exportModeExportPnlCpn, $modeAllLayers, $pltLayers, $npltLayers )
	  ;
	$mngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );

	$self->{"taskMngr"} = $mngr;

	$self->{"itemsCount"} = $mngr->TaskItemsCount();

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

