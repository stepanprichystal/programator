#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::ETExport::ETExport;
use base('Managers::AbstractQueue::Groups::TaskClassBase');
#3th party library
use strict;
use warnings;

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Packages::Events::Event';
use aliased 'Packages::Export::ETExport::ETMngr';

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
	my $taskData = shift;
	 

	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
	$self->{"taskData"} = $taskData;
	
	
	my $step = $taskData->GetStepToTest();
	my $createEtStep = $taskData->GetCreateEtStep();
	
	my $mngr = ETMngr->new($inCAM, $jobId, $step, $createEtStep);
	
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

