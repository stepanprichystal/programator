#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::View::QuickNoteFrm::QuickNoteFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library

use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::QuickNoteFrm::NoteList';

#tested form

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class     = shift;
	my $parent    = shift;
	my @dimension = ( 500, 600 );
	my $self      = $class->SUPER::new( $parent, "Quick notes", \@dimension );

	bless($self);

	$self->__SetLayout();

	# Properties

	return $self;
}



sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	my $listNote = $self->__SetLayoutList( $self->{"mainFrm"} );

	$self->AddContent($listNote);

	$self->SetButtonHeight(20);

	$self->AddButton( "Reset", sub { $self->__ResetClick(@_) } );
	$self->AddButton( "Ok",    sub { $self->__SetClick(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# Add this rappet to group table

}

sub __SetLayoutList {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Other options' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $noteList = NoteList->new($statBox);

	$szMain->Add( $noteList, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"noteList"} = $noteList;

	return $szStatBox;

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

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

