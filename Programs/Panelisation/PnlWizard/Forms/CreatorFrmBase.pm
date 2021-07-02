
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $creatorKey = shift;
	my $parent     = shift;
	my $inCAM      = shift;
	my $jobId      = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	#$self->__SetLayout();

	$self->{"creatorKey"} = $creatorKey;
	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
	$self->{"step"}       = undef;

	# DEFINE EVENTS

	$self->{"creatorSettingsChangedEvt"} = Event->new( $self->{"creatorKey"} );
	$self->{"creatorInitRequestEvt"}     = Event->new( $self->{"creatorKey"} );

	return $self;
}

sub GetCreatorKey {
	my $self = shift;

	return $self->{"creatorKey"};
}

sub __SetLayout {
	my $self = shift;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetStep {
	my $self = shift;
	my $val  = shift;

	$self->{"step"} = $val;

}

sub GetStep {
	my $self = shift;

	return $self->{"step"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

