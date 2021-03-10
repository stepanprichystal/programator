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
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my ( $class, $parent, $partType, $title, $messMngr ) = @_;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# PROPERTIES
	$self->{"partType"}         = $partType;
	$self->{"title"}            = $title;
	$self->{"messMngr"}         = $messMngr;
	$self->{"partBody"}         = undef;
	$self->{"maximized"}        = 0;
	$self->{"loadingIndicator"} = 0;

	$self->__SetLayout();

	#EVENTS

	$self->{"maximizeChangedEvt"} = Event->new();
	$self->{"previewChangedEvt"}  = Event->new();
	$self->{"errIndClickEvent"}   = Event->new();

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

sub SetErrIndicator {
	my $self = shift;
	my $cnt  = shift;

	$self->{"errInd"}->SetErrorCnt($cnt);

}


sub SetFinalProcessLayout {
	my $self = shift;
	my $val  = shift;    # start/end

	 if($val){
	 	
	 	$self->{"previewChb"}->Disable();
	 	$self->{"pnlBody"}->Disable();
	 }else{
	 	
	 	
	 	$self->{"previewChb"}->Enable();
	 	$self->{"pnlBody"}->Enable();
	 }

}

sub __SetLayout {
	my $self = shift;

	# define panels
	my $szMain   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szHeader = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szBody   = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $pnlHeader = Wx::Panel->new( $self, -1 );
	my $pnlBody   = Wx::Panel->new( $self, -1 );

	$self->SetBackgroundColour( EnumsStyle->BACKGCLR_LIGHTGRAY );
	$pnlHeader->SetBackgroundColour( EnumsStyle->BACKGCLR_LEFTPNLBLUE );
	$pnlBody->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	# DEFINE CONTROLS
	Wx::InitAllImageHandlers();

	#my $iconPath     = GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . $self->{"partType"} . ".png";
	my $iconPath     = GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/" . "table" . ".png";
	my $iconBtmp     = Wx::Bitmap->new( $iconPath, &Wx::wxBITMAP_TYPE_PNG );
	my $iconStatBtmp = Wx::StaticBitmap->new( $pnlHeader, -1, $iconBtmp );
	my $titleTxt     = Wx::StaticText->new( $pnlHeader, -1, $self->{"title"}, &Wx::wxDefaultPosition );
	my $f            = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );
	$titleTxt->SetFont($f);
	$titleTxt->SetForegroundColour( EnumsStyle->TXTCLR_LEFTPNL );
	my $gauge = Wx::Gauge->new( $pnlHeader, -1, 100, &Wx::wxDefaultPosition, [ 80, 5 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(100);
	$gauge->Pulse();
	$gauge->Hide();

	my $previewChb = Wx::CheckBox->new( $pnlHeader, -1, "Preview", &Wx::wxDefaultPosition );
	$previewChb->SetForegroundColour( Wx::Colour->new( 187, 187, 196 ) );

	my $errInd = ErrorIndicator->new( $pnlHeader, EnumsGeneral->MessageType_ERROR, 15, undef, $self->{"jobId"} );
	$errInd->{"onClick"}->Add( sub { $self->{"errIndClickEvent"}->Do( EnumsGeneral->MessageType_ERROR ) } );

	$szMain->Add( $pnlHeader, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $pnlBody,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szHeader->Add( 80,            0, 0,                                &Wx::wxEXPAND );    # expander
	$szHeader->Add( $iconStatBtmp, 0, &Wx::wxEXPAND | &Wx::wxALL,       2 );
	$szHeader->Add( $titleTxt,     0, &Wx::wxALIGN_CENTER | &Wx::wxALL, 2 );
	$szHeader->Add( $gauge,        0, &Wx::wxEXPAND | &Wx::wxALL,       2 );

	$szHeader->Add( 1,           1, 1,                          &Wx::wxEXPAND );            # expander
	$szHeader->Add( $previewChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szHeader->Add( $errInd,     0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$pnlHeader->SetSizer($szHeader);
	$pnlBody->SetSizer($szBody);

	$self->SetSizer($szMain);

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $previewChb, -1, sub { $self->{"previewChangedEvt"}->Do( ( $self->{"previewChb"}->IsChecked() ? 1 : 0 ) ) } );

	# SET REFERENCES

	$self->{"pnlBody"}    = $pnlBody;
	$self->{"szBody"}     = $szBody;
	$self->{"previewChb"} = $previewChb;
	$self->{"errInd"}     = $errInd;
	$self->{"gauge"}      = $gauge;

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

sub GetMessMngr {
	my $self = shift;

	return $self->{"messMngr"};
}

sub SetPreview {
	my $self  = shift;
	my $value = shift;

	$self->{"previewChb"}->SetValue($value);
}

sub GetPreview {
	my $self = shift;
	return $self->{"previewChb"}->GetValue();
}

sub ShowLoading {
	my $self  = shift;
	my $value = shift;

	if ($value) {
		$self->{"loadingIndicator"}++;

	}
	else {
		$self->{"loadingIndicator"}--;
	}

	if ( $self->{"loadingIndicator"} > 0 ) {

		$self->{"gauge"}->Show();
	}
	else {
		$self->{"gauge"}->Hide();
	}
}

1;
