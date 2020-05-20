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

	$self->{"saveExitEvt"} = Event->new();

	# Comment list events
	$self->{"onSelCommChangedEvt"} = Event->new();

	return $self;
}

sub RefreshCommListViewForm {
	my $self   = shift;
	my $layout = shift;

	my @commLayoputs = $layout->GetAllComments();

	$self->{"commListViewFrm"}->SetCommList( \@commLayoputs );

	$self->{"commListViewFrm"}->SetCommSelected( scalar(@commLayoputs) - 1 );

}

sub RefreshCommViewForm {
	my $self   = shift;
	my $commId = shift;
	my $layout = shift;

	$self->{"commViewFrm"}->SetCommLayout( $commId, $layout );

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
	my $btnCancel   = $self->AddButton( "Cancel",      sub { $self->{"saveExitEvt"}->Do( 0, 1 ) } );
	my $btnSave     = $self->AddButton( "Save",        sub { $self->{"saveExitEvt"}->Do( 1, 0 ) } );
	my $btnSaveExit = $self->AddButton( "Save & exit", sub { $self->{"saveExitEvt"}->Do( 1, 1 ) } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

}

sub __SetLayoutCommView {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Comment edit' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $viewFrm = CommViewFrm->new($statBox);

	$szStatBox->Add( $viewFrm, 1, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"commViewFrm"} = $viewFrm;

	return $szStatBox;
}

sub __SetLayoutCommListView {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Comment list' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	 

	my $viewFrm = CommListViewFrm->new($statBox);

	$szStatBox->Add( $viewFrm, 1, &Wx::wxEXPAND );
	 

	# SET EVENTS
	$viewFrm->{"onSelCommChangedEvt"}->Add( sub { $self->__OnCommSelChangedHndl(@_) } );

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

