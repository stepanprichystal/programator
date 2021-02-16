
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
use File::Basename;
use Try::Tiny;

#use strict;

#local library
use aliased 'Programs::Comments::CommWizard::Forms::CommWizardFrm';
use aliased 'Programs::Comments::Comments';
use aliased 'Programs::Comments::Enums' => 'CommEnums';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::Comments::CommMail::CommMail';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Exporter::ExportCheckerMini::RunExport::RunExporterCheckerMini';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ControlPdf';
use aliased 'Packages::SystemCall::SystemCall';
use aliased 'Helpers::GeneralHelper';

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

	$self->{"addDefaultComm"} = shift;    # add default comments when app start

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

	$self->{"comments"} = Comments->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"addDefaultComm"} );

	# Refresh before set handlers in order do not raise events
	$self->__RefreshForm();

	#set handlers for main app form
	$self->__SetHandlers();

	# Set timers which works on background
	$self->__SetTimers();

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

		if ( $self->__FormChecks() ) {

			$self->{"comments"}->Save();
			$self->{"form"}->RefreshCommListViewForm( $self->{"comments"}->GetLayout() );
		}
		else {
			return 0;
		}
	}

	if ($export) {

		$self->__StopTimers();

		# Run next app and use current server

		# 1) Disconect this app from server
		if ( $self->{"inCAM"}->IsConnected() ) {
			$self->{"inCAM"}->ClientFinish();
		}

		# 2) Tell to launcher, do not close/exit server when this app ends
		$self->{"launcher"}->SetLetServerRun();

		# 3) Run new app via ExportCheckerMiniWrapper ( wrapper for AppLauncher package and RunFromApp method)
		# Pass current port from launcher to AppLauncher
		my $unitId = UnitEnums->UnitId_COMM;
		my $unitDim = [ 600, 400 ];

		my $app = RunExporterCheckerMini->new( $self->{"jobId"}, $unitId, $unitDim, 1, $self->{"launcher"}->GetServerPort() );

		# 4) End this app
		$self->{"form"}->{"mainFrm"}->Close();

	}

	if ($exit) {

		$self->__StopTimers();

		$self->{"form"}->{"mainFrm"}->Close();
	}

}

sub __OnEmailPreview {
	my $self = shift;

	if ( $self->__FormChecks() ) {
		my %inf  = %{ HegMethods->GetCustomerInfo( $self->{"jobId"} ) };
		my $lang = "en";

		# if country CZ or SK
		$lang = "cz" if ( $inf{"zeme"} eq 25 || $inf{"zeme"} eq 79 );

		my $mail = CommMail->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"comments"}->GetLayout(), $lang );

		my $txt = "!!! NEODESÍLAT !!! (pouze náhled, odeslat vždy přes Export)";
		$mail->Open( [$txt], [], "-", undef, 0, 0, 0 );

		#$mail->Sent(['stepan.prichystal@gatema.cz'], [], "Comment preview...");

	}
}

sub __OnClearAllHndl {
	my $self = shift;

	my $layout = $self->{"comments"}->GetLayout();

	if ( scalar( $layout->GetAllComments ) ) {

	   #		my $messMngr = $self->{"form"}->GetMessMngr();
	   #
	   #		my @mess = ();
	   #
	   #		push( @mess, "You are about to clear all comments:\n" );
	   #		push( @mess, " 1) First, all coments will be archived in: " . $self->{"comments"}->GetCommArchiveDir() );
	   #		push( @mess, " 2) All coments will be removed from viewer" );
	   #		push( @mess, " 3) You can restore last cleared comments by click on Restore button (activ3e only if Comemnt list is empty)" );
	   #		push( @mess, "\n\nDo you want continue?" );
	   #
	   #		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "No", "Yes, archive and clear comments" ] );    #  Script is stopped
	   #
	   #		if ( $messMngr->Result() == 1 ) {

		# Remove comments from list

		$self->{"comments"}->ClearCoomments();

		$self->{"form"}->RefreshCommListViewForm($layout);
		$self->{"form"}->RefreshCommViewForm(-1);

		#		}

	}

}

