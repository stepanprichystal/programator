#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommViewFrm::AddFileFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::QuickNoteFrm::NoteList';
use aliased 'Helpers::GeneralHelper';

#tested form

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class     = shift;
	my $parent    = shift;
	my @dimension = ( 200, 170 );

	my $flags = &Wx::wxCAPTION |  &Wx::wxFRAME_NO_TASKBAR | &Wx::wxSTAY_ON_TOP;
	my $self = $class->SUPER::new( $parent, "Choose file type", \@dimension, $flags );

	bless($self);

	$self->__SetLayout();

	# Properties

	# DEFINE EVENTS
	$self->{'onAddFileEvt'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $btnAddFile  = Wx::Button->new( $self->{"mainFrm"}, -1, "+ Add existing file",    &Wx::wxDefaultPosition );
	my $btnStckpPDF = Wx::Button->new( $self->{"mainFrm"}, -1, "+ Generate PDF stackup", &Wx::wxDefaultPosition );
	my $btnStckpIMG = Wx::Button->new( $self->{"mainFrm"}, -1, "+ Generate JPEG stackup", &Wx::wxDefaultPosition );

	$self->__SetIconByApp( $btnAddFile,  GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\file24x24.ico" );
	$self->__SetIconByApp( $btnStckpPDF, GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\stackup22x22.ico" );
	$self->__SetIconByApp( $btnStckpIMG, GeneralHelper->Root() . "\\Programs\\Comments\\CommWizard\\Resources\\stackup22x22.ico" );

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnAddFile, -1, sub { $self->__OnAddFileClick("existingFile") } );
	Wx::Event::EVT_BUTTON( $btnStckpPDF, -1, sub { $self->__OnAddFileClick("stackupPDF") } );
	Wx::Event::EVT_BUTTON( $btnStckpIMG, -1, sub { $self->__OnAddFileClick("stackupImage") } );

	$szMain->Add( $btnAddFile,  1, &Wx::wxEXPAND );
	$szMain->Add( $btnStckpPDF, 1, &Wx::wxEXPAND );
	$szMain->Add( $btnStckpIMG, 1, &Wx::wxEXPAND );

	$self->AddContent($szMain);

	$self->SetButtonHeight(25);

	$self->AddButton( "Cancel", sub { $self->__OnCloseClick(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# Add this rappet to group table

}


sub __OnAddFileClick {
	my $self = shift;
	my $fileType = shift;

	$self->{"mainFrm"}->Hide();

	 $self->{"onAddFileEvt"}->Do($fileType)

}

sub __OnCloseClick {
	my $self = shift;

	$self->{"mainFrm"}->Hide();

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

