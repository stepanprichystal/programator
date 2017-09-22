
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
	$self->{"dataMngr"}        = DataMngr->new();
	$self->{"stencilDataMngr"} = StencilDataMngr->new( $self->{"dataMngr"} );

	my $custInfo = HegMethods->GetCustomerInfo( $self->{"jobId"} );
	$self->{"customerNote"} = CustomerNote->new( $custInfo->{"reference_subjektu"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Set source data to DataMngr
	DataHelper->SetSourceData( $inCAM, $jobId, $self->{"dataMngr"} );
	
	# 2) Set default values
	$self->__DefaultValDataMngr(undef, undef, 1 );

	# 3) Set default customer values
	my $warnMess = "";
	my $res = DataHelper->SetDefaultData( $inCAM, $jobId, $self->{"dataMngr"}, $self->{"customerNote"}, \$warnMess );
 
	unless ($res) {

		my $messMngr = $self->{"form"}->GetMessageMngr();
		my @mess1    = ($warnMess);
		my @btn      = ("Beru na vìdomí");

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn );
	}
	
	$self->{"stencilDataMngr"}->Update();

	# Init form by source data in DataMngr
	$self->{"form"}->Init( $self->{"dataMngr"}, $self->{"stencilDataMngr"} );

	# Refresh form according actual data in DataMngr
	$self->__RefreshForm(1);

	$self->{"form"}->{"mainFrm"}->Show();

	$self->{"form"}->MainLoop();
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __OnFrmDataChanged {
	my $self        = shift;
	my $form        = shift;
	my $controlName = shift;
	my $newValue    = shift;

	# 2) update actual stored form data
	$self->__UpdateDataMngr();

	$self->__DefaultValDataMngr( $controlName, $newValue );

	$self->__RefreshForm();
}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __UpdateDataMngr {
	my $self = shift;

	# set default data

	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilDataMngr"};

	$dataMngr->SetStencilType( $self->{"form"}->GetStencilType() );

	my %size = $self->{"form"}->GetStencilSize();

	$dataMngr->SetStencilSizeX( $size{"w"} );
	$dataMngr->SetStencilSizeY( $size{"h"} );

	$dataMngr->SetStencilStep( $self->{"form"}->GetStencilStep() );

	$dataMngr->SetSpacing( $self->{"form"}->GetSpacing() );

	$dataMngr->SetSpacingType( $self->{"form"}->GetSpacingType() );

	$dataMngr->SetHCenterType( $self->{"form"}->GetHCenterType() );

	$dataMngr->SetSchemaType( $self->{"form"}->GetSchemaType() );

	$dataMngr->SetHoleSize( $self->{"form"}->GetHoleSize() );

	$dataMngr->SetHoleDist( $self->{"form"}->GetHoleDist() );

	$dataMngr->SetHoleDist2( $self->{"form"}->GetHoleDist2() );

	$dataMngr->SetHoleDist2( $self->{"form"}->GetHoleDist2() );

	$dataMngr->SetAddPcbNumber( $self->{"form"}->GetAddPcbNumber() );

	$stencilMngr->Update();

}


sub __RefreshForm {
	my $self = shift;
	my $autoZoom = shift;

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

	$self->{"form"}->SetAddPcbNumber( $self->{"dataMngr"}->GetAddPcbNumber() );

	$self->{"form"}->{"raiseEvt"} = 1;

	# 3) refresh form drawing
	$self->{"form"}->UpdateDrawing($autoZoom);

}

# ================================================================================
# METHODS WHICH SET DEFAULT DATA VALUES
# ================================================================================

sub __DefaultValDataMngr {
	my $self        = shift;
	my $controlName = shift;
	my $newValue    = shift;
	my $force = shift;

	# set specific default value

	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilDataMngr"};

	# 1) Set default hole distance, if dimension or schema type is changed
	if ( $force || grep { $_ eq $controlName } ( "size", "sizeX", "sizeY", "schemaType" ) ) {

		$self->__DefaultHoleDist();

	}

	# 2) Set spacing type according center type
	if ( $force || ($controlName eq "hCenterType" && $dataMngr->GetStencilType() eq Enums->StencilType_TOPBOT) ) {

		$self->__DefaultSpacingType();
	}

	# 3) If Top + Bot compute default vertical spacing between pcb

	if ( $force || grep { $_ eq $controlName } ( "stencilType", "step", "size", "sizeY", "spacingType", "hCenterType", "schemaType", "holeDist2" ) ) {

		$self->__DefaultSpacing();

	}

}

sub __DefaultHoleDist {
	my $self = shift;

	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilDataMngr"};

	if ( $dataMngr->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my $holeDist2 = $dataMngr->GetStencilSizeY() - 2 * 12;    # 12 mm is standard distance from top/bot edge of stencil, where holes are placed
		$dataMngr->SetHoleDist2($holeDist2);

		$stencilMngr->Update();
	}

}

sub __DefaultSpacingType {
	my $self = shift;

	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilDataMngr"};

	if ( $dataMngr->GetHCenterType() eq Enums->HCenter_BYPROF ) {

		$dataMngr->SetSpacingType( Enums->Spacing_PROF2PROF );

	}
	elsif ( $dataMngr->GetHCenterType() eq Enums->HCenter_BYDATA ) {

		$dataMngr->SetSpacingType( Enums->Spacing_DATA2DATA );
	}

	$stencilMngr->Update();

}

sub __DefaultSpacing {
	my $self = shift;

	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilDataMngr"};

	if ( $dataMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		my $spacing    = 0;
		my %activeArea = $stencilMngr->GetStencilActiveArea();

		if ( $dataMngr->GetHCenterType() eq Enums->HCenter_BYPROF ) {

			$spacing = ( $activeArea{"h"} - $stencilMngr->GetTopProfile()->GetHeight() - $stencilMngr->GetBotProfile()->GetHeight() ) / 3;

		}
		elsif ( $dataMngr->GetHCenterType() eq Enums->HCenter_BYDATA ) {

			$spacing =
			  ( $activeArea{"h"} -
				$stencilMngr->GetTopProfile()->GetPasteData()->GetHeight() -
				$stencilMngr->GetBotProfile()->GetPasteData()->GetHeight() ) / 3;

		}

		$dataMngr->SetSpacing( sprintf( "%.1f", $spacing ) );

		$stencilMngr->Update();
	}
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

