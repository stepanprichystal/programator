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

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Popup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my @params = @_;

	print STDERR "Parametry:" . join(",", @params);

	my $title     = "Example";
	my $jobId     = "f52456";
	my @dimension = ( 550, 400 );
	my $self      = $class->SUPER::new( -1, $title, \@dimension );

	bless($self);

	$self->__SetLayout();

	# Properties

	return $self;
}

sub Run {
	my $self = shift;

		$self->{"mainFrm"}->Show(1);
	$self->MainLoop();

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

	$self->SetButtonHeight(30);

	my $btnTest = $self->AddButton( "test", sub { $self->test(@_)});

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

}

sub test{
		my $self = shift;
	

	
	print STDERR "test";
	
	use Win32::GUI;

my $desk = Win32::GUI::GetDesktopWindow();
my $dw = Win32::GUI::Width($desk);
my $dh = Win32::GUI::Height($desk);

get window position
	my $popup = Popup->new( $self->{"mainFrm"}   );	
	$popup->Move( 0, 0 );
    $popup->SetSize( 300, 200 );
    $popup->Show;

print "${dw}x$dh\n";
	
	
}


#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#
 

1;

	 
	my $frm = PureWindow->new(-1);
	$frm->Run();

