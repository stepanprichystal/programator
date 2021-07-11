
#-------------------------------------------------------------------------------------------#
# Description: Helper form. Represent form for one specific coupon
# Support adding coupon placement types + custome controls
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::CpnPart::View::Creators::Frm::CpnSettFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use List::Util qw(first);

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $parent   = shift;
	my $cpnTitle = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# PROPERTIES
	$self->{"cpnTypeRadioBtns"} = [];    # all radiobuttons of all cpn placement types (rb contain key with type value)

 
	
	# DEFINE EVENTS
	 
	$self->{"cpnSettingChangedEvt"} = Event->new();
	
	$self->__SetLayout($cpnTitle);

	return $self;
}

sub __SetLayout {
	my $self     = shift;
	my $cpnTitle = shift;

	my $szMain           = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szPlacementTypes = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szPlacementSett = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szCustomControls = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	
	my $szPlacementSettCol = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Add empty item

	# DEFINE CONTROLS
	my $cpnTitleTxt = Wx::StaticText->new( $self, -1, $cpnTitle, &Wx::wxDefaultPosition );
	
	my $cpn2stepDistTxt = Wx::StaticText->new( $self, -1, "Cpn to steps dist.:", &Wx::wxDefaultPosition );
	my $cpn2stepDistValTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition );
 
	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $cpn2stepDistValTxt, -1, sub { $self->{"cpnSettingChangedEvt"}->Do() } );
	 

	# BUILD STRUCTURE OF LAYOUT
	
	
	$szPlacementSettCol->Add( $cpn2stepDistTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szPlacementSettCol->Add( $cpn2stepDistValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	$szPlacementSett->Add( $szPlacementSettCol, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	 
	$szMain->Add( $cpnTitleTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szPlacementTypes, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szPlacementSett, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szCustomControls, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"szPlacementTypes"} = $szPlacementTypes;
	$self->{"szCustomControls"} = $szCustomControls;
	$self->{"cpn2stepDistValTxt"} = $cpn2stepDistValTxt;
	

}

# =====================================================================
# PROTECTED METHOD
# =====================================================================
sub _AddPlacementType {
	my $self    = shift;
	my $type    = shift;
	my $title   = shift;
	my $imgPath = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szType = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $cpnTitle = Wx::StaticText->new( $self, -1, $title, &Wx::wxDefaultPosition );
	my $rb = Wx::RadioButton->new( $self, -1, "", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$rb->{"cpnPlacementType"} = $type;

	my $iconStatBtmp = undef;

	if ( defined $imgPath && $imgPath ne "" ) {

		Wx::InitAllImageHandlers();

		my $iconBtmp = Wx::Bitmap->new( $imgPath, &Wx::wxBITMAP_TYPE_PNG );
		$iconStatBtmp = Wx::StaticBitmap->new( $self, -1, $iconBtmp );
	}

	# BUILD STRUCTURE OF LAYOUT
	$szType->Add( $cpnTitle,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szType->Add( $iconStatBtmp, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 ) if ( defined $iconStatBtmp );
	$szMain->Add( $rb,           0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szType,       0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->{"szPlacementTypes"}->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# DEFINE EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rb, -1, sub { $self->{"cpnSettingChangedEvt"}->Do() } );
	 


	push( @{ $self->{"cpnTypeRadioBtns"} }, $rb );

}

sub _AddCustomControls {
	my $self    = shift;
	my $control = shift;

	$self->{"szCustomControls"}->Add( $control, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

}

sub _GetCustomControlParent {
	my $self = shift;

	return $self;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub GetSelectedCpntType {
	my $self = shift;

	my $rb = first { $_->GetValue() == 1 } @{ $self->{"cpnTypeRadioBtns"} };

	die "No cpn type selected" unless ( defined $rb );

	return $rb->{"cpnPlacementType"};
}

sub SetSelectedCpntType {
	my $self = shift;
	my $type = shift;

	my $rb = first { $_->{"cpnPlacementType"} eq $type } @{ $self->{"cpnTypeRadioBtns"} };

	die "No radiop button contain cpn placement type: $type" unless ( defined $rb );

	return $rb->SetValue(1);
}

sub GetCpn2StepDist {
	my $self = shift;

 
	return $self->{"cpn2stepDistValTxt"}->GetValue();
}

sub SetCpn2StepDist {
	my $self = shift;
	my $dist = shift;

	 $self->{"cpn2stepDistValTxt"}->SetValue($dist);
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

