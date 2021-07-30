
#-------------------------------------------------------------------------------------------#
# Description: View form for specific creator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::CpnPart::View::Creators::SemiautoFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;
use List::Util qw(first);

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStep';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Programs::Panelisation::PnlWizard::Parts::CpnPart::View::Creators::Frm::CpnSettFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::ManualPlacement';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->CpnPnlCreator_SEMIAUTO, $parent, $inCAM, $jobId );

	bless($self);

	# PROPERTIES

	$self->{"impCpnRequired"}   = 0;
	$self->{"IPC3CpnRequired"}  = 0;
	$self->{"zAxisCpnRequired"} = 0;

	$self->__SetLayout();

	# DEFINE EVENTS
	$self->{"manualPlacementEvt"} = Event->new();

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $cpnsStatBox      = $self->__SetLayoutCpns();
	my $placementStatBox = $self->__SetLayoutPlacement();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $cpnsStatBox,      0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $placementStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for coupon settings
sub __SetLayoutCpns {
	my $self = shift;

	my $parent = $self;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Coupon placement settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );

	# IMP coupon

	my $impCpn = CpnSettFrm->new( $statBox, "Impedance" );

	$impCpn->_AddPlacementType( PnlCreEnums->ImpCpnType_1, "7 ks",
								GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ImpCpnType_1 . ".png" );
	$impCpn->_AddPlacementType( PnlCreEnums->ImpCpnType_2, "5 ks",
								GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ImpCpnType_2 . ".png" );
	$impCpn->_AddPlacementType( PnlCreEnums->ImpCpnType_3, "3 ks",
								GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ImpCpnType_3 . ".png" );
	$impCpn->_AddPlacementType( PnlCreEnums->ImpCpnType_4, "6 ks",
								GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ImpCpnType_4 . ".png" );
	$impCpn->_AddPlacementType( PnlCreEnums->ImpCpnType_5, "4 ks",
								GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ImpCpnType_5 . ".png" );
	$impCpn->_AddPlacementType( PnlCreEnums->ImpCpnType_6, "2 ks",
								GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ImpCpnType_6 . ".png" );

	my $impCpnBaseName = EnumsGeneral->Coupon_IMPEDANCE;
	$impCpn->Hide() if ( scalar( grep { $_ =~ /$impCpnBaseName/i } @steps ) == 0 );

	# IPC3 coupon

	my $IPC3Cpn = CpnSettFrm->new( $statBox, "IPC3" );

	$IPC3Cpn->_AddPlacementType( PnlCreEnums->IPC3CpnType_1,
								 "6 ks", GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ImpCpnType_1 . ".png" );
	$IPC3Cpn->_AddPlacementType( PnlCreEnums->IPC3CpnType_2,
								 "6 ks",
								 GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->IPC3CpnType_2 . ".png" );
	$IPC3Cpn->_AddPlacementType( PnlCreEnums->IPC3CpnType_3,
								 "3 ks",
								 GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->IPC3CpnType_3 . ".png" );
	$IPC3Cpn->_AddPlacementType( PnlCreEnums->IPC3CpnType_4,
								 "4 ks",
								 GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->IPC3CpnType_4 . ".png" );
	$IPC3Cpn->_AddPlacementType( PnlCreEnums->IPC3CpnType_5,
								 "4 ks",
								 GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->IPC3CpnType_5 . ".png" );

	my $ipc3CpnBaseName = EnumsGeneral->Coupon_IPC3MAIN;
	$IPC3Cpn->Hide() if ( scalar( grep { $_ =~ /$ipc3CpnBaseName/i } @steps ) == 0 );

	# ZAXIS coupon

	my $zAxisCpn = CpnSettFrm->new( $statBox, "Z-axis" );

	$zAxisCpn->_AddPlacementType( PnlCreEnums->ZAxisCpnType_1,
								  "3 sets",
								  GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ZAxisCpnType_1 . ".png" );
	$zAxisCpn->_AddPlacementType( PnlCreEnums->ZAxisCpnType_2,
								  "2 sets",
								  GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ZAxisCpnType_2 . ".png" );
	$zAxisCpn->_AddPlacementType( PnlCreEnums->ZAxisCpnType_3,
								  "2 sets",
								  GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ZAxisCpnType_3 . ".png" );
	$zAxisCpn->_AddPlacementType( PnlCreEnums->ZAxisCpnType_4,
								  "1 set",
								  GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ZAxisCpnType_4 . ".png" );
	$zAxisCpn->_AddPlacementType( PnlCreEnums->ZAxisCpnType_5,
								  "1 set",
								  GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ZAxisCpnType_5 . ".png" );
	$zAxisCpn->_AddPlacementType( PnlCreEnums->ZAxisCpnType_6,
								  "1 set",
								  GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . PnlCreEnums->ZAxisCpnType_6 . ".png" );

	my $zaxisCpnBaseName = EnumsGeneral->Coupon_ZAXIS;
	$zAxisCpn->Hide() if ( scalar( grep { $_ =~ /$zaxisCpnBaseName/i } @steps ) == 0 );

	# DEFINE EVENTS

	$impCpn->{"cpnSettingChangedEvt"}->Add( sub   { $self->{"creatorSettingsChangedEvt"}->Do() } );
	$IPC3Cpn->{"cpnSettingChangedEvt"}->Add( sub  { $self->{"creatorSettingsChangedEvt"}->Do() } );
	$zAxisCpn->{"cpnSettingChangedEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $impCpn,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $IPC3Cpn,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $zAxisCpn, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# save control references

	$self->{"impCpn"}   = $impCpn;
	$self->{"IPC3Cpn"}  = $IPC3Cpn;
	$self->{"zAxisCpn"} = $zAxisCpn;
	$self->{"layoutCpnBox"} = $statBox;

	return $szStatBox;
}

