
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
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

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

	# DEFINE EVENTS

	$self->__SetLayout($cpnTitle);

	return $self;
}

sub __SetLayout {
	my $self     = shift;
	my $cpnTitle = shift;

	my $szMain           = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szPlacementTypes = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szCustomControls = Wx::BoxSizer->new(&Wx::wxVERTICALL);

	# Add empty item

	# DEFINE CONTROLS
	my $cpnTitle = Wx::StaticText->new( $statBox, -1, $cpnTitle, &Wx::wxDefaultPosition );

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $cpnTitle, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szPlacementTypes, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szCustomControls, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"szPlacementTypes"} = $szPlacementTypes;
	$self->{"szCustomControls"} = $szCustomControls;

}

# =====================================================================
# PROTECTED METHOD
# =====================================================================
sub _AddPlacementType {
	my $self    = shift;
	my $type    = shift;
	my $title   = shift;
	my $imgPath = shift;


	my $szType = Wx::BoxSizer->new(&Wx::wxVERTICALL);

	my $cpnTitle = Wx::StaticText->new( $statBox, -1, $cpnTitle, &Wx::wxDefaultPosition );
	my $rb = Wx::RadioButton->new( $statBox, -1, "Defined", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $iconStatBtmp = undef;
	if(defined $imgPath && $imgPath ne ""){
		 
	Wx::InitAllImageHandlers();
 
		my $iconBtmp     = Wx::Bitmap->new( $iconPath, &Wx::wxBITMAP_TYPE_PNG );
		$iconStatBtmp = Wx::StaticBitmap->new( $self, -1, $iconBtmp );
	}
	
	
	
	
	$self->{"szPlacementTypes"} = $szPlacementTypes;
}

sub _AddCustomControls {
	my $self = shift;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================


sub GetCpntType{
	
	
	
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

