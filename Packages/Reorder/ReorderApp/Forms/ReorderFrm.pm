#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::Forms::ReorderFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class     = shift;
	my $parent    = shift;
	my $title = shift;
	my @dimension = ( 400, 300 );
	my $self      = $class->SUPER::new( $parent, $title, \@dimension );

	bless($self);

	$self->__SetLayout();

	# Properties
	$self->{"errIndClickEvent"} = Event->new();
	$self->{"processLocallyEvent"} = Event->new();
	$self->{"processServerEvent"} = Event->new();
	
	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	my $content = $self->__SetLayoutContent( $self->{"mainFrm"} );

	$self->AddContent($content);

	$self->SetButtonHeight(30);

	$self->AddButton( "Process locally",   sub { $self->{"processLocallyEvent"}->Do(@_) } );
	$self->AddButton( "Process on server", sub { $self->{"processServerEvent"}->Do(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# Add this rappet to group table

}

sub __SetLayoutContent {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Manual changes' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $errTxt = Wx::StaticText->new( $statBox, -1, "Errors", &Wx::wxDefaultPosition, [ -1, 20 ] );

	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 20, undef, $self->{"jobId"} );

	$errInd->{"onClick"}->Add( sub { $self->{"errIndClickEvent"}->Do(@_) } );

	$szMain->Add( $errTxt, 0  );
	$szMain->Add( $errInd, 1 );
	$szStatBox->Add( $szMain, 0, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"errInd"} = $errInd;

	return $szStatBox;
}

sub __OnErrIndClick {

	print STDERR "Test";
}

sub __SetClick {
	my $self = shift;

	$self->{"mainFrm"}->Hide();

}

sub __ResetClick {
	my $self = shift;

	$self->{"noteList"}->UnselectAll();
	$self->{"mainFrm"}->Hide();

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetNotesData {
	my $self = shift;
	my $data = shift;

	$self->{"noteList"}->SetNotesData($data);

}

sub GetNotesData {
	my $self = shift;

	return $self->{"noteList"}->GetNotesData();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

 
1;

