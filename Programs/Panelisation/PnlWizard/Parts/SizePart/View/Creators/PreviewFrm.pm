
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::PreviewFrm;
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
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->SizePnlCreator_PREVIEW, $parent, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

	# PROPERTIES
	$self->{"panelJSON"} = undef;

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	my $statBox = $self->__SetLayoutJobList();

	my $mainSz = $self->_GetMainSizer();

	$mainSz->Hide(1);    # Remove expander which is last item in sizer
	$mainSz->Prepend( $statBox, 50, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->_EnableLayoutSize(0);
	$self->_EnableLayoutBorder(0);

	# Disable all another controls

	# DEFINE EVENTS

	# Disable dimension + border textctrl events
	my $widthTxt  = $self->_GetPnlWidthControl();
	my $heightTxt = $self->_GetPnlHeightControl();
	my $borderL   = $self->_GetPnlBorderLControl();
	my $borderR   = $self->_GetPnlBorderRControl();
	my $borderT   = $self->_GetPnlBorderTControl();
	my $borderB   = $self->_GetPnlBorderBControl();

	Wx::Event::EVT_TEXT( $borderL,   -1, sub { } );
	Wx::Event::EVT_TEXT( $borderR,   -1, sub { } );
	Wx::Event::EVT_TEXT( $borderT,   -1, sub { } );
	Wx::Event::EVT_TEXT( $borderB,   -1, sub { } );
	Wx::Event::EVT_TEXT( $widthTxt,  -1, sub { } );    # empty handler - no raise setting changed evt
	Wx::Event::EVT_TEXT( $heightTxt, -1, sub { } );

	# BUILD STRUCTURE OF LAYOUT

	# SAVE REFERENCES
}

