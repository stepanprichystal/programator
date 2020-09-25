#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportCheckerMini::Forms::ExportCheckerMiniForm;
use base 'Widgets::Forms::StandardFrm';

#3th party library
use strict;
use warnings;
use Wx;

#local library
use aliased 'Packages::Tests::Test';
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Packages::Events::Event';
use aliased 'Managers::MessageMngr::MessageMngr';
use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my $jobId = shift;
	my $dim   = shift;

	# Add 70px to height because of progress bar + bottom buttons
	$dim->[1] += 100;

	my $flags =
	   &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX | &Wx::wxRESIZE_BORDER;

	my $self = $class->SUPER::new( $parent, "Exporter checker mini: $jobId", $dim, $flags );

	bless($self);

	# Properties
 
	$self->__SetLayout();
	$self->{"unitForm"} = undef;

	# EVENTS

	# Comment detail events

	$self->{"onExportEvt"} = Event->new();
	$self->{"onCloseEvt"}  = Event->new();

	return $self;
}

sub SetGroup {
	my $self     = shift;
	my $unitForm = shift;
	
	$self->{"unitForm"} = $unitForm;

	$self->{"mainFrm"}->Freeze();

	$self->{"szUnit"}->Add( $unitForm, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->{"mainFrm"}->Thaw();
}

sub ShowGauge {
	my $self = shift;
	my $val = shift;
	
	if($val){
		 
		$self->{"gauge"}->SetValue(100);
		$self->{"gauge"}->Pulse();
		$self->{"unitForm"}->Disable();
	 
	}else{
		
		$self->{"gauge"}->SetValue(0);
		#$self->{"gauge"}->Pulse();
		$self->{"unitForm"}->Enable();
	
	}
	
	 
}

sub GetMessageMngr {
	my $self = shift;

	return $self->_GetMessageMngr();
}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	$self->SetButtonHeight(30);
	my $btnPreview = $self->AddButton( "Export", sub { $self->{"onExportEvt"}->Do() } );
	#my $statusTxt = Wx::TextCtrl->new( $self->{"mainFrm"}, -1, "Status bar...", &Wx::wxDefaultPosition, [ -1, 40 ] );
	my $gauge = Wx::Gauge->new( $self->{"mainFrm"}, -1, 100, [ -1, -1 ], [ -1, 20 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);
	#$gauge->Pulse();
	 
	#$statusTxt->SetForegroundColour( Wx::Colour->new( 255, 255, 255 ) );
	#$statusTxt->SetBackgroundColour( Wx::Colour->new( 127, 127, 127 ) );

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szUnit = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	$self->AddContent($szMain);

	# DEFINE LAYOUT STRUCTURE
	$szMain->Add( $szUnit,    1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $gauge, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# ADD EVENTS
	$self->{"mainFrm"}->{"onClose"}->Add( sub { $self->{"onCloseEvt"}->Do(); } );

	# KEEP REFERENCES
	$self->{"szUnit"}    = $szUnit;
	$self->{"gauge"} = $gauge;

}

#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