sub __OnRestoreHndl {
	my $self = shift;

	my $layout   = $self->{"comments"}->GetLayout();
	my $messMngr = $self->{"form"}->GetMessMngr();
	if ( scalar( $layout->GetAllComments ) ) {

		my @mess = ();
		push( @mess, "Unable to restore comments, when still exist " . scalar( $layout->GetAllComments ) . " comments in list" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess );    #  Script is stopped

		return 0;
	}

	if ( scalar( $layout->GetAllComments ) ) {

		my @mess = ();
		push( @mess, "Unable to restore comments, when still exist " . scalar( $layout->GetAllComments ) . " comments in list" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess );    #  Script is stopped

		return 0;
	}

	my $res = $self->{"comments"}->RestoreCoomments();

	if ($res) {

		$self->__RefreshForm();
	}
	else {
		my @mess = ();
		push( @mess, "Unable to restore comments, because there are no archived comments at: " . $self->{"comments"}->GetCommArchiveDir() );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );    #  Script is stopped
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

	# Check if exist green shot
	if ( !-e CommEnums->Path_GREENSHOT ) {
		my $messMngr = $self->{"form"}->GetMessMngr();
		$messMngr->ShowModal(
							  -1,
							  EnumsGeneral->MessageType_WARNING,
							  [
								 "Nelze použít aplikaci GreenShot.",
								 "Aplikace musí být nainstalovaná na následující cestě: " . CommEnums->Path_GREENSHOT
							  ]
		);

		return 0;
	}

	unless ( $self->{"comments"}->EditFile( $commId, $fileId ) ) {

		my $messMngr = $self->{"form"}->GetMessMngr();
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during edit image in GreenShot"] );    #  Script is stopped
	}

}

