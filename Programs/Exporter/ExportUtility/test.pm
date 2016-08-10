package Programs::Exporter::test;
use base 'Wx::App';

use threads;
use threads::shared;
use Wx;
use strict;
use warnings;



use Win32::Process::Info;

use Widgets::Style;
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Programs::Exporter::ThreadMngr';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::Exporter::ServerMngr';



sub new {
	my $self   = shift;
	my $parent = shift;
	$self = {};

	unless ($parent) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	my @files = ();
	$self->{"exportFiles"} = \@files;

	$self->{"serverMngr"} = ServerMngr->new();
	$self->{"threadMngr"} = ThreadMngr->new();

	my $mainFrm = $self->__SetLayout($parent);

	#$self->__RunTimers();


	$self->{"mainFrm"} = $mainFrm;

	$mainFrm->Show(1);

	return $self;
}

sub OnInit {
	return 1;
}

sub __SetLayout {

	my $self   = shift;
	my $parent = shift;

	#EVT_NOTEBOOK_PAGE_CHANGED( $self, $nb, $self->can( 'OnPageChanged' ) );

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                   # parent window
		-1,                        # ID -1 means any
		"Exporter",                # title
		&Wx::wxDefaultPosition,    # window position
		[ 700, 700 ],              # size
		                           #&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	#SIZERS
	my $sz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#CONTROLS
	my $txt = Wx::StaticText->new( $mainFrm, -1, "ahoj", &Wx::wxDefaultPosition, [ 300, 200 ] );
	$self->{"txt"} = $txt;

	my $txt2 = Wx::StaticText->new( $mainFrm, -1, "ahoj2", &Wx::wxDefaultPosition, [ 300, 200 ] );
	$self->{"txt2"} = $txt2;

	my $button = Wx::Button->new( $mainFrm, -1, "click" );

	#Wx::Event::EVT_BUTTON( $button, -1, sub { $self->__OnClick($button ) } );

	my $gauge = Wx::Gauge->new( $mainFrm, -1, 100, [ -1, -1 ], [ 300, 20 ], &Wx::wxGA_HORIZONTAL );

	$gauge->SetValue(0);

	$sz->Add( $txt,    1, &Wx::wxEXPAND );
	$sz->Add( $txt2,   1, &Wx::wxEXPAND );
	$sz->Add( $gauge,  1, &Wx::wxEXPAND );
	$sz->Add( $button, 1, &Wx::wxEXPAND );

	$mainFrm->SetSizer($sz);

	$self->{"mainFrm"} = $mainFrm;
	$self->{"gauge"}   = $gauge;

	#EVENTS

	my $EXPORT_DONE_EVT : shared = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $EXPORT_DONE_EVT, sub { $self->__ExportDone(@_) } );

	my $EXPORT_PROGRESS_EVT : shared = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $EXPORT_PROGRESS_EVT, sub { $self->__ExportProgress(@_) } );

	my $EXPORT_MESSAGE_EVT : shared = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $EXPORT_MESSAGE_EVT, sub { $self->__ExportMessage(@_) } );

	$self->{"threadMngr"}->Init( $self->{"mainFrm"}, \$EXPORT_PROGRESS_EVT, \$EXPORT_MESSAGE_EVT, \$EXPORT_DONE_EVT, );

	return $mainFrm;
}

sub Test {
	my $self = shift;

	#	my $EXPORT_DONE_EVT2;
	#	share($EXPORT_DONE_EVT2);
	#	$EXPORT_DONE_EVT2 = Wx::NewEventType;
	#
	#	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $EXPORT_DONE_EVT2, sub { $self->__ExportDone(@_ ) } );
	#
	#
	#
	#
	#	my $m = Programs::Exporter::ThreadMngr->new( );
	#
	#	$m->Init($self->{"mainFrm"},  \$EXPORT_PROGRESS_EVT, \$EXPORT_MESSAGE_EVT, \$EXPORT_DONE_EVT2,);

	$self->{"threadMngr"}->RunNewExport( 1001, "F1234" );

}



sub __ExportDone {
	my ( $self, $frame, $event ) = @_;

	my $data = $event->GetData;

	print "\nDone Method\n";
}

my $app = Programs::Exporter::test->new();

$app->Test();

$app->MainLoop;

1;

