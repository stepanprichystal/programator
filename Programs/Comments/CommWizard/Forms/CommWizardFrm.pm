#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommWizardFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party library
use strict;
use warnings;
use Wx;

#local library
use aliased 'Packages::Tests::Test';
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Packages::Events::Event';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListViewFrm';
use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::CommViewFrm';
use Widgets::Style;
use aliased 'Widgets::Forms::MyWxStaticBoxSizer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my $jobId  = shift;
	my $orders = shift;

	my @dimension = ( 1000, 800 );
	my $flags = &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX | &Wx::wxRESIZE_BORDER;

	my $self = $class->SUPER::new( $parent, "TPV comments builder - $jobId", \@dimension, $flags );

	bless($self);

	# Properties

	$self->__SetLayout();

	# EVENTS

	# Comment detail events

	$self->{'onChangeTypeEvt'} = Event->new();
	$self->{'onChangeNoteEvt'} = Event->new();

	# Comment detail files evt
	$self->{'onAddFileEvt'}        = Event->new();
	$self->{'onRemoveFileEvt'}     = Event->new();
	$self->{'onEditFileEvt'}       = Event->new();
	$self->{'onChangeFileNameEvt'} = Event->new();

	# Comment detail suggestions evt
	$self->{'onAddSuggesEvt'}    = Event->new();
	$self->{'onRemoveSuggesEvt'} = Event->new();
	$self->{'onChangeSuggesEvt'} = Event->new();

	# Comment list events
	$self->{"onSelCommChangedEvt"} = Event->new();
	$self->{'onRemoveCommEvt'}     = Event->new();
	$self->{'onMoveCommEvt'}       = Event->new();
	$self->{'onAddCommEvt'}        = Event->new();

	$self->{"saveExitEvt"}     = Event->new();
	$self->{"emailPreviewEvt"} = Event->new();
	$self->{"clearAllEvt"}     = Event->new();
	$self->{"restoreEvt"}      = Event->new();

	return $self;
}

sub RefreshCommListViewForm {
	my $self   = shift;
	my $layout = shift;

	$self->{"mainFrm"}->Freeze();

	my @commLayoputs = $layout->GetAllComments();

	$self->{"commListViewFrm"}->SetCommList( \@commLayoputs );

	if ( scalar(@commLayoputs) ) {
		$self->{"commListViewFrm"}->SetCommSelected( scalar(@commLayoputs) - 1 );
	}

	# Set detail view
	if ( scalar(@commLayoputs) ) {

		$self->{"commViewFrm"}->Show();
	}
	else {

		$self->{"commViewFrm"}->Hide();
	}

	# Set buttons
	if ( scalar(@commLayoputs) ) {

		$self->{"btnClear"}->Enable();
		$self->{"btnPreview"}->Enable();
		$self->{"btnRestore"}->Disable();
	}
	else {

		$self->{"btnClear"}->Disable();
		$self->{"btnPreview"}->Disable();
		$self->{"btnRestore"}->Enable();
	}

	$self->{"mainFrm"}->Thaw();

}

sub RefreshCommListItem {
	my $self   = shift;
	my $commId = shift;
	my $layout = shift;

	#$self->{"mainFrm"}->Freeze();

	$self->{"commListViewFrm"}->SetComm( $commId, $layout );

	#$self->{"mainFrm"}->Thaw();
}

sub RefreshCommViewForm {
	my $self   = shift;
	my $commId = shift;
	my $layout = shift;

	$self->{"mainFrm"}->Freeze();

	if ( $commId > -1 ) {

		$self->{"commViewFrm"}->SetCommLayout( $commId, $layout );
		$self->{"commViewFrm"}->Show();
	}
	else {

		$self->{"commViewFrm"}->Hide();
	}

	$self->{"mainFrm"}->Thaw();
}

sub RefreshSelected {
	my $self   = shift;
	my $commId = shift;

	if ( defined $commId ) {

		$self->{"commListViewFrm"}->SetCommSelected($commId);
	}
}

sub GetSelectedComment {
	my $self = shift;

	return $self->{"commListViewFrm"}->GetSelectedComm();
}

sub GetMessMngr {
	my $self = shift;

	return $self->_GetMessageMngr();
}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $commView     = $self->__SetLayoutCommView( $self->{"mainFrm"} );
	my $commListView = $self->__SetLayoutCommListView( $self->{"mainFrm"} );

	$szMain->Add( $commView, 75, &Wx::wxEXPAND );
	$szMain->Add( 5, 5, 0, &Wx::wxEXPAND );
	$szMain->Add( $commListView, 25, &Wx::wxEXPAND );

	$self->AddContent($szMain);
	$self->SetButtonHeight(30);
	my $btnPreview    = $self->AddButton( "Mail preview",  sub { $self->{"emailPreviewEvt"}->Do() } );
	my $btnClear      = $self->AddButton( "Clear all",     sub { $self->{"clearAllEvt"}->Do() } );
	my $btnRestore    = $self->AddButton( "Restore last",  sub { $self->{"restoreEvt"}->Do() } );
	my $btnSave       = $self->AddButton( "Save",          sub { $self->{"saveExitEvt"}->Do( 1, 0, 0 ) } );
	my $btnSaveExport = $self->AddButton( 'Save + Export', sub { $self->{"saveExitEvt"}->Do(1, 0, 1) } );
	my $btnSaveExit   = $self->AddButton( "Save + Exit",   sub { $self->{"saveExitEvt"}->Do( 1, 1, 0 ) } );

	$btnClear->Disable();
	$btnPreview->Disable();

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES
	$self->{"btnClear"}   = $btnClear;
	$self->{"btnRestore"} = $btnRestore;
	$self->{"btnPreview"} = $btnPreview;

}

