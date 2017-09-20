
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::StencilCreator;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::StencilCreator::Forms::StencilFrm';
use aliased 'Programs::StencilCreator::Helpers::DataHelper';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Programs::StencilCreator::DataMngr::DataMngr';
use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::StencilDataMngr';
use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::PasteProfile';
use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::PasteData';
use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::Schema';
use aliased 'Programs::StencilCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	# Main application form
	$self->{"form"} = StencilFrm->new( -1, $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"form"}->{"fmrDataChanged"}->Add( sub { $self->__OnFrmDataChanged(@_) } );

	# Data where are stored stencil position, deimensions etc
	$self->{"dataMngr"} = DataMngr->new();

	my $custInfo = HegMethods->GetCustomerInfo( $self->{"jobId"} );
	$self->{"customerNote"} = CustomerNote->new( $custInfo->{"reference_subjektu"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Set source data to DataMngr
	DataHelper->SetSourceData( $inCAM, $jobId, $self->{"dataMngr"} );

	# Set default data to DataMngr
	my $warnMess = "";
	my $res = DataHelper->SetDefaultData( $inCAM, $jobId, $self->{"dataMngr"}, $self->{"customerNote"}, \$warnMess );
	
	$self->__UpdateStencilDataMngr();

	unless ($res) {

		my $messMngr = $self->{"form"}->GetMessageMngr();
		my @mess1    = ($warnMess);
		my @btn      = ("Beru na vìdomí");

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn );
	}

	# Init form by source data in DataMngr
	$self->{"form"}->Init( $self->{"dataMngr"}->{"stepsSize"}, $self->{"dataMngr"}->{"steps"}, $self->{"dataMngr"}->{"topExist"},
						   $self->{"dataMngr"}->{"botExist"} );

	# Refresh form according actual data in DataMngr
	$self->__RefreshForm();

	$self->{"form"}->{"mainFrm"}->Show();

	$self->{"form"}->MainLoop();
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __OnFrmDataChanged {
	my $self = shift;
	my $form = shift;
	my $controlName = shift;
	my $newValue = shift;

	# 2) update actual stored form data
	$self->__UpdateDataMngr($form, $controlName, $newValue);
 

	$self->__RefreshForm();
}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __UpdateDataMngr {
	my $self = shift;
	my $form = shift;
	my $controlName = shift;
	my $newValue = shift;

	# set default data

	$self->{"dataMngr"}->SetStencilType( $self->{"form"}->GetStencilType() );

	my %size = $self->{"form"}->GetStencilSize();

	$self->{"dataMngr"}->SetStencilSizeX( $size{"w"} );
	$self->{"dataMngr"}->SetStencilSizeY( $size{"h"} );

	$self->{"dataMngr"}->SetStencilStep( $self->{"form"}->GetStencilStep() );
  

	$self->{"dataMngr"}->SetSpacing( $self->{"form"}->GetSpacing() );

	$self->{"dataMngr"}->SetSpacingType( $self->{"form"}->GetSpacingType() );

	$self->{"dataMngr"}->SetHCenterType( $self->{"form"}->GetHCenterType() );

	$self->{"dataMngr"}->SetSchemaType( $self->{"form"}->GetSchemaType() );

	$self->{"dataMngr"}->SetHoleSize( $self->{"form"}->GetHoleSize() );

	$self->{"dataMngr"}->SetHoleDist( $self->{"form"}->GetHoleDist() );

	$self->{"dataMngr"}->SetHoleDist2( $self->{"form"}->GetHoleDist2() );

	$self->{"dataMngr"}->SetHoleDist2( $self->{"form"}->GetHoleDist2() );
	
	$self->__UpdateStencilDataMngr();
	
	
	# set specific default value
		 	
	# compute default spacing
#	if($self->{"dataMngr"}->GetStencilType() eq Enums->StencilType_TOPBOT){
#		
#		 my $stencilMngr = $self->{"dataMngr"}->GetStencilDataMngr();
#		
#			if ( $defaultSpacing && $dataMngr->GetSpacingType() eq Enums->Spacing_PROF2PROF ) {
#
#		my $spac = $stencilMngr->GetDefaultSpacing();
#		$stencilMngr->SetSpacing($spac);
#
#		# set spacing to control
#		#$dataMngr->SetSpacing($spac);
#
#	}
#	else {
#		
#			my $h = $stencilMngr->GetTopProfile()->GetHeight();
#		
#		 my $spacing = 
#	}
	 
}

sub __UpdateStencilDataMngr {
	my $self           = shift;
	my $autoZoom       = shift;
	

	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"dataMngr"}->GetStencilDataMngr();

	# 1) update type of stencil
	my $stencilType = $dataMngr->GetStencilType();
	$stencilMngr->SetStencilType($stencilType);

	# 2) update profile data
	my $stencilStep = $dataMngr->GetStencilStep();

	if ( $dataMngr->{"topExist"} ) {

		my $pd =
		  PasteData->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"h"} );
		my $pp = PasteProfile->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"h"} );

		$pp->SetPasteData( $pd, $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"x"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"y"} );

		$stencilMngr->SetTopProfile($pp);
	}

	if ( $dataMngr->{"botExist"} ) {

		my $botKye = $stencilType eq Enums->StencilType_BOT ? "bot" : "botMirror";

		my $pd =
		  PasteData->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"h"} );
		my $pp = PasteProfile->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"h"} );

		$pp->SetPasteData( $pd,
						   $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"x"},
						   $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"y"} );

		$stencilMngr->SetBotProfile($pp);
	}

	# 3)update stencil size

	$stencilMngr->SetWidth( $dataMngr->GetStencilSizeX() );
	$stencilMngr->SetHeight( $dataMngr->GetStencilSizeY() );

	# 4) Update schema

	my $schema = Schema->new( $dataMngr->GetStencilSizeX() , $dataMngr->GetStencilSizeY() );

	$schema->SetSchemaType( $dataMngr->GetSchemaType() );
	$schema->SetHoleSize( $dataMngr->GetHoleSize() );
	$schema->SetHoleDist( $dataMngr->GetHoleDist() );
	$schema->SetHoleDist2( $dataMngr->GetHoleDist2() );

	$stencilMngr->SetSchema($schema);

	# 5) Spacing type
	$stencilMngr->SetSpacingType( $dataMngr->GetSpacingType() );

	# 4) Set spacing size

	$stencilMngr->SetSpacing( $dataMngr->GetSpacing() );
	 

	# 5)Set horiyontal aligment type
	$stencilMngr->SetHCenterType( $dataMngr->GetHCenterType() );

}

