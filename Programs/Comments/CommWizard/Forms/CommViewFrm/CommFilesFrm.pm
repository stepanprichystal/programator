#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommViewFrm::CommFilesFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use List::Util qw[max min];

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Comments::Enums';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::AddFileFrm';
use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::CommFilesDragDrop';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"jobId"} = $jobId;

	$self->__SetLayout();

	# DEFINE EVENTS
	$self->{'onAddFileEvt'}        = Event->new();
	$self->{'onRemoveFileEvt'}     = Event->new();
	$self->{'onEditFileEvt'}       = Event->new();
	$self->{'onChangeFileNameEvt'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szBtns = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $nb = Wx::Notebook->new( $self, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $btnRemove    = Wx::Button->new( $self, -1, "- Remove",       &Wx::wxDefaultPosition, [ 90,  28 ] );
	my $btnEditGS    = Wx::Button->new( $self, -1, "Edit in GS",     &Wx::wxDefaultPosition, [ 90,  28 ] );
	my $btnAddCAMDir = Wx::Button->new( $self, -1, "+ CAM (direct)", &Wx::wxDefaultPosition, [ 110, 28 ] );
	my $btnAddCAM    = Wx::Button->new( $self, -1, "+ CAM",          &Wx::wxDefaultPosition, [ 70,  28 ] );
	my $btnAddGS     = Wx::Button->new( $self, -1, "+ GS",           &Wx::wxDefaultPosition, [ 70,  28 ] );
	my $btnAddFile   = Wx::Button->new( $self, -1, "+ File",         &Wx::wxDefaultPosition, [ 70,  28 ] );

	# Drag and drop for File button
	$btnAddFile->DragAcceptFiles(1);
	my $btnDragDrop = CommFilesDragDrop->new($btnAddFile);
	$btnAddFile->SetDropTarget($btnDragDrop);

	$self->{'addFileFrm'} = AddFileFrm->new($self);

	# Set icons
	$self->__SetIconByApp( $btnAddGS,     GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\GreenShot22x22.ico" );
	$self->__SetIconByApp( $btnAddCAMDir, GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\InCAM22x22.ico" );
	$self->__SetIconByApp( $btnAddCAM,    GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\InCAM22x22.ico" );
	$self->__SetIconByApp( $btnAddFile,   GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\file24x24.ico" );

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnAddCAMDir, -1, sub { $self->{"onAddFileEvt"}->Do( 1, 0, 0, 0 ) } );
	Wx::Event::EVT_BUTTON( $btnAddCAM,    -1, sub { $self->{"onAddFileEvt"}->Do( 0, 1, 0, 0 ) } );
	Wx::Event::EVT_BUTTON( $btnAddGS,     -1, sub { $self->{"onAddFileEvt"}->Do( 0, 0, 1, 0 ) } );
	Wx::Event::EVT_BUTTON( $btnAddFile,   -1, sub { $self->__ShowAddFileFrm() } );
	Wx::Event::EVT_BUTTON( $btnEditGS,    -1, sub { $self->{"onEditFileEvt"}->Do( $nb->GetCurrentPage()->GetPageId() ) } );
	Wx::Event::EVT_BUTTON( $btnRemove,    -1, sub { $self->{"onRemoveFileEvt"}->Do( $nb->GetCurrentPage()->GetPageId() ) } );
	$self->{"addFileFrm"}->{"onAddFileEvt"}->Add( sub { $self->{"onAddFileEvt"}->Do( 0, 0, 0, 1, @_ ) } );
	$btnDragDrop->{"onAddFileEvt"}->Add( sub { $self->{"onAddFileEvt"}->Do( 0, 0, 0, 1, "existingFileDragDrop", @_ ) } );

	# DEFINE LAYOUT STRUCTURE

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $nb,     1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szBtns, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szBtns->Add( $btnAddCAMDir, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnAddCAM,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnAddGS,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnAddFile,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szBtns->Add( 1, 1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnEditGS, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnRemove, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SET REFERENCES
	$self->{"nb"}        = $nb;
	$self->{"btnRemove"} = $btnRemove;
	$self->{"btnEditGS"} = $btnEditGS;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub __AddFile {
	my $self       = shift;
	my $fileLayout = shift;
	my $commId     = shift;

	my $count = $self->{"nb"}->GetPageCount();
	my $page = MyWxBookCtrlPage->new( $self->{"nb"}, $count );

	my $szTab  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szHead = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $fileNameTxt = Wx::StaticText->new( $page, -1, "Output name:", &Wx::wxDefaultPosition, [ 90, 30 ] );
	my $fileNamePrefValTxt = Wx::StaticText->new( $page, -1, $fileLayout->GetFilePrefix() . ( $commId + 1 ), &Wx::wxDefaultPosition, [ 20, 30 ] );
	my $fileNameExtraValTxt = Wx::TextCtrl->new( $page, -1, $fileLayout->GetFileCustName(), &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $fileNameSuffValTxt = Wx::StaticText->new( $page, -1, $fileLayout->GetFileSufix(), &Wx::wxDefaultPosition, [ 30, 30 ] );

	Wx::InitAllImageHandlers();

	my $p = $fileLayout->GetFilePath();

	if ( !-e $p ) {
		$p = GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\noImage.png";
	}
	elsif ( !$fileLayout->IsImage() ) {

		if ( $fileLayout->GetIsPDF() ) {

			$p = GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\filePDF.png";
		}
		else {

			$p = GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\fileAll.png";
		}

	}

	my $im = Wx::Image->new( $p, &Wx::wxBITMAP_TYPE_ANY );

	use constant MAXIMGW => 690;    # 500px
	use constant MAXIMGH => 270;    # 500px

	my $w = $im->GetWidth();
	my $h = $im->GetHeight();

	my $scale = 1;

	my $scaleW = MAXIMGW / $w;
	my $scaleH = MAXIMGH / $h;

	if ( $scaleW < 1 || $scaleH < 1 ) {

		$scale = min( $scaleW * 10, $scaleH * 10 ) / 10;
	}

	my $btmIco = Wx::Bitmap->new( $im->Scale( $w * $scale, $h * $scale ) );    #wxBITMAP_TYPE_PNG;

	#
	#	my $btmIco = Wx::Bitmap->new( $p, &Wx::wxBITMAP_TYPE_PNG );    #wxBITMAP_TYPE_PNG;
	my $statBtmIco = Wx::StaticBitmap->new( $page, -1, $btmIco );

	#	$statBtmIco->SetScaleMode();
	# EVENTS
	Wx::Event::EVT_TEXT( $fileNameExtraValTxt, -1,
						 sub { $self->{"onChangeFileNameEvt"}->Do( $page->GetPageId(), $fileNameExtraValTxt->GetValue() ) } );

	Wx::Event::EVT_LEFT_DOWN( $statBtmIco, sub { $self->__OnShowFilePreview( $fileLayout->GetFilePath() ) } );

	#$self->{"onChangeFileNameEvt"}->Do($page->GetPageId(), $fileNameExtraValTxt->GetLabel() )
	# DEFINE LAYOUT
	$szTab->Add( $szHead, 0, &Wx::wxEXPAND | &Wx::wxALL, 3 );
	$szTab->Add( 5, 5, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szTab->Add( $statBtmIco, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szHead->Add( $fileNameTxt,         0, &Wx::wxALL, 1 );
	$szHead->Add( $fileNamePrefValTxt,  0, &Wx::wxALL, 1 );
	$szHead->Add( $fileNameExtraValTxt, 0, &Wx::wxALL, 1 );
	$szHead->Add( $fileNameSuffValTxt,  0, &Wx::wxALL, 1 );

	$page->SetSizer($szTab);

	$self->{"nb"}->AddPage( $page, "File " . ( $count + 1 ), 0, $count );

	# SET REFERENCES

	#$self->{"fileNamePrefValTxt"} = $fileNamePrefValTxt;

}

sub SetFilesLayout {
	my $self        = shift;
	my @filesLayout = @{ shift(@_) };
	my $commId      = shift;

	$self->Freeze();

	$self->{"nb"}->DeleteAllPages();

	for ( my $i = 0 ; $i < scalar(@filesLayout) ; $i++ ) {

		my $fileLayout = $filesLayout[$i];

		$self->__AddFile( $fileLayout, $commId );
	}

	if ( scalar(@filesLayout) ) {

		$self->{"nb"}->SetSelection( $self->{"nb"}->GetPageCount() - 1 );
		$self->{"btnRemove"}->Enable();
		$self->{"btnEditGS"}->Enable();
	}
	else {
		$self->{"btnRemove"}->Disable();
		$self->{"btnEditGS"}->Disable();
	}

	$self->Thaw();
}

# =====================================================================
# PRIVATE METHODS
# =====================================================================

sub __OnShowFilePreview {
	my $self     = shift;
	my $filePath = shift;

	# show file preview

	system( "start " . $filePath );

}

sub __SetIconByApp {
	my $self     = shift;
	my $button   = shift;
	my $iconPath = shift;

	return 0 unless ( -e $iconPath );
	Wx::InitAllImageHandlers();
	my $im = Wx::Image->new( $iconPath, &Wx::wxBITMAP_TYPE_ICO );
	my $btmIco = Wx::Bitmap->new( $im->Scale( 22, 22 ) );
	$button->SetBitmap($btmIco);

}

# =====================================================================
# HANDLERS
# =====================================================================

sub __ShowAddFileFrm {
	my $self = shift;

	$self->{'addFileFrm'}->{"mainFrm"}->CentreOnParent(&Wx::wxBOTH);
	$self->{'addFileFrm'}->{"mainFrm"}->Show();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