sub __OnAddFileHndl {
	my $self        = shift;
	my $commId      = shift;
	my $addCAMDir   = shift;    # Add CAM directly without pause
	my $addCAM      = shift;
	my $addGS       = shift;
	my $addFile     = shift;
	my $addFileType = shift;    # Existing/ PDF stackup/ IMG stackup ...

	my $messMngr = $self->{"form"}->GetMessMngr();

	$self->{"form"}->HideFrm() if ( $addCAM || $addGS );

	my $p          = "";
	my $delOriFile = 0;         # Remove original file after adding to comments
	my $custName   = undef;     # Name of final file
	my $res;

	# Process snapshots
	if ( $addCAM || $addCAMDir || $addGS ) {

		if ( $addCAM || $addCAMDir ) {

			$res = $self->{"comments"}->SnapshotCAM( $addCAMDir, \$p );
		}
		elsif ($addGS) {

			# Check if exist green shot
			if ( -e CommEnums->Path_GREENSHOT ) {
				$res = $self->{"comments"}->SnapshotGS( \$p );
			}
			else {
				$res = 0;
				$messMngr->ShowModal(
									  -1,
									  EnumsGeneral->MessageType_WARNING,
									  [
										 "Nelze použít aplikaci GreenShot.",
										 "Aplikace musí být nainstalovaná na následující cestě: " . CommEnums->Path_GREENSHOT
									  ]
				);
			}

		}
		$self->{"form"}->ShowFrm();
		unless ($res) {
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during create/attach file or image"] );    #  Script is stopped
		}
	}

	elsif ( $addFile && $addFileType eq "existingFile" ) {

		# Process file attach

		$res = $self->{"comments"}->ChooseFile( \$p, $self->{"form"}->{"mainFrm"} );

		# No spaces alowed
		if ( $p =~ /\s/ ) {

			$res = 0;
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["File name has to be without spaces and diacritics"] );   #  Script is stopped
		}

		my ( $name, $a, $suf ) = fileparse( $p, qr/\.\w*/ );
		$custName = $name;    # Take name form original file

	}
	elsif ( $addFile && ( $addFileType eq "stackupPDF" || $addFileType eq "stackupImage" ) ) {

		# Process stackup

		$delOriFile = 1;
		my $stckOutput = undef;

		my $mess = "";

		try {

			my $control = ControlPdf->new( $self->{"inCAM"}, $self->{"jobId"}, "o+1", 0, 0 );

			$control->AddStackupPreview( \$mess );

			$res = $control->GeneratePdf( \$mess );
			 
			$stckOutput = $control->GetOutputPath();

		}
		catch {
			$mess .= "Error during generating stackup stackup: " . $_;
			$res = 0;

		};

		if ($res) {

			if ( $addFileType eq "stackupPDF" ) {

				$p = $stckOutput;

			}
			elsif ( $addFileType eq "stackupImage" ) {

				my $pdf = $stckOutput;

				my $pImg = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpeg";

				my @cmds = ();
				push( @cmds, EnumsPaths->Client_IMAGEMAGICK . "convert.exe +antialias" );

				push( @cmds, " -density 300" );
				push( @cmds, $pdf . " -flatten" );
				push( @cmds, "-resize 1060x1500!" ); 
				push( @cmds, $pImg );

				print STDERR join( " ", @cmds );

				my $systeMres = system( join( " ", @cmds ) );

				unlink($pdf);

				if ( $systeMres > 0 ) {
					$messMngr->ShowModal( -1,
										  EnumsGeneral->MessageType_ERROR,
										  ["Error during converting PDF stackup to IMG. Error detail: $systeMres"] );    #  Script is stopped

					$res = 0;

				}
				else {

					$p = $pImg;
				}

			}

			$custName = $self->{"jobId"} . "_stackup";    # Take name form original file
		}
		else {
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during create stackup. Detail: $mess"] );    #  Script is stopped
		}

	}

	# Store result
	if ($res) {

		$self->{"comments"}->AddFile( $commId, $custName, $p );

		unlink($p) if ($delOriFile);

		# Refresh Comm view
		my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);
		$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );

		# Refresh Comm list
		$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );
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

	$self->{"form"}->{"saveExitEvt"}->Add( sub     { $self->__SaveExitHndl(@_) } );
	$self->{"form"}->{"emailPreviewEvt"}->Add( sub { $self->__OnEmailPreview(@_) } );
	$self->{"form"}->{"clearAllEvt"}->Add( sub     { $self->__OnClearAllHndl(@_) } );
	$self->{"form"}->{"restoreEvt"}->Add( sub      { $self->__OnRestoreHndl(@_) } );

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

