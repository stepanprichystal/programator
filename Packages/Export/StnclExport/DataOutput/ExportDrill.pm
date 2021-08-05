
#-------------------------------------------------------------------------------------------#
# Description: Export NC programs for drilled stencil
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::DataOutput::ExportDrill;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Export::NCExport::ExportMngr';
use aliased 'Packages::Export::NCExport::Enums' => "ExportNCEnums";
 
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	 
	$self->{"step"} = "panel"; # step which stnecil data are exported from
	$self->{"ncExport"} = ExportMngr->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, ExportNCEnums->ExportMode_ALL, 1);
	$self->{"ncExport"}->{"onItemResult"}->Add( sub { $self->__OnExportResult(@_) } );
  

	return $self;
}

# Prepare gerber files
sub Output {
	my $self = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 
	# Check when more NC layers except "flc"
	my @allLayers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );
	
	my @layers = grep {$_->{"gROWname"} eq "flc"} @allLayers;
	
	if(scalar(@layers) == 0){
		
		die "Layer flc, doesn't exist";
	}
	
	if(scalar(@allLayers) > 1){
		
		die "There is more NC layers in job. Only NC board layer can be flc";
	}

 
	$self->{"ncExport"}->Run();
 
}
 

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

sub __OnExportResult {
	my $self = shift;
	my $item = shift;


	$self->_OnItemResult($item);
}

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::DataOutput::ExportDrill';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my $export = ExportDrill->new( $inCAM, $jobId);
	$export->Output();
	
}

1;

