
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::CommWizard;

use Class::Interface;
&implements('Packages::InCAMHelpers::AppLauncher::IAppLauncher');

#3th party library
use utf8;
use strict;
use warnings;
use threads;
use threads::shared;

#use strict;

#local library
use aliased 'Programs::Comments::CommWizard::Forms::CommWizardFrm';
use aliased 'Programs::Comments::Comments';
use aliased 'Programs::Comments::Enums' => 'CommEnums';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"serverPort"} = shift;

	$self->{"inCAM"} = undef;

	# Launcher, helper, which do connection to InCAm editor
	$self->{"launcher"} = undef;

	# Main application form
	$self->{"form"} = CommWizardFrm->new( -1, $self->{"jobId"} );

	# Manage group date (store/load group data from/to disc)
	$self->{"comments"} = undef;

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;    # contain InCAM library conencted to server

	# 1) Get InCAm from Launcher

	$self->{"launcher"} = $launcher;
	$self->{"inCAM"}    = $launcher->GetInCAM();

	$self->{"comments"} = Comments->new( $self->{"inCAM"}, $self->{"jobId"} );

	# Refresh before set handlers in order do not raise events
	$self->__RefreshForm();

	#set handlers for main app form
	$self->__SetHandlers();

}

sub Run {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Show(1);

	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __SaveExitHndl {
	my $self   = shift;
	my $save   = shift;
	my $exit   = shift;
	my $export = shift;

	if ($save) {

		my $messMngr   = $self->{"form"}->GetMessMngr();
		my $commLayout = $self->{"comments"}->GetLayout();

		# Do error check

		my @errMess = ();

		if ( $self->{"comments"}->CheckBeforeSave( \@errMess ) ) {
			$self->{"form"}->RefreshCommListViewForm($commLayout);

		}
		else {

			$messMngr->ShowModal( -1,
								  EnumsGeneral->MessageType_ERROR,
								  [ "Chyba při ukládání komentářů.", "Detail chyby:\n" . join( "\n", map { "- " . $_ } @errMess ) ],
								  ["Repair"] );

			return 0;
		}

		# Do warning check
		my @warnMess = ();

		# If comment is typ of question
		my @commSngls = $commLayout->GetAllComments();

		for ( my $i = 0 ; $i < scalar(@commSngls) ; $i++ ) {

			my $commSngl = $commSngls[$i];

			if ( $commSngl->GetType() eq CommEnums->CommentType_QUESTION && scalar( $commSngl->GetAllSuggestions() ) < 1 ) {

				push( @warnMess, "Komentář číslo: " . ( $i + 1 ) . " i" . " je otázka, ale nejsou navrženy žádné odpovědi. Je to ok?" );
			}
		}

		if ( scalar(@warnMess) ) {

			$messMngr->ShowModal( -1,
								  EnumsGeneral->MessageType_WARNING,
								  [ "Varování při ukládání komentářů.", "Detail varování:\n" . join( "\n", map { "- " . $_ } @warnMess ) ],
								  [ "Repair",                                    "Continue" ] );

			if ( $messMngr->Result() == 0 ) {

				return 0;
			}
		}

		$self->{"comments"}->Save();
		$self->{"form"}->RefreshCommListViewForm( $self->{"comments"}->GetLayout() );
	}

	if ($exit) {

		$self->{"form"}->{"mainFrm"}->Close();
	}

}

sub __OnSelCommChangedHndl {
	my $self   = shift;
	my $commId = shift;

	my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

	$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );

}

sub __OnRemoveCommdHndl {
	my $self   = shift;
	my $commId = shift;

	$self->{"comments"}->RemoveComment($commId);

	my $commLayout = $self->{"comments"}->GetLayout();

	# Refresh list
	$self->{"form"}->RefreshCommListViewForm($commLayout);

	my $commCnt = scalar( $commLayout->GetAllComments() );

	# Refresh view
	my $commSnglLayout = undef;
	if ( $commCnt > 0 ) {

		$commSnglLayout = $commLayout->GetCommentById( $commCnt - 1 );
	}

	$self->{"form"}->RefreshCommViewForm( $commCnt - 1, $commSnglLayout );

}

sub __OnAddCommdHndl {
	my $self   = shift;
	my $commId = shift;

	$self->{"comments"}->AddComment( CommEnums->CommentType_QUESTION );

	my $commLayout = $self->{"comments"}->GetLayout();

	# Refresh list
	$self->{"form"}->RefreshCommListViewForm($commLayout);

	my $commCnt = scalar( $commLayout->GetAllComments() );

	# Refresh view
	my $commSnglLayout = undef;
	if ( $commCnt > 0 ) {

		$commSnglLayout = $commLayout->GetCommentById( $commCnt - 1 );
	}

	$self->{"form"}->RefreshCommViewForm( $commCnt - 1, $commSnglLayout );

}

sub __OnMoveCommdHndl {
	my $self   = shift;
	my $commId = shift;
	my $type   = shift;

	if ( $self->{"comments"}->MoveComment( $commId, $type ) ) {

		my $commLayout = $self->{"comments"}->GetLayout();

		# Refresh list
		$self->{"form"}->RefreshCommListViewForm($commLayout);

		my $newPos = $type eq "up" ? $commId - 1 : $commId + 1;
		my $commSnglLayout = $commLayout->GetCommentById($newPos);

		$self->{"form"}->RefreshSelected($newPos);

		#$self->{"form"}->RefreshCommViewForm( $newPos, $commSnglLayout );
	}

}

sub __OnChangeTypeHndl {
	my $self   = shift;
	my $commId = shift;
	my $type   = shift;

	$self->{"comments"}->ChangeType( $commId, $type );

	my $commLayout = $self->{"comments"}->GetLayout();

	my $commSnglLayout = $commLayout->GetCommentById($commId);

	$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );
	$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );

}

