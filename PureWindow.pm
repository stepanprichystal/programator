#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package PureWindow;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;
use Win32::GUI;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Popup';
use aliased 'Packages::Stackup::Stackup::Stackup';

#use aliased 'Managers::AbstractQueue::NotifyMngr::NotifyMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @params = @_;

	my $title     = "My title";
	my $w         = 500;
	my $h         = 700;
	my @dimension = ( $w, $h );

	my $self = $class->SUPER::new( -1, $title, \@dimension, undef );

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

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
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Content definition
	my $content = $self->__SetContentLayout( $self->{"mainFrm"} );

	$self->AddContent($content);

	# Button height
	$self->SetButtonHeight(30);

	# Button definition
	my $btnTest = $self->AddButton( "notify 1", sub { $self->test1(@_) } );

	#	my $btnTest2 = $self->AddButton( "notify 2", sub { $self->test2(@_) } );
	#	my $btnTest3 = $self->AddButton( "test 3",   sub { $self->test3(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

}

sub __SetContentLayout {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'My content' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $ordersTxtXtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	$self->{"textCtrl"} = $ordersTxtXtrl;

	$szStatBox->Add( $ordersTxtXtrl, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );




	use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::AddFileFrm';
	$self->{'quickNoteFrm'} = AddFileFrm->new($parent);

	$self->{'quickNoteFrm'}->{"mainFrm"}->CentreOnParent(&Wx::wxBOTH);
	$self->{'quickNoteFrm'}->{"mainFrm"}->Show();


	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#

sub test1 {
	my $self = shift;

	my $text = $self->{"textCtrl"}->GetValue();

	my $f;
	my $path = "c:\\Export\\test\\test.txt";
	unlink($path);
	open( $f, "+>", $path );

	print $f $text;
	
	close($f);
	
	#.decode('utf-8');

}

sub test2 {
	my $self = shift;

	print STDERR "notify 2\n";

}

sub test3 {
	my $self = shift;

	print STDERR "notify 3\n";
}

sub __OnCheckboxChecked {
	my $self     = shift;
	my $greeting = shift;

	print STDERR "$greeting\n";
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

my $jobId    = "d288054";
my $stepName = "o+1";

#my $layerName = "fstiffs";

my $frm = PureWindow->new( $inCAM, $jobId );
$frm->{"mainFrm"}->Show();
$frm->MainLoop();

die;

1;

