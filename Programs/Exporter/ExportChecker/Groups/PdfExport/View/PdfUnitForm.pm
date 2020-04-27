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

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $control   = $self->__SetLayoutControl($self);
	my $stackup   = $self->__SetLayoutStackup($self);
	my $pressfit  = $self->__SetLayoutPressfit($self);
	my $ncSpecial = $self->__SetLayoutNCSpecial($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $control, 0, &Wx::wxEXPAND );

	#$szMain->Add( 2, 2, 0, &Wx::wxEXPAND );
	$szMain->Add( $stackup, 0, &Wx::wxEXPAND );

	#$szMain->Add( 2, 2, 0, &Wx::wxEXPAND );
	$szMain->Add( $pressfit, 0, &Wx::wxEXPAND );

	#$szMain->Add( 2, 2, 0, &Wx::wxEXPAND );
	$szMain->Add( $ncSpecial, 0, &Wx::wxEXPAND );

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

	my $stepTxt     = Wx::StaticText->new( $statBox, -1, "Step",          &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $langTxt     = Wx::StaticText->new( $statBox, -1, "Language",      &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $inclNestedTxt = Wx::StaticText->new( $statBox, -1, "Incl nested steps", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $operatorTxt = Wx::StaticText->new( $statBox, -1, "Operator info", &Wx::wxDefaultPosition, [ 120, 20 ] );

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
	Wx::Event::EVT_COMBOBOX( $stepCb,    -1, sub { $self->__OnControlStepChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowDetail1->Add( $exportControlChb, 0, &Wx::wxALL, 0 );

	$szRowDetail2->Add( $stepTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail2->Add( $stepCb,  0, &Wx::wxALL, 0 );

	$szRowDetail3->Add( $langTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail3->Add( $langCb,  0, &Wx::wxALL, 0 );

	$szRowDetail4->Add( $inclNestedTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail4->Add( $inclNestedChb, 0, &Wx::wxALL, 0 );
	
	$szRowDetail5->Add( $operatorTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail5->Add( $operatorChb,  0, &Wx::wxALL, 0 );
	

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
sub __SetLayoutStackup {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Production stackup' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	my $exportStackupChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );


	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportStackupChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportStackupChb"} = $exportStackupChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutPressfit {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Tolerance measurement' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	my $exportPressfitChb   = Wx::CheckBox->new( $statBox, -1, "Pressfit (Plt)",   &Wx::wxDefaultPosition );
	my $exportTolMeasureChb = Wx::CheckBox->new( $statBox, -1, "Tolerance (NPlt)", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportPressfitChb,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $exportTolMeasureChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportPressfitChb"}   = $exportPressfitChb;
	$self->{"exportTolMeasureChb"} = $exportTolMeasureChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutNCSpecial {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'NC countersink' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	my $exportNCChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportNCChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportNCSpecialChb"} = $exportNCChb;

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

	if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepCb"}->GetValue() ) ) {

		$self->{"inclNestedChb"}->Enable();
	}
	else {
		$self->{"inclNestedChb"}->Disable();
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

1;
