#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommViewFrm::CommSugessFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

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

	 

	my $btnRemove = Wx::Button->new( $self, -1, "Remove",           &Wx::wxDefaultPosition, [ 60, -1 ] );
	my $btnEditGS = Wx::Button->new( $self, -1, "Edit in GShot",    &Wx::wxDefaultPosition, [ 60, -1 ] );
	my $btnAddCAM = Wx::Button->new( $self, -1, "Add Snapshot CAM", &Wx::wxDefaultPosition, [ 60, -1 ] );
	my $btnAddGS  = Wx::Button->new( $self, -1, "Add Snapshot GS",  &Wx::wxDefaultPosition, [ 60, -1 ] );

	# DEFINE LAYOUT STRUCTURE

	# BUILD STRUCTURE OF LAYOUT
	 
	$szMain->Add( $szBtns, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szBtns->Add( $btnRemove, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnEditGS, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( 1, 1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnAddCAM, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnAddGS,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SET REFERENCES
 

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
 

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

	$self->{"nb"}->DeleteAllPages();

	for ( my $i = 0 ; $i < scalar(@filesLayout) ; $i++ ) {

		my $fileLayout = $filesLayout[$i];

		$self->AddFile($fileLayout);
	}
	 
 
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

