
#-------------------------------------------------------------------------------------------#
# Description: Stencil creator prepare stencil lazer for export
# Provides stencil panelization and GUI
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::CpnWizard;

#3th party library
use strict;
use warnings;


#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardFrm';
 

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
 
	$self->{"inCAM"} = undef;

	# Main application form
	$self->{"form"} = WizardFrm->new( -1, $self->{"jobId"} );

	# Data where are stored stencil position, deimensions etc
 

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;

	$self->{"launcher"} = $launcher;
	$self->{"inCAM"}    = $launcher->GetInCAM();
 		
 	$self->{"form"}->Init($self->{"inCAM"});	 

	#set handlers for main app form
	$self->__SetHandlers();

}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

  

	$self->{"form"}->{"mainFrm"}->Show();

	$self->{"form"}->MainLoop();
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __SetHandlers {
	my $self = shift;

#	$self->{"form"}->{"fmrDataChanged"}->Add( sub { $self->__OnFrmDataChanged(@_) } );
#
#	$self->{"form"}->{"prepareClick"}->Add( sub { $self->__OnPrepareClick(@_) } );
#	
#	$self->{"stencilPopup"}->{'stencilOutputEvt'}->Add(  sub {$self->__OutputStencil(@_)});

}
 

# ================================================================================
# PRIVATE METHODS
# ================================================================================
 
 
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

