#-------------------------------------------------------------------------------------------#
# Description: Form display item title and item result error
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::ItemForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Packages::ItemResult::ItemResultMngr';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new($parent);

	bless($self);

	my $title = shift;
	$self->{"subItem"} = shift;
	$self->{"jobId"}   = shift;
	my $resultItem = shift;

	$self->{"resultMngr"} = ItemResultMngr->new();
	$self->{"resultMngr"}->AddItem($resultItem);

	$self->__SetLayout($title);

	return $self;
}

sub __SetLayout {
	my $self  = shift;
	my $title = shift;

	#define panels
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $bulletText = "   - ";
	unless ( $self->{"subItem"} ) {
		$bulletText = "";
	}

	# DEFINE CONTROLS
	my $bulletTxt = Wx::StaticText->new( $self, -1, $bulletText, &Wx::wxDefaultPosition );
	my $titleTxt = Wx::StaticText->new( $self, -1, $title, &Wx::wxDefaultPosition, [ 70, 20 ] );

	my $errIndicator  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15, undef, $self->{"jobId"}, $self->{"resultMngr"} );
	my $warnIndicator = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"}, $self->{"resultMngr"} );

	$errIndicator->Hide();
	$warnIndicator->Hide();

	# SET EVENTS
	#Wx::Event::EVT_COMBOBOX( $colorCb, -1, sub { $self->__OnColorChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $bulletTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $titleTxt,      1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $errIndicator,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $warnIndicator, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"errIndicator"}  = $errIndicator;
	$self->{"warnIndicator"} = $warnIndicator;
	$self->{"szMain"}        = $szMain;
}

sub SetErrors {
	my $self  = shift;
	my $count = shift;

	$self->{"errIndicator"}->SetErrorCnt($count);

	if ( $count > 0 ) {
		$self->{"errIndicator"}->Show(1);

	}

	#$self->{"szMain"}->Layout();

}

sub SetWarnings {
	my $self  = shift;
	my $count = shift;

	$self->{"warnIndicator"}->SetErrorCnt($count);

	if ( $count > 0 ) {
		$self->{"warnIndicator"}->Show(1);

	}

	#	$self->{"szMain"}->Layout();
}

1;