sub __SetTimers {
	my $self = shift;

	# Hack - refresh form after start in order show images in Notebook control
	my $tmtImgUpdate = Wx::Timer->new( $self->{"form"}->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER(
		$self->{"form"}->{"mainFrm"}, $tmtImgUpdate,

		sub {
			my $commId = $self->{"form"}->GetSelectedComment();

			return 0 unless ( defined $commId );
			my $commSngl = $self->{"comments"}->GetLayout()->GetCommentById($commId);

			my @files = grep { $_->IsImage() } $commSngl->GetAllFiles();

			my $refresh = 0;
			foreach my $f (@files) {

				my $currUpdate = ( stat( $f->GetFilePath() ) )[9];
				if ( $f->GetLastUpdate() != $currUpdate ) {
					$f->SetLastUpdate($currUpdate);
					$refresh = 1;

				}

			}

			# Refresh if curr comment is still selected
			if ( $refresh && $commId == $self->{"form"}->GetSelectedComment() ) {
				$self->{"form"}->RefreshCommViewForm( $commId, $commSngl );
			}
		}
	);

	# Check special folder, where greenshot scrrens are stored
	# If tehere is new screenshot, ask user what to do with screen
	my $tmGSSnapshot = Wx::Timer->new( $self->{"form"}->{"mainFrm"}, -1, );

	Wx::Event::EVT_TIMER(
		$self->{"form"}->{"mainFrm"}, $tmGSSnapshot,

		sub {

			my $pGS = $self->{"comments"}->GetGSSnapshotPath();

			return 0 unless ( -e $pGS );

			$tmGSSnapshot->Stop();

			my $messMngr = $self->{"form"}->GetMessMngr();

			my @comments = $self->{"comments"}->GetLayout()->GetAllComments();

			if ( scalar(@comments) > 0 ) {

				$messMngr->ShowModal( -1,
									  EnumsGeneral->MessageType_QUESTION,
									  ["Image was received from <b><g>GreenShot</g></b>.\n\nWhat woud you like to do with this image?"],
									  [ "Nothing", "Add to new comment", "Add to selected comment" ] );

			}
			else {
				$messMngr->ShowModal( -1,
									  EnumsGeneral->MessageType_QUESTION,
									  ["Image was received from <b><g>GreenShot</g></b>.\n\nWhat woud you like to do with this image?"],
									  [ "Nothing", "Add to new comment" ] );
			}

			my $res = $messMngr->Result();

			if ( $res > 0 ) {

				my $commId;

				# Create new comment
				if ( $res == 1 ) {
					$self->__OnAddCommdHndl();
					$commId = scalar(@comments);
				}
				elsif ( $res == 2 ) {

					$commId = $self->{"form"}->GetSelectedComment();
				}

				my $p = "";
				$self->{"comments"}->SnapshotGSDirectly( \$p );
				$self->{"comments"}->AddFile( $commId, undef, $p );

				# Refresh Comm view
				my $commSnglLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);
				$self->{"form"}->RefreshCommViewForm( $commId, $commSnglLayout );

				# Refresh Comm list
				$self->{"form"}->RefreshCommListItem( $commId, $commSnglLayout );

			}
			else {
				unlink($pGS) if ( -e $pGS );
			}

			$tmGSSnapshot->Start(500);
		}
	);

	$tmtImgUpdate->Start(1000);
	$tmGSSnapshot->Start(500);

	$self->{"tmtImgUpdate"} = $tmtImgUpdate;
	$self->{"tmGSSnapshot"} = $tmGSSnapshot;
}

sub __StopTimers {
	my $self = shift;
	$self->{"tmtImgUpdate"}->Stop();
	$self->{"tmGSSnapshot"}->Stop();
}

sub __FormChecks {
	my $self = shift;

	my $result   = 1;
	my $messMngr = $self->{"form"}->GetMessMngr();

	# Do error check

	my @errMess = ();

	# Check critical errors
	$self->{"comments"}->CheckBeforeSave( \@errMess );

	# Check less ritical errors
	my $commLayout = $self->{"comments"}->GetLayout();

	# Cehck if all atgs was found
	my @allComm = $commLayout->GetAllComments();

	for ( my $i = 0 ; $i < scalar(@allComm) ; $i++ ) {

		my @files = $allComm[$i]->GetAllFiles();
		my $text  = $allComm[$i]->GetText();
		$text .= join( " ", $allComm[$i]->GetAllSuggestions() );

		my @tags = ( $text =~ /(\@f\d+)/g );

		foreach my $tag (@tags) {

			my $fileNum = ( $tag =~ /^\@f(\d+)$/ )[0] - 1;

			if ( $fileNum < 0 || $fileNum >= scalar(@files) ) {

				push( @errMess, "No file exists in comment number:" . ( $i + 1 ) . " for tag: $tag" );
			}
		}
	}

	if ( scalar(@errMess) ) {
		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ "Chyba při kontrole formuláře.", "Detail chyby:\n" . join( "\n", map { "- " . $_ } @errMess ) ],
							  ["Repair"] );
		$result = 0;
	}
	else {

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
								  [ "Varování při kontrole formuláře.", "Detail varování:\n" . join( "\n", map { "- " . $_ } @warnMess ) ],
								  [ "Repair",                                "Continue" ] );

			if ( $messMngr->Result() == 0 ) {

				$result = 0;
			}
		}

	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

