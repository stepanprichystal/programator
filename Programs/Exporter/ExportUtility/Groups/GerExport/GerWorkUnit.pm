#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::GerExport::GerWorkUnit;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');
#3th party library
use strict;
use warnings;

# local library
use aliased "Packages::Export::GerExport::GerMngr";


#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $unitId = shift;
	
	my $self  = {};
 
	$self = $class->SUPER::new($unitId);
	bless $self;

	# PROPERTIES

	# EVENTS

	return $self;
}

sub Init {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	
	my $taskData = $self->{"taskData"};
 
	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
 
	
 
	my $exportLayers =  $taskData->GetExportLayers();
	my $layers =  $taskData->GetLayers();
	my $pasteInfo =  $taskData->GetPasteInfo();
	my $mdiInfo =  $taskData->GetMdiInfo();
	my $jetprintInfo =  $taskData->GetJetprintInfo();
	
 
	my $mngr  = GerMngr->new( $inCAM, $jobId, $exportLayers, $layers, $pasteInfo, $mdiInfo, $jetprintInfo);
	
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

