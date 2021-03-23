
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::ClassUserFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->SizePnlCreator_CLASSUSER, $parent, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}


# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;
 
 	 

	# DEFINE CONTROLS
	
 
 
	# DEFINE EVENTS
 
	# BUILD STRUCTURE OF LAYOUT
 
	# SAVE REFERENCES
	
 	$self->_SetLayoutCBMain("Class", )

	 

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

 

sub SetPnlClasses {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pnlClasses"} = $val;
}

sub GetPnlClasses {
	my $self = shift;

	return $self->{"settings"}->{"pnlClasses"};
}

sub SetDefPnlClass {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlClass"} = $val;
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"settings"}->{"defPnlClass"};
}

sub SetDefPnlSize {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlSize"} = $val;
}

sub GetDefPnlSize {
	my $self = shift;

	return $self->{"settings"}->{"defPnlSize"};
}

sub SetDefPnlBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlBorder"} = $val;
}

sub GetDefPnlBorder {
	my $self = shift;

	return $self->{"settings"}->{"defPnlBorder"};
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

