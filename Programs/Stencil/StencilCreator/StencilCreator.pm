
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilCreator::StencilCreator;

#3th party library
use strict;
use warnings;
use threads;
use threads::shared;


#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Stencil::StencilCreator::Forms::StencilFrm';
use aliased 'Programs::Stencil::StencilCreator::Helpers::DataHelper';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Programs::Stencil::StencilCreator::DataMngr::DataMngr';
use aliased 'Programs::Stencil::StencilCreator::DataMngr::StencilDataMngr::StencilDataMngr';
use aliased 'Programs::Stencil::StencilCreator::Enums';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Output';
use aliased 'Programs::Stencil::StencilCreator::StencilPopup';

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

	$self->{"jobId"} = shift;

	$self->{"stencilSrc"} = shift;    # existing job or customer data
	$self->{"jobIdSrc"}   = shift;    # if source job, contain job id

	$self->{"inCAM"} = undef;

	# Main application form
	$self->{"form"} = StencilFrm->new( -1,  $self->{"jobId"} );

	# Data where are stored stencil position, deimensions etc
	$self->{"dataMngr"}        = DataMngr->new();
	$self->{"stencilDataMngr"} = StencilDataMngr->new( $self->{"dataMngr"} );

	$self->{"stencilPopup"} = StencilPopup->new( $self->{"jobId"}, $self->{"form"}, $self->{"dataMngr"}, $self->{"stencilDataMngr"},
												 $self->{"stencilSrc"}, $self->{"jobIdSrc"} );

	$self->{"output"} = undef;
	$self->{"dataHelper"} = undef;

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;

	$self->{"launcher"} = $launcher;
	$self->{"inCAM"}    = $launcher->GetInCAM();
	
	$self->{"output"} = Output->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"dataMngr"}, $self->{"stencilDataMngr"} );
	$self->{"dataHelper"} = DataHelper->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"dataMngr"}, $self->{"stencilDataMngr"},
											 $self->{"stencilSrc"}, $self->{"jobIdSrc"} );
											 
	# 1) Set source data to DataMngr
	$self->{"dataHelper"}->SetSourceData();										 

	#set handlers for main app form
	$self->__SetHandlers();

}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

 
	# 2) Set default settings by IS
	my $warnMess = "";
	my $res      = $self->{"dataHelper"}->SetDefaultByIS( \$warnMess );

	unless ($res) {

		my $messMngr = $self->{"form"}->_GetMessageMngr();
		my @mess1    = ($warnMess);
		my @btn      = ("Beru na vìdomí");

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn );
	}

	# 3) Set default settings by Customer notes
	my $custWarnMess = "";
	my $custRes      = $self->{"dataHelper"}->SetDefaultByCustomer( \$custWarnMess );

	# Init form by source data in DataMngr
	$self->{"form"}->Init( $inCAM, $self->{"dataMngr"}, $self->{"stencilDataMngr"} );

	# Refresh form according actual data in DataMngr
	$self->__RefreshForm(1);

	$self->{"form"}->{"mainFrm"}->Show();

	$self->{"form"}->MainLoop();
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __SetHandlers {
	my $self = shift;

	$self->{"form"}->{"fmrDataChanged"}->Add( sub { $self->__OnFrmDataChanged(@_) } );

	$self->{"form"}->{"prepareClick"}->Add( sub { $self->__OnPrepareClick(@_) } );
	
	$self->{"stencilPopup"}->{'stencilOutputEvt'}->Add(  sub {$self->__OutputStencil(@_)});

}

sub __OnFrmDataChanged {
	my $self        = shift;
	my $form        = shift;
	my $controlName = shift;
	my $newValue    = shift;

	# 2) update actual stored form data
	$self->__UpdateDataMngr();

	$self->__DefaultCompValues( $controlName, $newValue );

	$self->__RefreshForm();
}