# Set layout for placement type
sub __SetLayoutPlacement {
	my $self = shift;

	my $parent = $self;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Placement type' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );
	my $szColLeft = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $rbPlacementAuto = Wx::RadioButton->new( $statBox, -1, "Automatic", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbPlacementManual = Wx::RadioButton->new( $statBox, -1, "Manual adjust", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $notebook = CustomNotebook->new( $statBox, -1 );
	my $placementAutoPage   = $notebook->AddPage( 1, 0 );
	my $placementManualPage = $notebook->AddPage( 2, 0 );

	my $szManual = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $pnlPicker = ManualPlacement->new( $placementManualPage->GetParent(),
										  $self->{"jobId"}, $self->GetStep(),
										  "Adjust coupons",
										  "Adjust coupon placement and press Continue.",
										  1, "Clear" );

	$szManual->Add( $pnlPicker, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$placementManualPage->AddContent($szManual);

	$notebook->ShowPage(1);

	# DEFINE EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementAuto,   -1, sub {$self->_EnableSettings(); $notebook->ShowPage(1); $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementManual, -1, sub {$self->_EnableSettings(); $notebook->ShowPage(2); $self->{"creatorSettingsChangedEvt"}->Do() } );

	$pnlPicker->{"placementEvt"}->Add( sub      { $self->{"manualPlacementEvt"}->Do(@_) } );
	$pnlPicker->{"clearPlacementEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	$szColLeft->Add( $rbPlacementAuto,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szColLeft->Add( $rbPlacementManual, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szColLeft,         1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $notebook,          1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( 1, 50, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );    # expander 40px heigh of panel picker

	# CONTROL REFERENCES
	$self->{"notebookPlacement"} = $notebook;
	$self->{"pnlPicker"}         = $pnlPicker;
	$self->{"rbPlacementAuto"}   = $rbPlacementAuto;
	$self->{"rbPlacementManual"} = $rbPlacementManual;

	return $szStatBox;
}


sub _EnableSettings {
	my $self = shift;

	if ( $self->{"rbPlacementAuto"}->GetValue() ) {

		$self->{"layoutCpnBox"}->Enable();
		 

	}
	elsif ( $self->{"rbPlacementManual"}->GetValue() ) {
		$self->{"layoutCpnBox"}->Disable();
		 
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Imp coupon

sub SetImpCpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"impCpnRequired"} = $val;

}

sub GetImpCpnRequired {
	my $self = shift;

	return $self->{"impCpnRequired"};
}

sub SetImpCpnSett {
	my $self = shift;
	my $sett = shift;

	return 0 unless ( defined $sett );

	$self->{"impCpn"}->SetSelectedCpntType( $sett->{"cpnPlacementType"} ) if ( defined $sett->{"cpnPlacementType"} );
	$self->{"impCpn"}->SetCpn2StepDist( $sett->{"cpn2StepDist"} )         if ( defined $sett->{"cpn2StepDist"} );

}

sub GetImpCpnSett {
	my $self = shift;

	return {} unless ( $self->GetImpCpnRequired() );

	my %sett = ();

	$sett{"cpnPlacementType"} = $self->{"impCpn"}->GetSelectedCpntType();
	$sett{"cpn2StepDist"}     = $self->{"impCpn"}->GetCpn2StepDist();

	return \%sett;
}

# IPC3 coupon

sub SetIPC3CpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"IPC3CpnRequired"} = $val;

}

sub GetIPC3CpnRequired {
	my $self = shift;

	return $self->{"IPC3CpnRequired"};
}

sub SetIPC3CpnSett {
	my $self = shift;
	my $sett = shift;

	return 0 unless ( defined $sett );

	$self->{"IPC3Cpn"}->SetSelectedCpntType( $sett->{"cpnPlacementType"} ) if ( defined $sett->{"cpnPlacementType"} );
	$self->{"IPC3Cpn"}->SetCpn2StepDist( $sett->{"cpn2StepDist"} )         if ( defined $sett->{"cpn2StepDist"} );
}

sub GetIPC3CpnSett {
	my $self = shift;

	return {} unless ( $self->GetIPC3CpnRequired() );

	my %sett = ();
	$sett{"cpnPlacementType"} = $self->{"IPC3Cpn"}->GetSelectedCpntType();
	$sett{"cpn2StepDist"}     = $self->{"IPC3Cpn"}->GetCpn2StepDist();

	return \%sett;
}

# zAxis coupon

sub SetZAxisCpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"zAxisCpnRequired"} = $val;

}

