#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::StripSettPnl;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:richtextctrl :textctrl :font);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Packages::Events::Event';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $stripId = shift;
	my $type  = shift;
	my $model  = shift;

	my $controlHeight = shift;

	unless ($controlHeight) {
		$controlHeight = -1;
	}

	my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition, [ -1, $controlHeight ] );

	bless($self);

	$self->__SetLayout($stripId, $type, $model);
	
	$self->{"onStripSett"} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self  = shift;
		my $stripId = shift;
	my $type          = shift;
	my $model         = shift;

	#define color of panel
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $p = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnWizard\\Resources\\small_".$type."_".$model.".bmp";

	unless(-e $p){
		die;
	}

	my $btmIco = Wx::Bitmap->new( $p, &Wx::wxBITMAP_TYPE_BMP );#wxBITMAP_TYPE_PNG
	my $statBtmIco = Wx::StaticBitmap->new( $self, -1, $btmIco );

	my $titleTxt = Wx::StaticText->new( $self, -1, "$type - $model", &Wx::wxDefaultPosition, [ 200, 25 ]  );
	my $btnSett = Wx::Button->new( $self, -1, "Microstrip", &Wx::wxDefaultPosition, [ 100, 22 ] );
	my $btmBtnIco = Wx::Bitmap->new( Helper->GetResourcePath()."settings15x15.bmp", &Wx::wxBITMAP_TYPE_BMP );#wxBITMAP_TYPE_PNG
	$btnSett->SetBitmap($btmBtnIco);

	$szMain->Add( $statBtmIco, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $titleTxt,   0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szMain->Add( $btnSett,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->SetSizer($szMain);
	
	# Events
	Wx::Event::EVT_BUTTON( $btnSett, -1, sub { $self->{"onStripSett"}->Do($stripId) } );
	
 
}

1;
