#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NCExport::Presenter::NCExport;
use base('Programs::Exporter::ExportUtility::Groups::ExportBase');
#3th party library
use strict;
use warnings;

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Managers::MessageMngr::MessageMngr';

 
use aliased 'Packages::Export::NCExport::ExportMngr';

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
 

	my $data = $exportData->GetUnitData( $self->{"unitId"} );

	my $mngr = ExportMngr->new( $inCAM, $jobId, "panel", $data->SetExportSingle(), $data->GetPltLayers(), $data->GetNPltLayers() );
	
	$mngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );
	
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