sub GetZAxisCpnRequired {
	my $self = shift;

	return $self->{"zAxisCpnRequired"};
}

sub SetZAxisCpnSett {
	my $self = shift;
	my $sett = shift;

	return 0 unless ( defined $sett );

	$self->{"zAxisCpn"}->SetSelectedCpntType( $sett->{"cpnPlacementType"} ) if ( defined $sett->{"cpnPlacementType"} );
	$self->{"zAxisCpn"}->SetCpn2StepDist( $sett->{"cpn2StepDist"} )         if ( defined $sett->{"cpn2StepDist"} );
}

sub GetZAxisCpnSett {
	my $self = shift;

	return {} unless ( $self->GetZAxisCpnRequired() );

	my %sett = ();
	$sett{"cpnPlacementType"} = $self->{"zAxisCpn"}->GetSelectedCpntType();
	$sett{"cpn2StepDist"}     = $self->{"zAxisCpn"}->GetCpn2StepDist();

	return \%sett;
}

# Panelisation

sub SetPlacementType {
	my $self = shift;
	my $val  = shift;

	if ( $val eq PnlCreEnums->CpnPlacementMode_AUTO ) {
		$self->{"rbPlacementAuto"}->SetValue(1);
		$self->{"notebookPlacement"}->ShowPage(1);
	}
	elsif ( $val eq PnlCreEnums->CpnPlacementMode_MANUAL ) {
		$self->{"rbPlacementManual"}->SetValue(1);
		$self->{"notebookPlacement"}->ShowPage(2);
	}
	else {

		die "Wrong action type: $val";
	}
	
	$self->_EnableSettings();

}

sub GetPlacementType {
	my $self = shift;

	my $val = undef;

	if ( $self->{"rbPlacementAuto"}->GetValue() ) {

		$val = PnlCreEnums->CpnPlacementMode_AUTO;
	}
	elsif ( $self->{"rbPlacementManual"}->GetValue() ) {
		$val = PnlCreEnums->CpnPlacementMode_MANUAL;
	}
	else {

		die "Wrong action type";
	}

	return $val;

}

sub SetManualPlacementJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlPicker"}->SetManualPlacementJSON($val);

}

sub GetManualPlacementJSON {
	my $self = shift;

	return $self->{"pnlPicker"}->GetManualPlacementJSON();

}

sub SetManualPlacementStatus {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlPicker"}->SetManualPlacementStatus($val);
}

sub GetManualPlacementStatus {
	my $self = shift;

	return $self->{"pnlPicker"}->GetManualPlacementStatus();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