sub __OnPrepareClick {
	my $self = shift;

	# Do check before prepare

	$self->{"stencilPopup"}->Init(  $self->{"launcher"} );
	$self->{"stencilPopup"}->Run();
	
	

#	my $mess = "";
#	my $res  = $self->{"dataHelper"}->CheckBeforeOutput( \$mess );
#
#	unless ($res) {
#
#		my $messMngr = $self->{"form"}->GetMessageMngr();
#		my @mess1    = ($mess);
#		my @btn      = ( "Prepare force", "Cancel" );
#
#		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn );
#		if ( $messMngr->Result() == 1 ) {
#			return 0;
#		}
#	}

	

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

	$dataMngr->SetCenterType( $self->{"form"}->GetCenterType() );

	$dataMngr->SetSchemaType( $self->{"form"}->GetSchemaType() );

	$dataMngr->SetHoleSize( $self->{"form"}->GetHoleSize() );

	$dataMngr->SetHoleDist( $self->{"form"}->GetHoleDist() );

	$dataMngr->SetHoleDist2( $self->{"form"}->GetHoleDist2() );

	$dataMngr->SetHoleDist2( $self->{"form"}->GetHoleDist2() );

	$dataMngr->SetAddPcbNumber( $self->{"form"}->GetAddPcbNumber() );

	$stencilMngr->Update();

}

sub __RefreshForm {
	my $self     = shift;
	my $autoZoom = shift;

	# 2) refresh form controls
	$self->{"form"}->{"raiseEvt"} = 0;

	$self->{"form"}->SetStencilType( $self->{"dataMngr"}->GetStencilType() );

	$self->{"form"}->SetStencilSize( $self->{"dataMngr"}->GetStencilSizeX(), $self->{"dataMngr"}->GetStencilSizeY() );

	$self->{"form"}->SetStencilStep( $self->{"dataMngr"}->GetStencilStep() );

	$self->{"form"}->SetSpacing( $self->{"dataMngr"}->GetSpacing() );

	$self->{"form"}->SetSpacingType( $self->{"dataMngr"}->GetSpacingType() );

	$self->{"form"}->SetCenterType( $self->{"dataMngr"}->GetCenterType() );

	$self->{"form"}->SetSchemaType( $self->{"dataMngr"}->GetSchemaType() );

	$self->{"form"}->SetHoleSize( $self->{"dataMngr"}->GetHoleSize() );

	$self->{"form"}->SetHoleDist( $self->{"dataMngr"}->GetHoleDist() );

	$self->{"form"}->SetHoleDist2( $self->{"dataMngr"}->GetHoleDist2() );

	$self->{"form"}->SetHoleDist2( $self->{"dataMngr"}->GetHoleDist2() );

	$self->{"form"}->SetAddPcbNumber( $self->{"dataMngr"}->GetAddPcbNumber() );

	$self->{"form"}->{"raiseEvt"} = 1;

	# 3) refresh form drawing
	$self->{"stencilDataMngr"}->Update();

	$self->{"form"}->UpdateDrawing($autoZoom);

}

# Prepare final layer
sub __OutputStencil {
	my $self = shift;

	$self->{"output"}->PrepareLayer();
	
	$self->{"form"}->{"mainFrm"}->Close();
}

# ================================================================================
# METHODS WHICH SET DEFAULT DATA VALUES
# ================================================================================

# Compute default values, which are depand on another stencil settings
sub __DefaultCompValues {
	my $self        = shift;
	my $controlName = shift;
	my $newValue    = shift;
	my $force       = shift;

	# set specific default value

	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilDataMngr"};

	# 1) Set default hole distance, if dimension or schema type is changed
	if ( $force || grep { $_ eq $controlName } ( "size", "sizeX", "sizeY", "schemaType" ) ) {

		$dataMngr->DefaultHoleDist();

	}

	# 2) Set spacing type according center type
	if ( $force || ( $controlName eq "hCenterType" && $dataMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) ) {

		$dataMngr->DefaultSpacingType();
	}

	# 3) If Top + Bot compute default vertical spacing between pcb

	if ( $force || grep { $_ eq $controlName } ( "stencilType", "step", "size", "sizeY", "spacingType", "hCenterType", "schemaType", "holeDist2" ) ) {

		$dataMngr->DefaultSpacing($stencilMngr);

	}

	$stencilMngr->Update();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Stencil::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	#my $creator = StencilCreator->new( $inCAM, $jobId, Enums->StencilSource_JOB, "f13609" );
	my $creator = StencilCreator->new( $inCAM, $jobId, Enums->StencilSource_CUSTDATA);
	
	
	
	$creator->Run();

}

1;