sub __OnChangeNoteHndl {
	my $self   = shift;
	my $commId = shift;
	my $note   = shift;

	$self->{"comments"}->SetText( $commId, $note );

	my $commLayout = $self->{"comments"}->GetLayout();

	my $commSnglLayout = $commLayout->GetCommentById($commId);

	$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );

}

sub __OnRemoveFileHndl {
	my $self   = shift;
	my $commId = shift;
	my $fileId = shift;

	$self->{"comments"}->RemoveFile( $commId, $fileId );
	my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

	$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );
	$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );
}

sub __OnEditFileHndl {
	my $self   = shift;
	my $commId = shift;
	my $fileId = shift;

	if ( $self->{"comments"}->EditFile( $commId, $fileId ) ) {

		my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

		$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );

		$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );
	}
	else {

		my $messMngr = $self->{"form"}->GetMessMngr();
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during edit image in GreenShot"] );    #  Script is stopped
	}

}

sub __OnAddFileHndl {
	my $self   = shift;
	my $commId = shift;
	my $addCAM = shift;
	my $addGS  = shift;

	$self->{"form"}->HideFrm();

	my $p = "";
	my $res;
	if ($addCAM) {

		$res = $self->{"comments"}->SnapshotCAM( 0, \$p );
	}
	elsif ($addGS) {
		$res = $self->{"comments"}->SnapshotGS( \$p );
	}

	$self->{"form"}->ShowFrm();

	if ($res) {

		$self->{"comments"}->AddFile( $commId, undef, $p );

		# Refresh Comm view
		my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);
		$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );

		# Refresh Comm list
		$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );
	}
	else {

		my $messMngr = $self->{"form"}->GetMessMngr();
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during create snapshot"] );    #  Script is stopped
	}

}

sub __OnChangeFileNameHndl {
	my $self     = shift;
	my $commId   = shift;
	my $fileId   = shift;
	my $fileName = shift;

	$self->{"comments"}->SetFileName( $commId, $fileId, $fileName );

	my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);
	$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );

}

sub __OnAddSuggesHndl {
	my $self   = shift;
	my $commId = shift;

	$self->{"comments"}->AddSuggestion( $commId, "" );
	my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

	$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );
	$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );
}

sub __OnChangeSuggesHndl {
	my $self   = shift;
	my $commId = shift;
	my $suggId = shift;
	my $text   = shift;

	$self->{"comments"}->SetSuggestion( $commId, $suggId, $text );
	my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);
	$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );

}

sub __OnRemoveSuggesHndl {
	my $self   = shift;
	my $commId = shift;
	my $suggId = shift;

	$self->{"comments"}->RemoveSuggestion( $commId, $suggId );
	my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

	$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );
	$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );
}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __RefreshForm {
	my $self = shift;

	my $comments = $self->{"comments"}->GetLayout();

	if ( scalar( $comments->GetAllComments() ) ) {

		$self->{"form"}->RefreshCommListViewForm( $self->{"comments"}->GetLayout() );

		my $commId     = scalar( $comments->GetAllComments() ) - 1;
		my $commLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

		$self->{"form"}->RefreshCommViewForm( $commId, $commLayout );

		# Final refresh by select comm
		#$self->{"form"}->RefreshSelected($commId);
	}
	else {

		$self->{"form"}->RefreshCommViewForm(-1);
	}

	# Hack - refresh form after start in order show images in Notebook control
	my $timerFiles = Wx::Timer->new( $self->{"form"}->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"form"}->{"mainFrm"}, $timerFiles, sub { $self->{"form"}->{"mainFrm"}->Refresh(); $timerFiles->Stop() } );
	$timerFiles->Start(200);

}

sub __CheckFilesHandler {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Refresh();

}

sub __SetHandlers {
	my $self = shift;

	$self->{"form"}->{"saveExitEvt"}->Add( sub { $self->__SaveExitHndl(@_) } );

	$self->{"form"}->{"onSelCommChangedEvt"}->Add( sub { $self->__OnSelCommChangedHndl(@_) } );
	$self->{"form"}->{"onRemoveCommEvt"}->Add( sub     { $self->__OnRemoveCommdHndl(@_) } );
	$self->{"form"}->{"onAddCommEvt"}->Add( sub        { $self->__OnAddCommdHndl(@_) } );
	$self->{"form"}->{"onMoveCommEvt"}->Add( sub       { $self->__OnMoveCommdHndl(@_) } );

	$self->{"form"}->{"onChangeTypeEvt"}->Add( sub { $self->__OnChangeTypeHndl(@_) } );
	$self->{"form"}->{"onChangeNoteEvt"}->Add( sub { $self->__OnChangeNoteHndl(@_) } );

	$self->{"form"}->{'onAddFileEvt'}->Add( sub        { $self->__OnAddFileHndl(@_) } );
	$self->{"form"}->{'onChangeFileNameEvt'}->Add( sub { $self->__OnChangeFileNameHndl(@_) } );
	$self->{"form"}->{'onRemoveFileEvt'}->Add( sub     { $self->__OnRemoveFileHndl(@_) } );
	$self->{"form"}->{'onEditFileEvt'}->Add( sub       { $self->__OnEditFileHndl(@_) } );

	$self->{"form"}->{'onAddSuggesEvt'}->Add( sub    { $self->__OnAddSuggesHndl(@_) } );
	$self->{"form"}->{'onRemoveSuggesEvt'}->Add( sub { $self->__OnRemoveSuggesHndl(@_) } );
	$self->{"form"}->{'onChangeSuggesEvt'}->Add( sub { $self->__OnChangeSuggesHndl(@_) } );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

