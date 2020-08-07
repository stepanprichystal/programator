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
	my $flags =
	  &Wx::wxSTAY_ON_TOP | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX | &Wx::wxRESIZE_BORDER;

	my $self = $class->SUPER::new( $parent, "TPV comments builder - $jobId", \@dimension, $flags );

	bless($self);

	# Properties

	$self->__SetLayout();

	# EVENTS
	$self->{'onRemoveFileEvt'} = Event->new();
	$self->{'onEditFileEvt'}   = Event->new();
	$self->{'onAddFileEvt'}    = Event->new();
	$self->{"saveExitEvt"}     = Event->new();

	# Comment list events
	$self->{"onSelCommChangedEvt"} = Event->new();
	$self->{'onRemoveCommEvt'}     = Event->new();
	$self->{'onMoveCommEvt'}       = Event->new();
	$self->{'onAddCommEvt'}        = Event->new();

	return $self;
}

sub RefreshCommListViewForm {
	my $self   = shift;
	my $layout = shift;

	$self->{"mainFrm"}->Freeze();

	my @commLayoputs = $layout->GetAllComments();

	$self->{"commListViewFrm"}->SetCommList( \@commLayoputs );

	$self->{"commListViewFrm"}->SetCommSelected( scalar(@commLayoputs) - 1 );

	$self->{"mainFrm"}->Thaw();

}

sub RefreshCommViewForm {
	my $self   = shift;
	my $commId = shift;
	my $layout = shift;

	$self->{"mainFrm"}->Freeze();

	$self->{"commViewFrm"}->SetCommLayout( $commId, $layout );

	$self->{"mainFrm"}->Thaw();
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

	$szMain->Add( $commView, 80, &Wx::wxEXPAND );
	$szMain->Add( 5, 5, 0, &Wx::wxEXPAND );
	$szMain->Add( $commListView, 20, &Wx::wxEXPAND );

	$self->AddContent($szMain);
	$self->SetButtonHeight(30);
	my $btnCancel = $self->AddButton( "Cancel", sub { $self->{"saveExitEvt"}->Do( 0, 1 ) } );
	my $btnSave   = $self->AddButton( "Save",   sub { $self->{"saveExitEvt"}->Do( 1, 0 ) } );
	my $btnSaveExport = $self->AddButton( 'Save + Export', sub { $self->{"saveExportEvt"}->Do() } );
	my $btnSaveExit = $self->AddButton( "Save + Exit", sub { $self->{"saveExitEvt"}->Do( 1, 1 ) } );

	$btnSaveExit

	  # DEFINE LAYOUT STRUCTURE

	  # KEEP REFERENCES

}

sub __SetLayoutCommView {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $szStatBox = MyWxStaticBoxSizer->new( $parent, &Wx::wxVERTICAL, 'Comment detail',
											 5, $Widgets::Style::fontLblBold,
											 Wx::Colour->new( 255, 255, 255 ),
											 Wx::Colour->new( 112, 146, 190 ),
											 Wx::Colour->new( 240, 240, 240 ), 3 );

	my $viewFrm = CommViewFrm->new($szStatBox);

	# EVENTS

	$viewFrm->{'onRemoveFileEvt'}->Add( sub { $self->{"onRemoveFileEvt"}->Do(@_) } );
	$viewFrm->{'onEditFileEvt'}->Add( sub   { $self->{"onEditFileEvt"}->Do(@_) } );
	$viewFrm->{'onAddFileEvt'}->Add( sub    { $self->{"onAddFileEvt"}->Do(@_) } );

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
											 Wx::Colour->new( 230, 230, 230 ), 3 );

	my $viewFrm = CommListViewFrm->new($szStatBox);

	$szStatBox->Add( $viewFrm, 1, &Wx::wxEXPAND );

	# SET EVENTS
	$viewFrm->{"onSelCommChangedEvt"}->Add( sub { $self->__OnCommSelChangedHndl(@_) } );
	$viewFrm->{"onRemoveCommEvt"}->Add( sub     { $self->__OnRemoveCommdHndl(@_) } );

 
	  # SAVE REFERENCES
	  $self->{"commListViewFrm"} = $viewFrm;

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#
sub __OnCommSelChangedHndl {
	my $self = shift;

	$self->{"onSelCommChangedEvt"}->Do(@_);

	#$self->{"mainFrm"}->Layout();
	#$self->{"mainFrm"}->Refresh();

	#$self->{"mainFrm"}->Layout();
	#	$self->{"mainFrm"}->Refresh();
	#	$self->{"mainFrm"}->Update();

	$self->{"mainFrm"}->Refresh();    # some background colors not work correctly without refersh

}
sub __OnRemoveCommdHndl {
	my $self = shift;

	$self->{"onRemoveCommEvt"}->Do(@_);

	$self->{"mainFrm"}->Refresh();
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

