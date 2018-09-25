#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package PureWindowRVI;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;
use Win32::GUI;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Popup';
#use aliased 'Managers::AbstractQueue::NotifyMngr::NotifyMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my @params = @_;
 
	my $title     = "Untility for transform PDF to drilling parameters";
	my $w         = 400;
	my $h         = 200;
	my @dimension = ( $w, $h );

	my $self = $class->SUPER::new( -1, $title, \@dimension, undef );


	bless($self);

	$self->__SetLayout();
 
	# Properties

	return $self;
}

sub Run {
	my $self = shift;

	$self->{"mainFrm"}->Show(1);

}

sub Init {
	my $self     = shift;
	my $launcher = shift;    # Launcher cobject

}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS


	# Content definition	
	my $content = $self->__SetContentLayout( $self->{"mainFrm"} );
	$self->AddContent($content);


	# Button height
	$self->SetButtonHeight(30);

	# Button definition
	my $btnTest = $self->AddButton( "Transform", sub { $self->transform(@_) } );
	
	

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

}

sub __SetContentLayout {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $mainBox = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szBoxR = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBoxL = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szBoxR = Wx::StaticBox->new( $parent, 1, 'XML to Drilling parameters file' );
	my $szStatBox = Wx::StaticBoxSizer->new( $szBoxR, &Wx::wxDefaultPosition );
	

	# DEFINE CONTROLS
	my $browse = Wx::Button->new( $parent, -1, 'Choose XML file...' , &Wx::wxDefaultPosition, [ 200, 50 ] );
	my $testTxtXtrl = Wx::TextCtrl->new( $szBoxR, -1, "Test", &Wx::wxDefaultPosition );


	# SET EVENTS
	Wx::Event::EVT_BUTTON( $browse, -1, sub { $self->__OnChooseDir() } );

	# BUILD STRUCTURE OF LAYOUT
	
	$szBoxL->Add($browse); 
	$szStatBox->Add( $testTxtXtrl, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	
	
	$mainBox->Add( $szBoxL,    0, &Wx::wxEXPAND | &Wx::wxHORIZONTAL, 0 );
	$mainBox->Add( $szStatBox, 0, &Wx::wxEXPAND | &Wx::wxHORIZONTAL, 0 );
	
	



	# Set References

	$self->{"button"} = $browse;
	

	return $mainBox;
}

sub __OnChooseDir {
	my $self  = shift;

	my $dirDialog = undef;


		$dirDialog = Wx::FileDialog->new( $self->{"mainFrm"}, "Select directory with data", "c:/" );

	if ( $dirDialog->ShowModal() != &Wx::wxID_CANCEL ) {

		my @paths = $dirDialog->GetPaths;
		
		$self->{"path"} = $paths[0];
		$self->{"button"}->SetLabel('File was chosen');
		
	}
}

#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#

sub transform {
	my $self = shift;

 print STDERR $self->{"path"} , "\n";

}


sub __OnCheckboxChecked {
	my $self = shift;
	my $greeting = shift;

	 print STDERR "$greeting\n";
}



#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

1;

