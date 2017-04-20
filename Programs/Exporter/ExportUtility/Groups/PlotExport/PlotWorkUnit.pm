#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::PlotExport::PlotWorkUnit;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');
#3th party library
use strict;
use warnings;

# local library
use aliased "Packages::Export::PlotExport::PlotMngr";


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
	 
	
 
	
	my $layers =  $taskData->GetLayers();
	my $sendToPlotter =  $taskData->GetSendToPlotter();
	
	
	my $mngr  = PlotMngr->new( $inCAM, $jobId, $layers, $sendToPlotter);
	
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

