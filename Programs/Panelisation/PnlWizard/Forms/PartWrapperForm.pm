#-------------------------------------------------------------------------------------------#
# Description: Wrapper wifget for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Forms::PartWrapperForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Widgets::Style;

#local library

#use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my ( $class, $parent, $partType, $title ) = @_;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# PROPERTIES
	$self->{"partType"}  = $partType;
	$self->{"title"}     = $title;
	$self->{"partBody"}  = undef;
	$self->{"maximized"} = 0;

	$self->__SetLayout();

	#EVENTS

	$self->{"maximizeChangedEvt"} = Event->new();
	$self->{"previewChangedEvt"}  = Event->new();

	return $self;
}

sub Init {
	my $self     = shift;
	my $partBody = shift;

	$self->{"szBody"}->Add( $partBody, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	#	$self->{"groupHeight"} = $groupBody->{"groupHeight"};
	#
	#	# panel, which contain group content
	$self->{"partBody"} = $partBody;

	#$self->{"groupBody"}->Disable();
	$self->Refresh();

}

sub __SetLayout {
	my $self = shift;

	# define panels
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szHeader = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szBody = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	
	my $pnlHeader = Wx::Panel->new( $self, -1 );
	my $pnlBody = Wx::Panel->new( $self, -1 );

	$self->SetBackgroundColour( Wx::Colour->new( 112, 0, 0 ) );
	$pnlHeader->SetBackgroundColour( Wx::Colour->new( 112, 146, 190 ) );
	$pnlBody->SetBackgroundColour( Wx::Colour->new( 0, 146, 0 ) );

	 
	# DEFINE CONTROLS
	 Wx::InitAllImageHandlers();
	my $iconPath     = GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . $self->{"partType"} . ".png";
	my $iconBtmp     = Wx::Bitmap->new( $iconPath, &Wx::wxBITMAP_TYPE_PNG );
	my $iconStatBtmp = Wx::StaticBitmap->new( $self, -1, $iconBtmp );
	my $titleTxt = Wx::StaticText->new( $pnlHeader, -1, $self->{"title"} );
	my $previewChb = Wx::CheckBox->new( $pnlHeader, -1, "", &Wx::wxDefaultPosition );
	my $errInd = ErrorIndicator->new( $pnlHeader, EnumsGeneral->MessageType_ERROR, 15, undef, $self->{"jobId"} );
	$errInd->{"onClick"}->Add( sub { $self->{"procIndicatorClick"}->Do( EnumsGeneral->MessageType_ERROR ) } );
	
  
	$szMain->Add( $pnlHeader, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $pnlBody, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	
	$szHeader->Add( $iconStatBtmp, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szHeader->Add( $titleTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szHeader->Add( $previewChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szHeader->Add( $errInd, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	 

	$pnlHeader->SetSizer($szHeader);
	$pnlBody->SetSizer($szBody);

	
	$self->SetSizer($szMain);
 
 
 	# SET REFERENCES
 	
 	$self->{"pnlBody"} = $pnlBody;
 	$self->{"szBody"} = $szBody;
 	
 
	#$self->__RecursiveHandler($pnlHeader);

}

#sub Test {
#	my $self = shift;
#	print STDERR "Refresh";
#	#$self->{"groupBody"}->Refresh();
#	#$self->{"pnlSwitch"}->Refresh();
#
#}
 
sub GetParentForPart {
	my $self = shift;

	return $self->{"pnlBody"};
}

1;
