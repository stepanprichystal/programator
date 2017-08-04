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
	my $title     = shift;
	my $jobId = shift;
	my @dimension = ( 550, 400 );
	my $self      = $class->SUPER::new( $parent, $title, \@dimension );

	bless($self);

	$self->__SetLayout();

	# Properties
	
	
	$self->{"isPool"} = HegMethods->GetPcbIsPool($jobId);
	
	$self->{"errIndClickEvent"}    = Event->new();
	$self->{"processReorderEvent"} = Event->new();
	 

	return $self;
}

sub SetErrIndicator {
	my $self = shift;
	my $cnt  = shift;

	if ($cnt) {

		$self->{"errInd"}->SetErrorCnt($cnt);

		$self->{"btnLocall"}->Disable();
		$self->{"btnServer"}->Disable();
	}

}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $checks = $self->__SetLayoutChecks( $self->{"mainFrm"} );
	my $info = $self->__SetLayoutInfo( $self->{"mainFrm"} );
	
	$szMain->Add($info, 0, &Wx::wxEXPAND );
	$szMain->Add($checks, 1, &Wx::wxEXPAND );
	
	$self->AddContent($szMain);

	$self->SetButtonHeight(30);

	my $btnText = "Process locally";
	unless($self->{"isPool"}){
		$btnText  .= " + export";
	}


	my $btnLocall = $self->AddButton( $btnText,   sub { $self->{"processReorderEvent"}->Do(Enums->Process_LOCALLY) } );
	my $btnServer = $self->AddButton( "Process on server", sub { $self->{"processReorderEvent"}->Do(Enums->Process_SERVER) } );

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
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $str = "1) Check if manual changes was processed (Change_log.txt)\n";
	$str .= "2) Do automatic tasks (put new schema, zip old files, ...) locally or on server (preferred)\n\n";

	my $infoTxt = Wx::StaticText->new( $statBox, -1, $str, &Wx::wxDefaultPosition, [ -1, -1 ] );

	 
	$szMain->Add( $infoTxt, 0 );
	$szStatBox->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxTOP, 10 );

	# SAVE REFERENCES
	 

	return $szStatBox;
}


sub __SetLayoutChecks {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Manual changes' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $errTxt = Wx::StaticText->new( $statBox, -1, "Not processed:", &Wx::wxDefaultPosition, [ 200, 30 ] );

	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 20, undef, $self->{"jobId"} );

	$errInd->{"onClick"}->Add( sub { $self->__OnErrIndClick(@_) } );

	$szMain->Add( $errTxt, 0 );
	$szMain->Add( $errInd, 0 );
	$szStatBox->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxTOP, 10 );

	# SAVE REFERENCES
	$self->{"errInd"} = $errInd;

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnErrIndClick {
	my $self = shift;

	$self->{"errIndClickEvent"}->Do(@_);
	
	$self->{"btnLocall"}->Enable();
	$self->{"btnServer"}->Enable();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

1;

