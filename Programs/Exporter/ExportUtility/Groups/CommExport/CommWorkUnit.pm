#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::CommExport::CommWorkUnit;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');

#3th party library
use strict;
use warnings;

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Packages::Events::Event';
use aliased 'Packages::Export::CommExport::CommMngr';

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

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	my $changeOrderStatus = $taskData->GetChangeOrderStatus();
	my $orderStatus       = $taskData->GetOrderStatus();
	my $exportEmail       = $taskData->GetExportEmail();
	my $emailAction       = $taskData->GetEmailAction();
	my $emailTo           = $taskData->GetEmailToAddress();
	my $emailCC           = $taskData->GetEmailCCAddress();
	my $emailSubject      = $taskData->GetEmailSubject();
	my $clearComments     = $taskData->GetClearComments();

	my $mngr = CommMngr->new( $inCAM, $jobId, $changeOrderStatus, $orderStatus, $exportEmail, $emailAction, $emailTo, $emailCC, $emailSubject,
							  $clearComments );

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