# Set layout for Quick set box
sub __SetLayoutJobList {
	my $self = shift;

	my $parent = $self;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Source jobs' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $jobSrcTxt = Wx::StaticText->new( $statBox, -1, "Source job:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $jobSrcValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $foundJobsTxt     = Wx::StaticText->new( $statBox, -1, "Found jobs by:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $jobSrcByOfferTxt = Wx::StaticText->new( $statBox, -1, "HEG PCB offer:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $jobSrcByOfferBox = Wx::ListBox->new( $statBox, -1, &Wx::wxDefaultPosition, [ 10, 23 ], [], &Wx::wxLB_SINGLE | &Wx::wxLB_NEEDED_SB );
	my $ISJobByOfferIndicator = ResultIndicator->new( $statBox, 20 );
	$ISJobByOfferIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	my $jobListByNoteTxt = Wx::StaticText->new( $statBox, -1, "HEG tpv note:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $jobListByNoteBox = Wx::ListBox->new( $statBox, -1, &Wx::wxDefaultPosition, [ 10, 23 ], [], &Wx::wxLB_SINGLE | &Wx::wxLB_NEEDED_SB );
	my $ISJobByNoteIndicator = ResultIndicator->new( $statBox, 20 );
	$ISJobByNoteIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	my $jobListByNameTxt = Wx::StaticText->new( $statBox, -1, "HEG pcb name:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $jobListByNameBox = Wx::ListBox->new( $statBox, -1, &Wx::wxDefaultPosition, [ 10, 23 ], [], &Wx::wxLB_SINGLE | &Wx::wxLB_NEEDED_SB );
	my $ISJobByNameIndicator = ResultIndicator->new( $statBox, 20 );
	$ISJobByNameIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $jobSrcValTxt, -1, sub { $self->__OnJobSrcChangedHndl() } );

	#Wx::Event::EVT_TEXT( $heightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_LISTBOX( $self, $jobSrcByOfferBox, sub { $self->__OnListBoxClick($jobSrcByOfferBox) } );
	Wx::Event::EVT_LISTBOX( $self, $jobListByNoteBox, sub { $self->__OnListBoxClick($jobListByNoteBox) } );
	Wx::Event::EVT_LISTBOX( $self, $jobListByNameBox, sub { $self->__OnListBoxClick($jobListByNameBox) } );

	Wx::Event::EVT_LISTBOX_DCLICK( $self, $jobSrcByOfferBox, sub { $self->__OnListBoxDClick($jobSrcByOfferBox) } );
	Wx::Event::EVT_LISTBOX_DCLICK( $self, $jobListByNameBox, sub { $self->__OnListBoxDClick($jobListByNameBox) } );
	Wx::Event::EVT_LISTBOX_DCLICK( $self, $jobListByNoteBox, sub { $self->__OnListBoxDClick($jobListByNoteBox) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow0->Add( $jobSrcTxt,    30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow0->Add( $jobSrcValTxt, 60, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow0->AddStretchSpacer(10);

	$szRow1->Add( $foundJobsTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $jobSrcByOfferTxt,      30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $jobSrcByOfferBox,      60, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $ISJobByOfferIndicator, 10, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow3->Add( $jobListByNoteTxt,     30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $jobListByNoteBox,     60, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $ISJobByNoteIndicator, 10, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow4->Add( $jobListByNameTxt,     30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow4->Add( $jobListByNameBox,     60, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow4->Add( $ISJobByNameIndicator, 10, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow0, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szStatBox->AddSpacer(5);
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow4, 1, &Wx::wxEXPAND );
	$szStatBox->AddSpacer(2);

	# save control references

	$self->{"jobSrcValTxt"} = $jobSrcValTxt;

	$self->{"jobSrcByOfferBox"}      = $jobSrcByOfferBox;
	$self->{"ISJobByOfferIndicator"} = $ISJobByOfferIndicator;

	$self->{"jobListByNoteBox"}     = $jobListByNoteBox;
	$self->{"ISJobByNoteIndicator"} = $ISJobByNoteIndicator;

	$self->{"jobListByNameBox"}     = $jobListByNameBox;
	$self->{"ISJobByNameIndicator"} = $ISJobByNameIndicator;

	return $szStatBox;
}

sub __OnListBoxClick {
	my $self    = shift;
	my $listBox = shift;

	if ( $listBox eq $self->{"jobListByNoteBox"} ) {
		$self->{"jobListByNameBox"}->SetSelection(-1);

	}
	elsif ( $listBox eq $self->{"jobListByNameBox"} ) {
		$self->{"jobListByNoteBox"}->SetSelection(-1);
	}

}

sub __OnListBoxDClick {
	my $self    = shift;
	my $listBox = shift;

	my $itemId = $listBox->GetSelection();

	my $inf = $listBox->GetClientData($itemId);

	$self->{"jobSrcValTxt"}->SetValue( $inf->{"jobId"} );

}

sub __OnJobSrcChangedHndl {
	my $self = shift;

	my $srcJob = $self->{"jobSrcValTxt"}->GetValue();

	if ( defined $srcJob && $srcJob =~ /^\w\d{6}$/i ) {

		$self->{"creatorInitRequestEvt"}->Do($srcJob);
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetSrcJobId {
	my $self = shift;
	my $val  = shift;

	$self->{"jobSrcValTxt"}->SetValue($val) if ( defined $val && $val ne "" );
}

sub GetSrcJobId {
	my $self = shift;

	return $self->{"jobSrcValTxt"}->GetValue();
}

sub SetSrcJobByOffer {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {

		$self->{"jobSrcByOfferBox"}->Freeze();

		$self->{"jobSrcByOfferBox"}->Clear();

		my $jobInfo = { "jobId" => $val };

		$self->{"jobSrcByOfferBox"}->Append( $val, $jobInfo );

		$self->{"jobSrcByOfferBox"}->Thaw();

		$self->{"ISJobByOfferIndicator"}->SetStatus( EnumsGeneral->ResultType_OK );
	}
	else {

		$self->{"ISJobByOfferIndicator"}->SetStatus( EnumsGeneral->ResultType_FAIL );
	}
}

sub GetSrcJobByOffer {
	my $self = shift;

	my @items = $self->{"jobSrcByOfferBox"}->GetStrings();

	return $items[0];
}

sub SetSrcJobListByNote {
	my $self = shift;
	my $list = shift;

	# List item
	#	jobId,
	#	jobName,
	#	nazev_subjektu,
	#	reference_subjektu

	$self->{"jobListByNoteBox"}->Freeze();

	$self->{"jobListByNoteBox"}->Clear();

	# Set cb classes
	foreach my $jobInfo ( @{$list} ) {

		my $txt = $jobInfo->{"jobId"} . " (" . $jobInfo->{"jobName"} . ")";

		$self->{"jobListByNoteBox"}->Append( $txt, $jobInfo );
	}

	$self->{"jobListByNoteBox"}->Thaw();

	if ( scalar( @{$list} ) ) {

		$self->{"ISJobByNoteIndicator"}->SetStatus( EnumsGeneral->ResultType_OK );
	}
	else {

		$self->{"ISJobByNoteIndicator"}->SetStatus( EnumsGeneral->ResultType_FAIL );
	}

}

sub GetSrcJobListByNote {
	my $self = shift;

	my @items = $self->{"jobListByNoteBox"}->GetStrings();
	my @list  = ();

	for ( my $i = 0 ; $i < scalar(@items) ; $i++ ) {

		my $d = $self->{"jobListByNoteBox"}->GetClientData($i);

		push( @list, $d );
	}

	return \@list;
}

sub SetSrcJobListByName {
	my $self = shift;
	my $list = shift;

	# List item
	#	jobId,
	#	jobName,
	#	nazev_subjektu,
	#	reference_subjektu

	$self->{"jobListByNameBox"}->Freeze();

	$self->{"jobListByNameBox"}->Clear();

	# Set cb classes
	foreach my $jobInfo ( @{$list} ) {

		my $txt = $jobInfo->{"jobId"} . " (" . $jobInfo->{"jobName"} . ")";

		$self->{"jobListByNameBox"}->Append( $txt, $jobInfo );
	}

	$self->{"jobListByNameBox"}->Thaw();

	if ( scalar( @{$list} ) ) {

		$self->{"ISJobByNameIndicator"}->SetStatus( EnumsGeneral->ResultType_OK );
	}
	else {

		$self->{"ISJobByNameIndicator"}->SetStatus( EnumsGeneral->ResultType_FAIL );
	}

}

sub GetSrcJobListByName {
	my $self = shift;

	my $items = $self->{"jobListByNameBox"}->GetStrings();
	my @list  = ();

	for ( my $i = 0 ; $i < scalar($items) ; $i++ ) {

		my $d = $self->{"jobListByNameBox"}->GetClientData($i);

		push( @list, $d );
	}

	return \@list;
}

sub SetPanelJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"panelJSON"} = $val;

}

sub GetPanelJSON {
	my $self = shift;

	return $self->{"panelJSON"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

