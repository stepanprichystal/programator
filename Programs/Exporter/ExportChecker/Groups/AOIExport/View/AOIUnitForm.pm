#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::AOIExport::View::AOIUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:richtextctrl :textctrl :font);

BEGIN {
	eval { require Wx::RichText; };
}

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';

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

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	# Load data

	my @layers = CamJob->GetSignalLayerNames( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"layers"} = \@layers;

	$self->__SetLayout();

	#$self->__SetName();

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	# EVENTS
	#$self->{'onTentingChange'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $settings = $self->__SetLayoutSettings($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $settings, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $stepTxt   = Wx::StaticText->new( $parent, -1, "Test step",   &Wx::wxDefaultPosition, [ 50, 25 ] );
	my $layersTxt = Wx::StaticText->new( $parent, -1, "Layers", &Wx::wxDefaultPosition, [ 50, 25 ] );

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb = Wx::ComboBox->new( $parent, -1, $last, &Wx::wxDefaultPosition, [ 50, 25 ], \@steps, &Wx::wxCB_READONLY );
	my $layersChlb = Wx::CheckListBox->new( $parent, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize, $self->{"layers"} );

	my $sendToServerTxt    = Wx::StaticText->new( $parent, -1, "Send to server",       &Wx::wxDefaultPosition, [ 50, 25 ] );
	my $incldMpanelFrmTxt = Wx::StaticText->new( $parent, -1, "Test mpanel frm", &Wx::wxDefaultPosition, [ 50, 25 ] );
	my $sendToServerChb    = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );
	my $incldMpanelFrmChb = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	# SET EVENTS
	Wx::Event::EVT_COMBOBOX( $stepCb, -1, sub { $self->__ChangeStep(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $sendToServerTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $stepTxt,            0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $incldMpanelFrmTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $layersTxt,          1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	

	$szCol2->Add( $sendToServerChb,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol2->Add( $stepCb,             0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol2->Add( $incldMpanelFrmChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol2->Add( $layersChlb,         1, &Wx::wxEXPAND | &Wx::wxALL, 1 );


	$szStatBox->Add( $szCol1, 40, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szCol2, 60, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"stepCb"}             = $stepCb;
	$self->{"layersChlb"}         = $layersChlb;
	$self->{"sendToServerChb"}    = $sendToServerChb;
	$self->{"incldMpanelFrmChb"} = $incldMpanelFrmChb;
	$self->{"incldMpanelFrmTxt"} = $incldMpanelFrmTxt;
	

	return $szStatBox;
}

sub __GetCheckedLayers {
	my $self = shift;
	my $type = shift;

	my @arr = ();

	for ( my $i = 0 ; $i < scalar( @{ $self->{"layers"} } ) ; $i++ ) {

		if ( $self->{"layersChlb"}->IsChecked($i) ) {
			my $l = ${ $self->{"layers"} }[$i];
			push( @arr, $l );
		}
	}

	return @arr;
}

sub __SetCheckedLayers {
	my $self      = shift;
	my $tmplayers = shift;
	my @layers    = ();

	if ($tmplayers) {
		@layers = @{$tmplayers};
	}
	else {
		return 0;
	}

	my @arr = ();

	for ( my $i = 0 ; $i < scalar( @{ $self->{"layers"} } ) ; $i++ ) {

		my $l = ${ $self->{"layers"} }[$i];

		my @layers = grep { $_ eq $l } @layers;

		if ( scalar(@layers) ) {
			$self->{"layersChlb"}->Check( $i, 1 );

		}
		else {

			$self->{"layersChlb"}->Check( $i, 0 );
		}
	}
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	$self->__ChangeStep();

}

# =====================================================================
# HANDLERS - HANDLE EVENTS ANOTHER GROUPS
# =====================================================================

sub __ChangeStep {
	my $self = shift;

	my $step = $self->{"stepCb"}->GetValue();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if (
		 CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step )
		 && ( $step eq "mpanel"
			  || grep { $_->{"stepName"} =~ /^mpanel\d*/ } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) )
	  )
	{
		$self->{"incldMpanelFrmTxt"}->Enable();
		$self->{"incldMpanelFrmChb"}->Enable();
	}
	else {
		$self->{"incldMpanelFrmTxt"}->Disable();
		$self->{"incldMpanelFrmChb"}->Disable();
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Dimension ========================================================

sub SetStepToTest {
	my $self  = shift;
	my $value = shift;

	$self->{"stepCb"}->SetValue($value);
}

sub GetStepToTest {
	my $self = shift;
	return $self->{"stepCb"}->GetValue();
}

sub SetLayers {
	my $self   = shift;
	my $layers = shift;

	$self->__SetCheckedLayers($layers);
}

sub GetLayers {
	my $self = shift;

	my @arr = $self->__GetCheckedLayers();

	return \@arr;
}

sub SetSendToServer {
	my $self  = shift;
	my $value = shift;

	$self->{"sendToServerChb"}->SetValue($value);
}

sub GetSendToServer {
	my $self = shift;

	if ( $self->{"sendToServerChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Include panel frame to testing
sub SetIncldMpanelFrm {
	my $self  = shift;
	my $value = shift;

	$self->{"incldMpanelFrmChb"}->SetValue($value);
}

sub GetIncldMpanelFrm {
	my $self = shift;

	if ( $self->{"incldMpanelFrmChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

1;
