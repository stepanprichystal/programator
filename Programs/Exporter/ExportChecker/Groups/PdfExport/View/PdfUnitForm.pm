#-------------------------------------------------------------------------------------------#
# Description: GUI form for pdf group
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PdfExport::View::PdfUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';

#use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::CAMJob::Drilling::CountersinkCheck';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"}       = $inCAM;
	$self->{"jobId"}       = $jobId;
	$self->{"defaultInfo"} = $defaultInfo;

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	# Load data
	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain       = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szMainWraper = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $control   = $self->__SetLayoutControl($self);
	my $travelers = $self->__SetLayoutTravelers($self);
	my $drawings  = $self->__SetLayoutDrawings($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $control,      0, &Wx::wxEXPAND );
	$szMain->Add( $szMainWraper, 0, &Wx::wxEXPAND );

	$szMainWraper->Add( $travelers, 1, &Wx::wxEXPAND );
	$szMainWraper->Add( $drawings,  1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutControl {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Control data' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	#my $szRowMain1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRowDetail4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $exportControlChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	my $stepTxt       = Wx::StaticText->new( $statBox, -1, "Step",              &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $langTxt       = Wx::StaticText->new( $statBox, -1, "Language",          &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $inclNestedTxt = Wx::StaticText->new( $statBox, -1, "Incl nested steps", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $operatorTxt   = Wx::StaticText->new( $statBox, -1, "Operator info",     &Wx::wxDefaultPosition, [ 120, 20 ] );

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb = Wx::ComboBox->new( $statBox, -1, $last, &Wx::wxDefaultPosition, [ 70, 20 ], \@steps, &Wx::wxCB_READONLY );

	my @lang   = ( "English", "Czech" );
	my $last2  = $lang[ scalar(@lang) - 1 ];
	my $langCb = Wx::ComboBox->new( $statBox, -1, $last2, &Wx::wxDefaultPosition, [ 70, 20 ], \@lang, &Wx::wxCB_READONLY );

	my $operatorChb   = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition );
	my $inclNestedChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $exportControlChb, -1, sub { $self->__OnExportControlChange(@_) } );
	Wx::Event::EVT_COMBOBOX( $stepCb, -1, sub { $self->__OnControlStepChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowDetail1->Add( $exportControlChb, 0, &Wx::wxALL, 0 );

	$szRowDetail2->Add( $stepTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail2->Add( $stepCb,  0, &Wx::wxALL, 0 );

	$szRowDetail3->Add( $langTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail3->Add( $langCb,  0, &Wx::wxALL, 0 );

	$szRowDetail4->Add( $inclNestedTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail4->Add( $inclNestedChb, 0, &Wx::wxALL, 0 );

	$szRowDetail5->Add( $operatorTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail5->Add( $operatorChb, 0, &Wx::wxALL, 0 );

	$szStatBox->Add( $szRowDetail1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szStatBox->Add( 0,             0, 0,                          &Wx::wxEXPAND );
	$szStatBox->Add( $szRowDetail2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRowDetail3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRowDetail4, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRowDetail5, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportControlChb"} = $exportControlChb;
	$self->{"stepCb"}           = $stepCb;
	$self->{"langCb"}           = $langCb;
	$self->{"operatorChb"}      = $operatorChb;
	$self->{"inclNestedChb"}    = $inclNestedChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutTravelers {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Production travelers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $exportStackupChb = Wx::CheckBox->new( $statBox, -1, "Stackup", &Wx::wxDefaultPosition );

	my $pcbType = $self->{"defaultInfo"}->GetPcbType();

	# 1) Choose stackup manager

	if (    $pcbType eq EnumsGeneral->PcbType_1V
		 || $pcbType eq EnumsGeneral->PcbType_2V
		 || $pcbType eq EnumsGeneral->PcbType_NOCOPPER )
	{

		$exportStackupChb->Disable();
	}

	my $exportPeelStencChb = Wx::CheckBox->new( $statBox, -1, "Peelable stenc.", &Wx::wxDefaultPosition );
	my $exportCvrlStencChb = Wx::CheckBox->new( $statBox, -1, "Coverlay stenc.", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportStackupChb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportPeelStencChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportCvrlStencChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportStackupChb"}   = $exportStackupChb;
	$self->{"exportPeelStencChb"} = $exportPeelStencChb;
	$self->{"exportCvrlStencChb"} = $exportCvrlStencChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutDrawings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Production drawings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $exportPressfitChb   = Wx::CheckBox->new( $statBox, -1, "Pressfit (Plt)",    &Wx::wxDefaultPosition );
	my $exportTolMeasureChb = Wx::CheckBox->new( $statBox, -1, "Tolerance (NPlt)",  &Wx::wxDefaultPosition );
	my $exportNCChb         = Wx::CheckBox->new( $statBox, -1, "NC countersing",    &Wx::wxDefaultPosition );
	my $exportDrillIPC3Chb  = Wx::CheckBox->new( $statBox, -1, "Cust. IPC3 cpn", &Wx::wxDefaultPosition );
	my $exportCustIPC3Chb   = Wx::CheckBox->new( $statBox, -1, "Drill. IPC3 cpn", &Wx::wxDefaultPosition );
	my $exportPCBThickChb = Wx::CheckBox->new( $statBox, -1, "PCB thickness.",  &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportPressfitChb,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportTolMeasureChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportNCChb,         1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportDrillIPC3Chb,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportCustIPC3Chb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportPCBThickChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportPressfitChb"}   = $exportPressfitChb;
	$self->{"exportTolMeasureChb"} = $exportTolMeasureChb;
	$self->{"exportNCSpecialChb"}  = $exportNCChb;
	$self->{"exportDrillIPC3Chb"}  = $exportDrillIPC3Chb;
	$self->{"exportCustIPC3Chb"}   = $exportCustIPC3Chb;
	$self->{"exportPCBThickChb"} = $exportPCBThickChb;

	return $szStatBox;
}

sub __OnExportControlChange {
	my $self = shift;

	if ( $self->{"exportControlChb"}->IsChecked() ) {

		$self->{"stepCb"}->Enable();
		$self->{"langCb"}->Enable();
		$self->{"operatorChb"}->Enable();

	}
	else {

		$self->{"stepCb"}->Disable();
		$self->{"langCb"}->Disable();
		$self->{"operatorChb"}->Disable();
	}

}

sub __OnControlStepChange {
	my $self = shift;

	my $inclNested = 0;

	if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepCb"}->GetValue() ) ) {

		$self->{"inclNestedChb"}->Enable();

		if ( scalar( CamStepRepeat->GetRepeatStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepCb"}->GetValue() ) ) > 1 ) {
			$inclNested = 1;
		}
	}
	else {

		$self->{"inclNestedChb"}->Disable();
	}

	$self->{"inclNestedChb"}->SetValue($inclNested);

}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	unless ( $self->{"defaultInfo"}->GetPressfitExist() ) {

		$self->{"exportPressfitChb"}->SetValue(0);
		$self->{"exportPressfitChb"}->Disable();

	}
	else {

		$self->{"exportPressfitChb"}->Enable();
	}

	unless ( $self->{"defaultInfo"}->GetToleranceHoleExist() ) {

		$self->{"exportTolMeasureChb"}->SetValue(0);
		$self->{"exportTolMeasureChb"}->Disable();

	}
	else {

		$self->{"exportTolMeasureChb"}->Enable();
	}

	if ( CountersinkCheck->ExistCountersink( $self->{"inCAM"}, $self->{"jobId"} ) ) {

		$self->{"exportNCSpecialChb"}->Enable();

	}
	else {

		$self->{"exportNCSpecialChb"}->Disable();
	}
	my $baseInf = $self->{"defaultInfo"}->GetPcbBaseInfo();
	if ( defined $baseInf->{"ipc_class_3"} && $baseInf->{"ipc_class_3"} ne "" ) {

		$self->{"exportDrillIPC3Chb"}->Enable();
		$self->{"exportCustIPC3Chb"}->Enable();
	}
	else {
		$self->{"exportDrillIPC3Chb"}->Disable();
		$self->{"exportCustIPC3Chb"}->Disable();
	}

	if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepCb"}->GetValue() ) ) {

		$self->{"inclNestedChb"}->Enable();
	}
	else {
		$self->{"inclNestedChb"}->Disable();
	}

	my @NCCvrllayers =
	  grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_soldcMill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_soldsMill }
	  $self->{"defaultInfo"}->GetNCLayers();

	if ( scalar(@NCCvrllayers) ) {

		$self->{"exportCvrlStencChb"}->Enable();
	}
	else {

		$self->{"exportCvrlStencChb"}->Disable();
	}

	my @NCSoldlayers =
	  grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_lcMill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_lsMill }
	  $self->{"defaultInfo"}->GetNCLayers();

	if ( scalar(@NCSoldlayers) ) {

		$self->{"exportPeelStencChb"}->Enable();
	}
	else {

		$self->{"exportPeelStencChb"}->Disable();
	}

	my @NCStiff =
	  grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
	  } $self->{"defaultInfo"}->GetNCLayers();

	if ( scalar(@NCStiff) ) {

		$self->{"exportPCBThickChb"}->Enable();
	}
	else {

		$self->{"exportPCBThickChb"}->Disable();
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetExportControl {
	my $self = shift;
	my $val  = shift;

	$self->{"exportControlChb"}->SetValue($val);

}

sub GetExportControl {
	my $self = shift;

	if ( $self->{"exportControlChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetControlStep {
	my $self = shift;
	my $val  = shift;

	$self->{"stepCb"}->SetValue($val);
	$self->__OnControlStepChange();
}

sub GetControlStep {
	my $self = shift;

	return $self->{"stepCb"}->GetValue();
}

sub SetControlLang {
	my $self = shift;
	my $val  = shift;

	$self->{"langCb"}->SetValue($val);
}

sub GetControlInclNested {
	my $self = shift;

	if ( $self->{"inclNestedChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetControlInclNested {
	my $self  = shift;
	my $value = shift;
	$self->{"inclNestedChb"}->SetValue($value);
}

sub GetControlLang {
	my $self = shift;

	return $self->{"langCb"}->GetValue();
}

# Info about tpv technik to pdf

sub GetInfoToPdf {
	my $self = shift;

	if ( $self->{"operatorChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetInfoToPdf {
	my $self  = shift;
	my $value = shift;
	$self->{"operatorChb"}->SetValue($value);
}

sub SetExportStackup {
	my $self = shift;
	my $val  = shift;

	$self->{"exportStackupChb"}->SetValue($val);
}

sub GetExportStackup {
	my $self = shift;

	if ( $self->{"exportStackupChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportPressfit {
	my $self = shift;
	my $val  = shift;

	$self->{"exportPressfitChb"}->SetValue($val);
}

sub GetExportPressfit {
	my $self = shift;

	if ( $self->{"exportPressfitChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportToleranceHole {
	my $self = shift;
	my $val  = shift;

	$self->{"exportTolMeasureChb"}->SetValue($val);
}

sub GetExportToleranceHole {
	my $self = shift;

	if ( $self->{"exportTolMeasureChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportNCSpecial {
	my $self = shift;
	my $val  = shift;

	$self->{"exportNCSpecialChb"}->SetValue($val);
}

sub GetExportNCSpecial {
	my $self = shift;

	if ( $self->{"exportNCSpecialChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportCustCpnIPC3Map {
	my $self = shift;
	my $val  = shift;

	$self->{"exportCustIPC3Chb"}->SetValue($val);
}

sub GetExportCustCpnIPC3Map {
	my $self = shift;

	if ( $self->{"exportCustIPC3Chb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportDrillCpnIPC3Map {
	my $self = shift;
	my $val  = shift;

	$self->{"exportDrillIPC3Chb"}->SetValue($val);
}

sub GetExportDrillCpnIPC3Map {
	my $self = shift;

	if ( $self->{"exportDrillIPC3Chb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportPCBThick {
	my $self = shift;
	my $val  = shift;

	$self->{"exportPCBThickChb"}->SetValue($val);
}

sub GetExportPCBThick {
	my $self = shift;

	if ( $self->{"exportPCBThickChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportPeelStencil {
	my $self = shift;
	my $val  = shift;

	$self->{"exportPeelStencChb"}->SetValue($val);
}

sub GetExportPeelStencil {
	my $self = shift;

	if ( $self->{"exportPeelStencChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

sub SetExportCvrlStencil {
	my $self = shift;
	my $val  = shift;

	$self->{"exportCvrlStencChb"}->SetValue($val);
}

sub GetExportCvrlStencil {
	my $self = shift;

	if ( $self->{"exportCvrlStencChb"}->IsChecked() ) {

		return 1;
	}
	else {
		return 0;
	}
}

1;
