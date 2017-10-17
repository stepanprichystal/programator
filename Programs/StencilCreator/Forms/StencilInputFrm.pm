#-------------------------------------------------------------------------------------------#
# Description:Programs::Stencil::StencilDrawing Popup, which shows result from export checking
# Allow terminate thread, which does checking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::StencilInputFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;

use Wx;
use aliased 'Packages::Events::Event';

#local library

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::StencilCreator::Forms::StencilDrawing';
use aliased 'Programs::StencilCreator::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Programs::StencilCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my @dimension = ( 400, 400 );
	my $self = $class->SUPER::new( $parent, "Stencil input", \@dimension );

	bless($self);

	# Properties
	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	# Events

	$self->__SetLayout();

	$self->{"mainFrm"}->Show(1);

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Layout methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	#define panels
	my $pnlMain = Wx::Panel->new( $self->{"mainFrm"}, -1 );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $general = $self->__SetLayoutGeneral($pnlMain);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $general, 0, &Wx::wxALL, 1 );

	$pnlMain->SetSizer($szMain);

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(30);

	$self->AddButton( "Ok", sub { $self->__Input(@_) } );

	$self->{"szMain"} = $szMain;

}

# Set layout general group
sub __SetLayoutGeneral {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'General' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Source", &Wx::wxDefaultPosition, [ 170, 22 ] );

	my @types = ();
	push( @types, "Existing job" );
	push( @types, "Customer data" );

	my $typeCb = Wx::ComboBox->new( $statBox, -1, $types[0], &Wx::wxDefaultPosition, [ 120, 22 ], \@types, &Wx::wxCB_READONLY );

	my $jobIdTxt = Wx::StaticText->new( $statBox, -1, "Job id", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $jobIdValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 60, 22 ] );

	my $btnR = Wx::Button->new( $statBox, -1, "Choose dir (r:pcb)", &Wx::wxDefaultPosition, [ 120, 25 ] );
	my $btnC = Wx::Button->new( $statBox, -1, "Choose dir (c:pcb)", &Wx::wxDefaultPosition, [ 120, 25 ] );

	#    if( $dialog->ShowModal == wxID_CANCEL ) {
	#        Wx::LogMessage( "User cancelled the dialog" );
	#    } else {
	#        Wx::LogMessage( "Wildcard: %s", $dialog->GetWildcard);
	#        my @paths = $dialog->GetPaths;
	#
	#        if( @paths > 0 ) {
	#            Wx::LogMessage( "File: $_" ) foreach @paths;
	#        } else {
	#            Wx::LogMessage( "No files" );
	#        }
	#
	#        $self->previous_directory( $dialog->GetDirectory );

	# SET EVENTS
	Wx::Event::EVT_TEXT( $typeCb, -1, sub { $self->__OnSourceChanged(@_) } );
	Wx::Event::EVT_BUTTON( $btnR, -1, sub { $self->__OnChooseDir("r") } );
	Wx::Event::EVT_BUTTON( $btnC, -1, sub { $self->__OnChooseDir("c") } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $typeTxt, 0, &Wx::wxALL, 1 );
	$szRow1->Add( $typeCb,  0, &Wx::wxALL, 1 );

	$szRow2->Add( $jobIdTxt,    0, &Wx::wxALL, 1 );
	$szRow2->Add( $jobIdValTxt, 0, &Wx::wxALL, 1 );

	$szRow3->Add( $btnR, 0, &Wx::wxALL, 1 );
	$szRow3->Add( $btnC, 0, &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"stencilTypeCb"} = $typeCb;
	$self->{"jobIdTxt"}      = $jobIdTxt;

	$self->{"jobIdValTxt"} = $jobIdValTxt;
	$self->{"btnR"}        = $btnR;
	$self->{"btnC"}        = $btnC;
	$self->{"szRow2"}      = $szRow2;

	$self->__DisableControls();

	return $szStatBox;
}

sub __Input {
	my $self = shift;

}

sub __OnSourceChanged {
	my $self = shift;

	$self->__DisableControls();
}

sub __OnChooseDir {
	my $self  = shift;
	my $place = shift;    #c/r
	
	my $dirDialog = undef;
	
	if ( $place eq "r" ) {

		$dirDialog = Wx::DirDialog->new( $self->{"mainFrm"}, "Select directory with data", "r:/pcb", &Wx::wxDD_DEFAULT_STYLE | &Wx::wxDD_DIR_MUST_EXIST );
 
	}
	elsif ( $place eq "c" ) {

		$dirDialog = Wx::DirDialog->new( $self->{"mainFrm"}, "Select directory with data", "c:/pcb", &Wx::wxDD_DEFAULT_STYLE | &Wx::wxDD_DIR_MUST_EXIST );
 
	}
	
	if( $dirDialog->ShowModal() != &Wx::wxID_CANCEL ) {
			
			print STDERR $dirDialog->GetPath();
	}

}

sub __DisableControls {
	my $self = shift;

	if ( $self->{"stencilTypeCb"}->GetSelection() == 0 ) {

		$self->{"jobIdValTxt"}->Show();
		$self->{"jobIdTxt"}->Show();
		$self->{"btnR"}->Hide();
		$self->{"btnC"}->Hide();

	}
	else {

		$self->{"jobIdValTxt"}->Hide();
		$self->{"jobIdTxt"}->Hide();
		$self->{"btnR"}->Show();
		$self->{"btnC"}->Show();

	}

	$self->{"mainFrm"}->Layout();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::StencilCreator::Forms::StencilInputFrm';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $test = StencilInputFrm->new( -1, $inCAM, "f13610" );

	# $test->Test();
	$test->MainLoop();

}

1;

