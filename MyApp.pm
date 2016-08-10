package MyApp;
use base 'Wx::App';

use strict;
use warnings;
use Wx;

#use aliased 'Wddddidgets::Forms::MyWxFrame';

sub new {
	my $self   = shift;
	my $parent = shift;
	$self = {};

	if ( !defined $parent ) {
		$self = Wx::App->new( \&OnInit );

	}

	bless($self);

	$self->{"windowNumber"} = shift;

	my $mainFrm = Wx::Frame->new(
		$parent,
		-1,
		"My app - ",
		&Wx::wxDefaultPosition, [ 200, 40 ],

		&Wx::wxCLOSE_BOX
	);

	my $button = Wx::Button->new( $mainFrm, -1, "Test btn", );
	Wx::Event::EVT_BUTTON( $button, -1, sub { __OnClick( $self, @_ ) } );

	$mainFrm->Show(1);
	return $self;
}

sub OnInit {
	return 1;
}

sub __OnClick {
	my $self  = shift;
	my $btn   = shift;
	my $event = shift;

	print $self->{"windowNumber"};

	my $max = 100;

	my $dialog = Wx::ProgressDialog->new(
										  'Progress dialog example',
										  'An informative message',
										  $max,
										  undef,
										  &Wx::wxPD_CAN_ABORT | &Wx::wxPD_AUTO_HIDE |
											&Wx::wxPD_APP_MODAL | &Wx::wxPD_ELAPSED_TIME |
											&Wx::wxPD_ESTIMATED_TIME | &Wx::wxPD_REMAINING_TIME
	);

	my $continue;
	foreach my $i ( 1 .. $max ) {
		sleep 1;
		if ( $i == $max ) {
			$continue = $dialog->Update( $i, "That's all, folks!" );
		}
		elsif ( $i == int( $max / 2 ) ) {
			$continue = $dialog->Update( $i, "Only a half left" );
		}
		else {
			$continue = $dialog->Update($i);
		}
		last unless $continue;
	}

}

#my $myApp2 = MyApp->new(2);

my $max = 10;

my $dialog = Wx::ProgressDialog->new(
									  'Progress dialog example',
									  'An informative message',
									  $max,
									  undef,
									  &Wx::wxPD_CAN_ABORT | &Wx::wxPD_AUTO_HIDE |
										&Wx::wxPD_APP_MODAL | &Wx::wxPD_ELAPSED_TIME |
										&Wx::wxPD_ESTIMATED_TIME | &Wx::wxPD_REMAINING_TIME
);

$dialog->Hide();

my $myApp = MyApp->new($dialog);

$dialog->Update( 0, "Only a half left" );

foreach my $i ( 1 .. $max ) {

	sleep 2;

	my $myApp2 = MyApp->new(undef);
	$myApp2->MainLoop;

	$dialog->Update( 0, "Only a half left" );
	print $i. "\n";
}

#$myApp->MainLoop;
