#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::Groups::OutExport::OutExport;
use base('Managers::AbstractQueue::Groups::ExportBase');
#3th party library
use strict;
use warnings;

# local library
use aliased "Packages::Export::OutExport::OutMngr";


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
	my $exportData = shift;
	 

	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
	$self->{"exportData"} = $exportData;
	
 
	my $exportCooper =  $exportData->GetExportCooper();
	my $exportEt =  $exportData->GetExportET();
	my $cooperStep =  $exportData->GetCooperStep();
	my $exportControl =  $exportData->GetExportControl();
 	my $controlStep =  $exportData->GetControlStep();
	
	my $mngr  = OutMngr->new( $inCAM, $jobId, $exportCooper, $cooperStep, $exportEt, $exportControl, $controlStep);
	
	$mngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );
	
	$self->{"exportMngr"} = $mngr;
	
	$self->{"itemsCount"} = $mngr->ExportItemsCount();
	
}



1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

