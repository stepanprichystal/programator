#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::GroupSettPnl;
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $group  = shift;

	my $controlHeight = shift;

	unless ($controlHeight) {
		$controlHeight = -1;
	}

	my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition, [ -1, $controlHeight ] );

	bless($self);

	$self->__SetLayout($group);

	return $self;
}

sub __SetLayout {
	my $self  = shift;
	my $group = shift;

	#define color of panel
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $groupTxt = Wx::StaticText->new( $self, -1, "$group",  &Wx::wxDefaultPosition,  [ 25, 25 ] );
	my $btnSett = Wx::Button->new( $self, -1, "Group", &Wx::wxDefaultPosition, [ 80, 28 ] );
	my $btmIco = Wx::Bitmap->new( Helper->GetResourcePath()."settings20x20.bmp", &Wx::wxBITMAP_TYPE_BMP );#wxBITMAP_TYPE_PNG
	$btnSett->SetBitmap($btmIco);

	$szMain->Add( $groupTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $btnSett,  0, &Wx::wxALL, 0 );
	$self->SetSizer($szMain);

}

1;