sub __SetLayoutCommView {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $szStatBox = MyWxStaticBoxSizer->new( $parent, &Wx::wxVERTICAL, 'Comment detail',
											 5, $Widgets::Style::fontLblBold,
											 Wx::Colour->new( 255, 255, 255 ),
											 Wx::Colour->new( 112, 146, 190 ),
											 Wx::Colour->new( 240, 240, 240 ), 4 );

	my $viewFrm = CommViewFrm->new($szStatBox);

	# EVENTS

	$viewFrm->{"onChangeTypeEvt"}->Add( sub { $self->__OnChangeTypedHndl(@_) } );
	$viewFrm->{"onChangeNoteEvt"}->Add( sub { $self->__OnChangeNotedHndl(@_) } );

	$viewFrm->{'onAddFileEvt'}->Add( sub        { $self->{"onAddFileEvt"}->Do(@_) } );
	$viewFrm->{'onChangeFileNameEvt'}->Add( sub { $self->{"onChangeFileNameEvt"}->Do(@_) } );
	$viewFrm->{'onRemoveFileEvt'}->Add( sub     { $self->{"onRemoveFileEvt"}->Do(@_) } );
	$viewFrm->{'onEditFileEvt'}->Add( sub       { $self->{"onEditFileEvt"}->Do(@_) } );

	$viewFrm->{'onAddSuggesEvt'}->Add( sub    { $self->{"onAddSuggesEvt"}->Do(@_) } );
	$viewFrm->{'onRemoveSuggesEvt'}->Add( sub { $self->{"onRemoveSuggesEvt"}->Do(@_) } );
	$viewFrm->{'onChangeSuggesEvt'}->Add( sub { $self->{"onChangeSuggesEvt"}->Do(@_) } );

	$szStatBox->Add( $viewFrm, 1, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"commViewFrm"} = $viewFrm;

	return $szStatBox;
}

sub __SetLayoutCommListView {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $szStatBox = MyWxStaticBoxSizer->new( $parent, &Wx::wxVERTICAL, 'Comment list', 5, $Widgets::Style::fontLblBold,
											 Wx::Colour->new( 255, 255, 255 ),
											 Wx::Colour->new( 112, 146, 190 ),
											 Wx::Colour->new( 230, 230, 230 ), 4 );

	my $viewFrm = CommListViewFrm->new($szStatBox);

	$szStatBox->Add( $viewFrm, 1, &Wx::wxEXPAND );

	# SET EVENTS
	$viewFrm->{"onSelCommChangedEvt"}->Add( sub { $self->__OnCommSelChangedHndl(@_) } );
	$viewFrm->{"onRemoveCommEvt"}->Add( sub     { $self->__OnRemoveCommdHndl(@_) } );
	$viewFrm->{"onAddCommEvt"}->Add( sub        { $self->__OnAddCommdHndl(@_) } );
	$viewFrm->{"onMoveCommEvt"}->Add( sub       { $self->__OnMoveCommdHndl(@_) } );

	# SAVE REFERENCES
	$self->{"commListViewFrm"} = $viewFrm;

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#
sub __OnCommSelChangedHndl {
	my $self = shift;

	$self->{"selectionChanged"} = 1;

	$self->{"onSelCommChangedEvt"}->Do(@_);

	#$self->{"mainFrm"}->Layout();
	#$self->{"mainFrm"}->Refresh();

	#$self->{"mainFrm"}->Layout();
	#	$self->{"mainFrm"}->Refresh();
	#	$self->{"mainFrm"}->Update();

	$self->{"mainFrm"}->Refresh();    # some background colors not work correctly without refersh

	$self->{"selectionChanged"} = 0;

}

sub __OnRemoveCommdHndl {
	my $self = shift;

	$self->{"onRemoveCommEvt"}->Do(@_);

	$self->{"mainFrm"}->Refresh();
}

sub __OnAddCommdHndl {
	my $self = shift;

	$self->{"onAddCommEvt"}->Do(@_);

	$self->{"mainFrm"}->Refresh();
}

sub __OnMoveCommdHndl {
	my $self = shift;

	$self->{"onMoveCommEvt"}->Do(@_);

	#$self->{"mainFrm"}->Refresh();
}

sub __OnChangeTypedHndl {
	my $self = shift;

	return 0 if ( $self->{"selectionChanged"} );    # Do not reise event if onlz selection changed

	$self->{"onChangeTypeEvt"}->Do(@_);

	#$self->{"mainFrm"}->Refresh();
}

sub __OnChangeNotedHndl {
	my $self = shift;

	return 0 if ( $self->{"selectionChanged"} );    # Do not reise event if onlz selection changed

	$self->{"onChangeNoteEvt"}->Do(@_);

	#$self->RefreshCommListItem
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

