#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NifExport::NifExport;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');
#3th party library
use strict;
use warnings;

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Managers::MessageMngr::MessageMngr';

 
use aliased 'Packages::Export::NifExport::NifMngr';


 

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
	
 
 
	
	 
	
	my %exportNifData = %{$taskData->{"data"}};
	
	
	
	my $nifMngr = NifMngr->new( $inCAM, $jobId, \%exportNifData );
	
	$nifMngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );
	
	$self->{"taskMngr"} = $nifMngr;
	
	$self->{"itemsCount"} = $nifMngr->TaskItemsCount();
	
 
}



1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

