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
	$self->{'onRemoveFileEvt'}     = Event->new();
	$self->{'onEditFileEvt'}       = Event->new();
	$self->{'onAddFileEvt'}        = Event->new();
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

	my $btnRemove = Wx::Button->new( $self, -1, "- Remove",   &Wx::wxDefaultPosition, [ 80, -1 ] );
	my $btnEditGS = Wx::Button->new( $self, -1, "Edit in GS", &Wx::wxDefaultPosition, [ 80, -1 ] );
	my $btnAddCAM = Wx::Button->new( $self, -1, "+ Add CAM",  &Wx::wxDefaultPosition, [ 80, -1 ] );
	my $btnAddGS  = Wx::Button->new( $self, -1, "+ Add GS",   &Wx::wxDefaultPosition, [ 80, -1 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnAddCAM, -1, sub { $self->{"onAddFileEvt"}->Do( 1, 0 ) } );
	Wx::Event::EVT_BUTTON( $btnAddGS,  -1, sub { $self->{"onAddFileEvt"}->Do( 0, 1 ) } );

	# DEFINE LAYOUT STRUCTURE

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $nb,     1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szBtns, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

		$szBtns->Add( $btnAddCAM, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnAddGS,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	$szBtns->Add( 1, 1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnRemove, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnEditGS, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );


	$self->SetSizer($szMain);

	# SET REFERENCES
	$self->{"nb"} = $nb;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub AddFile {
	my $self       = shift;
	my $fileLayout = shift;

	my $count = $self->{"nb"}->GetPageCount();
	my $page = MyWxBookCtrlPage->new( $self->{"nb"}, $count );

	my $szTab  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szHead = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $fileNameTxt = Wx::StaticText->new( $page, -1, "File name:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $fileNamePrefValTxt = Wx::StaticText->new( $page, -1, $fileLayout->GetFilePrefix() . ( $count + 1 ), &Wx::wxDefaultPosition, [ 20, 25 ] );
	my $fileNameExtraValTxt = Wx::TextCtrl->new( $page, -1, $fileLayout->GetFileCustName(), &Wx::wxDefaultPosition, [ 100, 25 ] );
	my $fileNameSuffValTxt = Wx::StaticText->new( $page, -1, $fileLayout->GetFileSufix(), &Wx::wxDefaultPosition, [ 30, 25 ] );

	Wx::InitAllImageHandlers();

	my $p = $fileLayout->GetFilePath();

	unless ( -e $p ) {
		$p = GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\noImage.png";
	}

	my $im = Wx::Image->new( $p, &Wx::wxBITMAP_TYPE_PNG );

	use constant MAXIMGW => 50;    # 500px
	use constant MAXIMGH => 35;    # 500px

	my $w = $im->GetWidth();
	my $h = $im->GetHeight();

	my $scale = 1;

	my $scaleW = MAXIMGW / $w;
	my $scaleH = MAXIMGH / $h;

	if ( max( $scaleW, $scaleH ) < 1 ) {
		$scale = min( $scaleW, $scaleH );
	}

	my $btmIco = Wx::Bitmap->new( $im->Scale( $w * $scale, $h * $scale ) );    #wxBITMAP_TYPE_PNG;

	#
	#	my $btmIco = Wx::Bitmap->new( $p, &Wx::wxBITMAP_TYPE_PNG );    #wxBITMAP_TYPE_PNG;
	my $statBtmIco = Wx::StaticBitmap->new( $page, -1, $btmIco );

	#	$statBtmIco->SetScaleMode();
	# EVENTS

	#Wx::Event::EVT_LEFT_DOWN( $statBtmIco, sub { print STDERR "obr click" } );

	# DEFINE LAYOUT
	$szTab->Add( $szHead, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szTab->Add( 5, 5, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szTab->Add( $statBtmIco, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szHead->Add( $fileNameTxt,         0, &Wx::wxALL, 1 );
	$szHead->Add( $fileNamePrefValTxt,  0, &Wx::wxALL, 1 );
	$szHead->Add( $fileNameExtraValTxt, 0, &Wx::wxALL, 1 );
	$szHead->Add( $fileNameSuffValTxt,  0, &Wx::wxALL, 1 );

	$page->SetSizer($szTab);

	$self->{"nb"}->AddPage( $page, "File " . ( $count + 1 ), 0, $count );

	# SET REFERENCES

	$page->{"fileNamePrefValTxt"} = $fileNamePrefValTxt;

	$page->SetBackgroundColour( Wx::Colour->new( 193, 240, 193 ) );    #gray

	#	$page->Refresh();
	#	$szTab->Layout();
	#	$page->Refresh();
	#	$szTab->Layout();
	#	 $page->Show(0);
	#	  $page->Show(1);
	# $self->{"nb"}->Layout();
	#	$self->{"nb"}->FitInside();

}

sub RemoveFile {
	my $self       = shift;
	my $fileId     = shift;
	my $fileLayout = shift;

}

sub UpdateFile {
	my $self       = shift;
	my $fileId     = shift;
	my $fileLayout = shift;

}

sub SetFilesLayout {
	my $self        = shift;
	my @filesLayout = @{ shift(@_) };

	$self->Freeze();

	$self->{"nb"}->DeleteAllPages();

	for ( my $i = 0 ; $i < scalar(@filesLayout) ; $i++ ) {

		my $fileLayout = $filesLayout[$i];

		$self->AddFile($fileLayout);
	}

	$self->Thaw();
}

# =====================================================================
# PRIVATE METHODS
# =====================================================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