sub __RefreshForm {
	my $self = shift;

	# 2) refresh form controls
	$self->{"form"}->{"raiseEvt"} = 0;

	$self->{"form"}->SetStencilType( $self->{"dataMngr"}->GetStencilType() );

	$self->{"form"}->SetStencilSize( $self->{"dataMngr"}->GetStencilSizeX(), $self->{"dataMngr"}->GetStencilSizeY() );

	$self->{"form"}->SetStencilStep( $self->{"dataMngr"}->GetStencilStep() );

	$self->{"form"}->SetSpacing( $self->{"dataMngr"}->GetSpacing() );

	$self->{"form"}->SetSpacingType( $self->{"dataMngr"}->GetSpacingType() );

	$self->{"form"}->SetHCenterType( $self->{"dataMngr"}->GetHCenterType() );

	$self->{"form"}->SetSchemaType( $self->{"dataMngr"}->GetSchemaType() );

	$self->{"form"}->SetHoleSize( $self->{"dataMngr"}->GetHoleSize() );

	$self->{"form"}->SetHoleDist( $self->{"dataMngr"}->GetHoleDist() );

	$self->{"form"}->SetHoleDist2( $self->{"dataMngr"}->GetHoleDist2() );

	$self->{"form"}->SetHoleDist2( $self->{"dataMngr"}->GetHoleDist2() );

	$self->{"form"}->{"raiseEvt"} = 1;

	# 3) refresh form drawing
	$self->{"form"}->UpdateDrawing($self->{"dataMngr"}->GetStencilDataMngr());

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $creator = StencilCreator->new( $inCAM, $jobId );
	$creator->Run();

}

1;

