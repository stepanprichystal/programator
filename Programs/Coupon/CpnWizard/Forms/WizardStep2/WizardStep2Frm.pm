
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep2::WizardStep2Frm;
use base('Programs::Coupon::CpnWizard::Forms::WizardStepFrmBase');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::GroupQueueFrm';
use aliased 'Widgets::Forms::MyWxScrollPanel';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::GeneratorFrm';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::GlobalSettFrm';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupSettFrm';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::StripSettFrm';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
 


sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub GetLayout {
	my $self   = shift;
	my $parent = shift;

	my $pnlMain       = Wx::Panel->new( $parent,  -1 );
	my $pnlListHeader = Wx::Panel->new( $pnlMain, -1 );
	my $rowHeight     = 27;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szSettPanel    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szAutogenerate = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szListHeader   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRowList = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $btnGlobal = Wx::Button->new( $pnlMain, -1, "Global", &Wx::wxDefaultPosition, [ 100, 35 ] );
	my $btmIco = Wx::Bitmap->new( Helper->GetResourcePath() . "settings25x25.bmp", &Wx::wxBITMAP_TYPE_BMP );    #wxBITMAP_TYPE_PNG
	$btnGlobal->SetBitmap($btmIco);

	my $autogenerateTxt = Wx::StaticText->new( $pnlMain, -1, "When group settings don't fit inside a single Coupon:", &Wx::wxDefaultPosition );
	my $rbGenYes =
	  Wx::RadioButton->new( $pnlMain, -1, "Generate automatically new coupon", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbGenNo = Wx::RadioButton->new( $pnlMain, -1, "Stop generating coupon and notify me", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	# header for list
	$pnlListHeader->SetBackgroundColour( Wx::Colour->new( 127, 127, 127 ) );
	$pnlListHeader->SetForegroundColour( Wx::Colour->new( 250, 250, 250 ) );

	my $groupTxt = Wx::StaticText->new( $pnlListHeader, -1, "Group number", &Wx::wxDefaultPosition, [ 125, 25 ] );
	
	my $stripsTxt = Wx::StaticText->new( $pnlListHeader, -1, "Group microstrips", &Wx::wxDefaultPosition, [ 330, 25 ] );

	my $trackLTxt = Wx::StaticText->new( $pnlListHeader, -1, "Track layer", &Wx::wxDefaultPosition, [ 105, 25 ] );

	my $topRefTxt = Wx::StaticText->new( $pnlListHeader, -1, "Top ref layer", &Wx::wxDefaultPosition, [ 133, 25 ] );

	my $botRefTxt = Wx::StaticText->new( $pnlListHeader, -1, "Bot ref layer", &Wx::wxDefaultPosition, [ 133, 25 ] );

	my $impedanceTxt = Wx::StaticText->new( $pnlListHeader, -1, "Impedance", &Wx::wxDefaultPosition, [ 100, 25 ] );


	my $list = GroupQueueFrm->new($pnlMain);

	#$containerPnl->SetBackgroundColour( Wx::Colour->new( 0, 255, 0 ) );

	# BUILD STRUCTURE OF LAYOUT

	$szAutogenerate->Add( $autogenerateTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szAutogenerate->Add( $rbGenYes,        0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szAutogenerate->Add( $rbGenNo,         0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szSettPanel->Add( $btnGlobal, 0, &Wx::wxALL, 0 );
	$szSettPanel->Add( 1, 1, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szSettPanel->Add( $szAutogenerate, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szListHeader->Add( $groupTxt,  0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szListHeader->Add( $stripsTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szListHeader->Add( $trackLTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szListHeader->Add( $topRefTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szListHeader->Add( $botRefTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szListHeader->Add( $impedanceTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szMain->Add( $szSettPanel,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( 1,              5, 0 );
	$szMain->Add( $pnlListHeader, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $list,          1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	
	$pnlListHeader->SetSizer($szListHeader);
	$pnlMain->SetSizer($szMain);

	# SET EVENTS

	Wx::Event::EVT_BUTTON( $btnGlobal,      -1, sub { $self->__ShowGlobalSett() } );
	Wx::Event::EVT_RADIOBUTTON( $rbGenYes, -1, sub { $self->__OnRadioBtnChanged(1) } );
	Wx::Event::EVT_RADIOBUTTON( $rbGenNo,  -1, sub { $self->__OnRadioBtnChanged(0) } );


	$list->{"onGroupSett"}->Add( sub { $self->__ShowGroupSett(@_) } );
	$list->{"onStripSett"}->Add( sub { $self->__ShowStripSett(@_) } );

	

	# SET REFERENCES

	$self->{"groupList"} = $list;

	#$self->{"scrollPnl"}    = $scrollPnl;
	$self->{"parent"}   = $parent;
	$self->{"rbGenYes"} = $rbGenYes;
	$self->{"rbGenNo"}  = $rbGenNo;

	#$self->{"containerPnl"} = $containerPnl;

	#my ( $width, $height ) = $containerPnl->GetSizeWH();

	return $pnlMain;

}

sub Update {
	my $self       = shift;
	my $wizardStep = shift;

	$self->{"coreWizardStep"} = $wizardStep; # Update current step wizard
	
	my @uniqGroups  = $self->{"coreWizardStep"}->GetUniqueGroups();
	my @constr      = $self->{"coreWizardStep"}->GetConstraints();
	my $constrGroup = $self->{"coreWizardStep"}->GetConstrGroups();

	my $listFirstInit = 0;

	$self->{"groupList"}->SetGroups( \@uniqGroups, \@constr, $constrGroup );

	#	$self->{"scrollPnl"}->FitInside();
	#	$self->{"scrollPnl"}->Layout();
	#
	#	$self->{"scrollPnl"}->SetRowCount( scalar(@constr) );

	if ( $self->{"coreWizardStep"}->GetAutogenerate() ) {
		$self->{"rbGenYes"}->SetValue(1);
	}
	else {
		$self->{"rbGenNo"}->SetValue(1);
	}
}

sub __OnRadioBtnChanged {
	my $self         = shift;
	my $autogenerate = shift;

	$self->{"coreWizardStep"}->UpdateAutogenerate($autogenerate);

}

sub __ShowGlobalSett {
	my $self = shift;

	# User will edit only copy of global settings
	# If click Ok, global settings will be updated by this copy
	
	my $settingsTmp = $self->{"coreWizardStep"}->GetGlobalSett()->GetDeepCopy();

	my $result = 0;
	my $frm = GlobalSettFrm->new( $self->{"parentFrm"}, $settingsTmp, \$result );

	$frm->ShowModal();
 

	# update layout
	if ($result) {

		my $globSett = $self->{"coreWizardStep"}->GetGlobalSett();
		$globSett->UpdateSettings($settingsTmp);
	}

}

sub __ShowGroupSett {
	my $self = shift;
	my $groupId = shift;

	# User will edit only copy of global settings
	# If click Ok, global settings will be updated by this copy
	
	my $settingsTmp = $self->{"coreWizardStep"}->GetGroupSettings($groupId)->GetDeepCopy();

	my $result = 0;
	my $frm = GroupSettFrm->new( $self->{"parentFrm"}, $settingsTmp, \$result );

	$frm->ShowModal();
 

	# update layout
	if ($result) {

		my $groupSett = $self->{"coreWizardStep"}->GetGroupSettings($groupId);
		$groupSett->UpdateSettings($settingsTmp);
	}

}

sub __ShowStripSett {
	my $self = shift;
	my $stripId = shift;

	# User will edit only copy of global settings
	# If click Ok, global settings will be updated by this copy
	
	my $settingsTmp = $self->{"coreWizardStep"}->GetStripSettings($stripId)->GetDeepCopy();

	my $result = 0;
	my $frm = StripSettFrm->new( $self->{"parentFrm"}, $settingsTmp, \$result );

	$frm->ShowModal();
  
	# update layout
	if ($result) {

		my $stripSett = $self->{"coreWizardStep"}->GetStripSettings($stripId);
		$stripSett->UpdateSettings($settingsTmp);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardCore';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

}

1;

