#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::Forms::ReorderAppFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class     = shift;
	my $parent    = shift;
	 
	my $jobId     = shift;
	my $orders = shift;
	
	my @dimension = ( 510, 370 );
	my $flags = &Wx::wxSTAY_ON_TOP | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION  | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX;
	
	my $self      = $class->SUPER::new( $parent, "Reorder app - $jobId", \@dimension, $flags );

	bless($self);

	# Properties

	$self->{"isPool"} = HegMethods->GetPcbIsPool($jobId);
	$self->{"orders"} = $orders;
	
	$self->__SetLayout();
		
	# Events	

	$self->{"errIndClickEvent"}       = Event->new();
	$self->{"errCriticIndClickEvent"} = Event->new();
	$self->{"processReorderEvent"}    = Event->new();

	return $self;
}

sub SetErrIndicator {
	my $self = shift;
	my $cnt  = shift;

	if ($cnt) {

		$self->{"errInd"}->SetErrorCnt($cnt);

	}

}

sub EnableBtnServer {
	my $self = shift;
	my $val  = shift;

	if ($val) {

		$self->{"btnServer"}->Enable();
	}
	else {
		$self->{"btnServer"}->Disable();
	}
}

sub EnableBtnLocall {
	my $self = shift;
	my $val  = shift;

	if ($val) {

		$self->{"btnLocall"}->Enable();
	}
	else {
		$self->{"btnLocall"}->Disable();
	}
}

sub SetErrCriticIndicator {
	my $self = shift;
	my $cnt  = shift;

	if ($cnt) {
		$self->{"errCriticalInd"}->SetErrorCnt($cnt);

	}

}

sub SetGaugeVal {
	my $self = shift;
	my $val  = shift;
	
	$val = int($val);
	
	print STDERR $val."\n";

	$self->{"gauge"}->SetValue($val);
	$self->{"progressTxt"}->SetLabel($val."%");
}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $checks = $self->__SetLayoutChecks( $self->{"mainFrm"} );
	my $info   = $self->__SetLayoutInfo( $self->{"mainFrm"} );

	$szMain->Add( $info,   0, &Wx::wxEXPAND );
	$szMain->Add( 5,   5, &Wx::wxEXPAND );
	$szMain->Add( $checks, 1, &Wx::wxEXPAND );

	$self->AddContent($szMain);

	$self->SetButtonHeight(30);

	my $btnText = "Process locally";
	unless ( $self->{"isPool"} ) {
		$btnText .= " + export";
	}

	my $btnLocall = $self->AddButton( $btnText,            sub { $self->{"processReorderEvent"}->Do( Enums->Process_LOCALLY ) } );
	my $btnServer = $self->AddButton( "Process on server", sub { $self->{"processReorderEvent"}->Do( Enums->Process_SERVER ) } );
	
	$btnLocall->Disable();
	$btnServer->Disable();
	
	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

	$self->{"btnLocall"} = $btnLocall;
	$self->{"btnServer"} = $btnServer;

}

sub __SetLayoutInfo {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Info' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $str = "1) Check if manual changes was processed (Change_log.txt)\n";
	$str .= "2) Process job (zip old files, export ...) locally or on server";

	my $infoTxt = Wx::StaticText->new( $statBox, -1, $str, &Wx::wxDefaultPosition, [ -1, -1 ] );
	
	my $ordersText = "Affected re-orders:\n\n";
	$ordersText .= join("\n", map { " - ".$_->{"reference_subjektu"}." - ". $_->{"aktualni_krok"}} @{$self->{"orders"}}); 
	
	my $infoOrdersTxt = Wx::StaticText->new( $statBox, -1, $ordersText, &Wx::wxDefaultPosition, [ -1, -1 ] );

	$szMain->Add( $infoTxt, 0 );
	$szMain->Add( 15,15, 0 );
	$szMain->Add( $infoOrdersTxt, 0 );
	$szMain->Add( 10,10, 0 );
	$szStatBox->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxTOP, 5 );

	# SAVE REFERENCES

	return $szStatBox;
}

sub __SetLayoutChecks {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Manual changes' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $errTxt = Wx::StaticText->new( $statBox, -1, "Not processed:", &Wx::wxDefaultPosition, [ 200, 30 ] );

	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 20, undef, $self->{"jobId"} );

	my $errCriticalTxt = Wx::StaticText->new( $statBox, -1, "Not processed - critical:", &Wx::wxDefaultPosition, [ 200, 30 ] );

	my $errCriticalInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 20, undef, $self->{"jobId"} );

	my $progressTxt = Wx::StaticText->new( $statBox, -1, "0%", &Wx::wxDefaultPosition, [ 30, 30 ] );

	my $gauge = Wx::Gauge->new( $statBox, -1, 100, [ -1, -1 ], [ -1, 20 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	$errInd->{"onClick"}->Add( sub { $self->{"errIndClickEvent"}->Do(@_) } );
	$errCriticalInd->{"onClick"}->Add( sub {$self->{"errCriticIndClickEvent"}->Do(@_) } );

	$szRow1->Add( $errTxt, 0 );
	$szRow1->Add( $errInd, 0 );

	$szRow2->Add( $errCriticalTxt, 0 );
	$szRow2->Add( $errCriticalInd, 0 );

	$szRow3->Add( $gauge, 1 );
	$szRow3->Add( $progressTxt,  0, &Wx::wxLEFT, 5 );
	
	$szStatBox->Add( 10, 10 );
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND |&Wx::wxALL, 1 );
	$szStatBox->Add( $szRow2, 0,  &Wx::wxEXPAND |&Wx::wxALL, 1 );
	 $szStatBox->Add( 10, 10, 1 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# SAVE REFERENCES
	$self->{"errInd"}         = $errInd;
	$self->{"errCriticalInd"} = $errCriticalInd;
	$self->{"progressTxt"}    = $progressTxt;
	$self->{"gauge"}          = $gauge;

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

1;

