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
#use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';

use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"}    = $inCAM;
	$self->{"jobId"}    = $jobId;
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
	my $control = $self->__SetLayoutControl($self);
	my $stackup = $self->__SetLayoutStackup($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $control, 0, &Wx::wxEXPAND );
	$szMain->Add( 15, 15, 0, &Wx::wxEXPAND );
	$szMain->Add( $stackup, 0, &Wx::wxEXPAND );

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

	#my $szRowDetail4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $exportControlChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	my $stepTxt = Wx::StaticText->new( $statBox, -1, "Step", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $langTxt = Wx::StaticText->new( $statBox, -1, "Language", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $operatorTxt = Wx::StaticText->new( $statBox, -1, "Operator info", &Wx::wxDefaultPosition, [ 120, 22 ] );

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb = Wx::ComboBox->new( $statBox, -1, $last, &Wx::wxDefaultPosition, [ 70, 22 ], \@steps, &Wx::wxCB_READONLY );

	my @lang   = ( "English", "Czech" );
	my $last2  = $lang[ scalar(@lang) - 1 ];
	my $langCb = Wx::ComboBox->new( $statBox, -1, $last2, &Wx::wxDefaultPosition, [ 70, 22 ], \@lang, &Wx::wxCB_READONLY );
	
	my $operatorChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $exportControlChb, -1, sub { $self->__OnExportControlChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowDetail1->Add( $exportControlChb, 0, &Wx::wxALL, 0 );

	$szRowDetail2->Add( $stepTxt, 0, &Wx::wxALL, 1 );
	$szRowDetail2->Add( $stepCb,  0, &Wx::wxALL, 1 );

	$szRowDetail3->Add( $langTxt, 0, &Wx::wxALL, 1 );
	$szRowDetail3->Add( $langCb,  0, &Wx::wxALL, 1 );
	
	$szRowDetail4->Add( $operatorTxt, 0, &Wx::wxALL, 1 );
	$szRowDetail4->Add( $operatorChb,  0, &Wx::wxALL, 1 );

	$szStatBox->Add( $szRowDetail1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( 8,             8, 0,                          &Wx::wxEXPAND );
	$szStatBox->Add( $szRowDetail2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRowDetail3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRowDetail4, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportControlChb"} = $exportControlChb;
	$self->{"stepCb"}           = $stepCb;
	$self->{"langCb"}           = $langCb;
	$self->{"operatorChb"}           = $operatorChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutStackup {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Stackup' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	my $exportStackupChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );
	if ( $self->{"layerCnt"} <= 2 ) {

		$exportStackupChb->Disable();
	}

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportStackupChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportStackupChb"} = $exportStackupChb;

	return $szStatBox;
}

sub __OnExportControlChange {
	my $self = shift;

	if ( $self->{"exportControlChb"}->IsChecked() ) {

		$self->{"stepCb"}->Enable();
		$self->{"langCb"}->Enable();

	}
	else {

		$self->{"stepCb"}->Disable();
		$self->{"langCb"}->Disable();
	}

}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls{
	
	
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

sub GetControlLang {
	my $self = shift;

	return $self->{"langCb"}->GetValue();
}

# Info about tpv technik to pdf

sub GetInfoToPdf {
	my $self  = shift;
	
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

1;
