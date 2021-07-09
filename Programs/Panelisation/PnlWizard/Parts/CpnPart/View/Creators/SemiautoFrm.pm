
#-------------------------------------------------------------------------------------------#
# Description: View form for specific creator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::CpnPart::View::Creators::SemiAutoFrm;
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->CpnPnlCreator_SEMIAUTO, $parent, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

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
	$szMain->Add( $placementStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

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

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $jobSrcTxt = Wx::StaticText->new( $statBox, -1, "Source job:", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $jobSrcValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ -1, 25 ] );

	my $jobListByNoteTxt = Wx::StaticText->new( $statBox, -1, "Jobs by TPV note", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $jobListByNoteBox = Wx::ListBox->new( $statBox, -1, [ -1, -1 ], [ -1, 25 ], [], &Wx::wxLB_SINGLE | &Wx::wxLB_NEEDED_SB );
	my $ISJobByNoteIndicator = ResultIndicator->new( $statBox, 20 );
	$ISJobByNoteIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	my $jobListByNameTxt = Wx::StaticText->new( $statBox, -1, "Jobs by similar name", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $jobListByNameBox = Wx::ListBox->new( $statBox, -1, [ -1, -1 ], [ -1, -1 ], [], &Wx::wxLB_SINGLE | &Wx::wxLB_NEEDED_SB );
	my $ISJobByNameIndicator = ResultIndicator->new( $statBox, 20 );
	$ISJobByNameIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $jobSrcValTxt, -1, sub { $self->__OnJobSrcChangedHndl() } );

	#Wx::Event::EVT_TEXT( $heightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_LISTBOX( $self, $jobListByNoteBox, sub { $self->__OnListBoxClick($jobListByNoteBox) } );
	Wx::Event::EVT_LISTBOX( $self, $jobListByNameBox, sub { $self->__OnListBoxClick($jobListByNameBox) } );

	Wx::Event::EVT_LISTBOX_DCLICK( $self, $jobListByNoteBox, sub { $self->__OnListBoxDClick($jobListByNoteBox) } );
	Wx::Event::EVT_LISTBOX_DCLICK( $self, $jobListByNameBox, sub { $self->__OnListBoxDClick($jobListByNameBox) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $jobSrcTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $jobSrcValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $jobListByNoteTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $jobListByNoteBox,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $ISJobByNoteIndicator, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow3->Add( $jobListByNameTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $jobListByNameBox,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $ISJobByNameIndicator, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND );

	# save control references

	$self->{"jobSrcValTxt"}         = $jobSrcValTxt;
	$self->{"jobListByNoteBox"}     = $jobListByNoteBox;
	$self->{"ISJobByNoteIndicator"} = $ISJobByNoteIndicator;
	$self->{"jobListByNameBox"}     = $jobListByNameBox;
	$self->{"ISJobByNameIndicator"} = $ISJobByNameIndicator;

	return $szStatBox;
}

# Set layout for placement type
sub __SetLayoutPlacement {
	my $self = shift;

	my $parent = $self;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Placement type' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $jobSrcTxt = Wx::StaticText->new( $statBox, -1, "Source job:", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $jobSrcValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ -1, 25 ] );

	my $jobListByNoteTxt = Wx::StaticText->new( $statBox, -1, "Jobs by TPV note", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $jobListByNoteBox = Wx::ListBox->new( $statBox, -1, [ -1, -1 ], [ -1, 25 ], [], &Wx::wxLB_SINGLE | &Wx::wxLB_NEEDED_SB );
	my $ISJobByNoteIndicator = ResultIndicator->new( $statBox, 20 );
	$ISJobByNoteIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	my $jobListByNameTxt = Wx::StaticText->new( $statBox, -1, "Jobs by similar name", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $jobListByNameBox = Wx::ListBox->new( $statBox, -1, [ -1, -1 ], [ -1, -1 ], [], &Wx::wxLB_SINGLE | &Wx::wxLB_NEEDED_SB );
	my $ISJobByNameIndicator = ResultIndicator->new( $statBox, 20 );
	$ISJobByNameIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $jobSrcValTxt, -1, sub { $self->__OnJobSrcChangedHndl() } );

	#Wx::Event::EVT_TEXT( $heightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_LISTBOX( $self, $jobListByNoteBox, sub { $self->__OnListBoxClick($jobListByNoteBox) } );
	Wx::Event::EVT_LISTBOX( $self, $jobListByNameBox, sub { $self->__OnListBoxClick($jobListByNameBox) } );

	Wx::Event::EVT_LISTBOX_DCLICK( $self, $jobListByNoteBox, sub { $self->__OnListBoxDClick($jobListByNoteBox) } );
	Wx::Event::EVT_LISTBOX_DCLICK( $self, $jobListByNameBox, sub { $self->__OnListBoxDClick($jobListByNameBox) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $jobSrcTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $jobSrcValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $jobListByNoteTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $jobListByNoteBox,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $ISJobByNoteIndicator, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow3->Add( $jobListByNameTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $jobListByNameBox,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $ISJobByNameIndicator, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND );

	# save control references

	$self->{"jobSrcValTxt"}         = $jobSrcValTxt;
	$self->{"jobListByNoteBox"}     = $jobListByNoteBox;
	$self->{"ISJobByNoteIndicator"} = $ISJobByNoteIndicator;
	$self->{"jobListByNameBox"}     = $jobListByNameBox;
	$self->{"ISJobByNameIndicator"} = $ISJobByNameIndicator;

	return $szStatBox;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetPnlClasses {
	my $self    = shift;
	my $classes = shift;

	$self->{"classes"} = $classes;

	$self->{"pnlClassCB"}->Clear();

	# Set cb classes
	foreach my $class ( @{$classes} ) {

		$self->{"pnlClassCB"}->Append( $class->GetName() );
	}

}

sub GetPnlClasses {
	my $self = shift;

	return $self->{"classes"};
}

sub SetDefPnlClass {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassCB"}->SetValue($val) if ( defined $val );

	$self->__OnPnlClassChanged($val) if ( defined $val );
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"pnlClassCB"}->GetValue();
}

sub SetDefPnlSize {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassSizeCB"}->SetValue($val) if ( defined $val );

	$self->__OnPnlClassSizeChanged($val) if ( defined $val );
}

sub GetDefPnlSize {
	my $self = shift;

	return $self->{"pnlClassSizeCB"}->GetValue();
}

sub SetDefPnlBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassBorderCB"}->SetValue($val) if ( defined $val );

	$self->__OnPnlClassBorderChanged($val) if ( defined $val );
}

sub GetDefPnlBorder {
	my $self = shift;

	return $self->{"pnlClassBorderCB"}->GetValue();
}

sub SetISDimensionFilled {
	my $self = shift;
	my $val  = shift;

	$self->{"ISDimensionFilled"}->SetStatus( ( $val ? EnumsGeneral->ResultType_OK : EnumsGeneral->ResultType_FAIL ) );

}

sub GetISDimensionFilled {
	my $self = shift;

	my $stat = $self->{"ISDimensionFilled"}->GetStatus();

	if ( $stat eq EnumsGeneral->ResultType_OK ) {

		return 1;
	}
	else {

		return 0;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

