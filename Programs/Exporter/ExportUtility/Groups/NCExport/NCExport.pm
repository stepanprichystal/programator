#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NCExport::NCExport;

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

	my $self = shift;
	$self = {};

	# PROPERTIES

	$self->{"unitId"} = shift;

	$self->{"itemsCount"}          = 0;
	$self->{"processedItemsCount"} = 0;

	$self->{"inCAM"}      = undef;
	$self->{"jobId"}      = undef;
	$self->{"exportData"} = undef;

	# EVENTS

	$self->{"onItemResult"} = Event->new();

	bless $self;
	return $self;
}

sub Init {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $exportData = shift;
	 

	
 
	
	my $exportSingle = $exportData->GetExportSingle();
	my $pltLayers = $exportData->GetPltLayers();
	my $npltLayers = $exportData->GetNPltLayers();
	
	my $mngr = ExportMngr->new( $inCAM, $jobId, "panel", $exportSingle, $pltLayers, $npltLayers);
	$mngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );
	
	$self->{"exportMngr"} = $mngr;
	
	$self->{"itemsCount"} = $mngr->ExportItemsCount();
	
 
}

sub Run {
	my $self = shift;

 
	

	

	$self->{"exportMngr"}->Run();

}

# Return process group value in percent
sub GetProgressValue {
	my $self       = shift;
	my $itemResult = shift;

	my $val = $self->{"processedItemsCount"} / $self->{"itemsCount"} *100;	
}

sub _OnItemResultHandler {
	my $self       = shift;
	my $itemResult = shift;

	$self->{"processedItemsCount"}++;

	$self->{"onItemResult"}->Do($itemResult);
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

