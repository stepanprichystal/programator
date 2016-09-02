#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NifExport::NifExport;

#3th party library
use strict;
use warnings;

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Packages::Events::Event';
use aliased 'Packages::Export::NifExport::NifMngr';

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
	 

	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
	$self->{"exportData"} = $exportData;
	
	
	my $nifMngr = NifMngr->new( $inCAM, $jobId, $exportData );
	$nifMngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );
	
	$self->{"exportMngr"} = $nifMngr;
	
	$self->{"itemsCount"} = $nifMngr->ExportItemsCount();
	
 
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

