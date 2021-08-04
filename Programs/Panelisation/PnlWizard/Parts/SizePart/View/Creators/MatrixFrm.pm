
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::MatrixFrm;
use base qw(Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::Frm::PnlSizeBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->SizePnlCreator_MATRIX, $parent, $jobId );

	bless($self);

	$self->__SetLayout();

	# PROPERTIES

	$self->{"activeAreaW"} = 0;
	$self->{"activeAreaH"} = 0;

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	# Init combobox class size
	$self->{"pnlQuickBorderCB"} = $self->_SetLayoutCBBorder( "Predefined:", [ "0mm", "5mm", "7mm", "10mm" ], 24, 76,0 );

	$self->{"CBBorderChangedEvt"}->Add( sub { $self->__OnQuickBorderChanged(@_) } );

	# DEFINE EVENTS
	# Catch events of border text controls
	my $widthTxt  = $self->_GetPnlWidthControl();
	my $heightTxt = $self->_GetPnlHeightControl();

	my $borderL = $self->_GetPnlBorderLControl();
	my $borderR = $self->_GetPnlBorderRControl();
	my $borderT = $self->_GetPnlBorderTControl();
	my $borderB = $self->_GetPnlBorderBControl();

	Wx::Event::EVT_TEXT( $borderL,   -1, sub { $self->__OnBorderChangedHndl(@_) } );
	Wx::Event::EVT_TEXT( $borderR,   -1, sub { $self->__OnBorderChangedHndl(@_) } );
	Wx::Event::EVT_TEXT( $borderT,   -1, sub { $self->__OnBorderChangedHndl(@_) } );
	Wx::Event::EVT_TEXT( $borderB,   -1, sub { $self->__OnBorderChangedHndl(@_) } );
	Wx::Event::EVT_TEXT( $widthTxt,  -1, sub { } );                                    # empty handler - no raise setting changed evt
	Wx::Event::EVT_TEXT( $heightTxt, -1, sub { } );                                    # empty handler - no raise setting changed evt

	# BUILD STRUCTURE OF LAYOUT
	# SAVE REFERENCES

	$self->_EnableLayoutSize(1);

}

sub __OnQuickBorderChanged {
	my $self = shift;
	my $val  = shift;

	my $border = ( $val =~ m/(\d+)/ )[0];

	if ( defined $border ) {

		# Change dimension
		
		$self->SetBorderLeft($border);
		$self->SetBorderRight($border);
		$self->SetBorderTop($border);
		$self->SetBorderBot($border);

	}
}

sub __OnBorderChangedHndl {
	my $self = shift;

	$self->ActiveAreaChanged();

	# Raise setting changed EVT
	$self->{"creatorSettingsChangedEvt"}->Do()

}


sub UpdateActiveArea {
	my $self = shift;

	my $areaW = shift;
	my $areaH = shift;

	$self->{"activeAreaW"} = $areaW;
	$self->{"activeAreaH"} = $areaH;

}

sub ActiveAreaChanged {
	my $self = shift;

	my $areaW = $self->{"activeAreaW"};
	my $areaH = $self->{"activeAreaH"};

	if ( defined $areaW && defined $self->GetBorderLeft() && defined $self->GetBorderRight() ) {

		$self->SetWidth( $areaW + $self->GetBorderLeft() + $self->GetBorderRight() );
	}
	if ( defined $areaH && defined $self->GetBorderTop() && defined $self->GetBorderBot() ) {

		$self->SetHeight( $areaH + $self->GetBorderTop() + $self->GetBorderBot() );
	}

}


# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
#sub SetActiveAreaW {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"activeAreaW"} = $val;
#
#	$self->__ActiveAreaChanged();
#}
#
#sub GetActiveAreaW {
#	my $self = shift;
#
#	return $self->{"activeAreaW"};
#}
#
#sub SetActiveAreaH {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"activeAreaH"} = $val;
#
#	$self->__ActiveAreaChanged();
#}
#
#sub GetActiveAreaH {
#	my $self = shift;
#
#	return $self->{"activeAreaH"};
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

