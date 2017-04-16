#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides code for process of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::PoolMerge::Groups::OutputGroup::OutputWorkUnit;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');
#3th party library
use strict;
use warnings;

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
#use aliased 'Programs::PoolMerge::Groups::NifExport::NifGroup';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Packages::Events::Event';
use aliased 'Packages::PoolMerge::OutputGroup::OutputMngr';

#-------------------------------------------------------------------------------------------#
#  
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
	 

	 
	 
	my $mngr = OutputMngr->new($inCAM, $jobId);
	
	$mngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );
	$mngr->{"onStatusResult"}->Add( sub { $self->_OnStatusResultHandler(@_) } );
	
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

