#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::Example::ExampleApp;
use base 'Widgets::Forms::StandardFrm';

use Class::Interface;
&implements('Packages::InCAMHelpers::AppLauncher::IAppLauncher');

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';

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


sleep(5);
	my $inCAM = $launcher->GetInCAM();

	$inCAM->COM("get_user_name");
	my $userName = $inCAM->GetReply();
	print STDERR "Some test answer from incam, user name: " . $userName;
	die "test";
	

	 $launcher->CloseWaitFrm();




}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	$self->SetButtonHeight(30);

	my $btnTest = $self->AddButton( "test", sub { print STDERR "test click\n" } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAMHelpers::AppLauncher::Example::ExampleApp';
	my $frm = ExampleApp->new(-1);

	$frm->LauncherInit();

}

1;

