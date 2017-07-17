#-------------------------------------------------------------------------------------------#
# Description:Programs::Stencil::StencilDrawing Popup, which shows result from export checking
# Allow terminate thread, which does checking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::StencilFrm;
use base 'Wx::App';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
 
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::StencilCreator::Forms::StencilDrawing';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $self   = shift;
	my $parent = shift;
	my $inCAM= shift;
	my $jobId = shift;
	$self = {};

	if ( !defined $parent || $parent == -1 ) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);
	
	# Properties
	$self->{"inCAM"} =  $inCAM;
	$self->{"jobId"} =  $jobId;
	
	

	# Load layer data, dimension etc
	my $pasteL = grep {$_->{"gROWname"} =~ /^s[ab][-] } CamJob->GetAllLayers($inCAM, $jobId);


	my $mainFrm = $self->__SetLayout($parent);

	

	$mainFrm->Show();

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}



sub __SetLayout {
	my $self   = shift;
	my $parent = shift;

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                       # parent window
		-1,                            # ID -1 means any
		"Checking export settings",    # title
		&Wx::wxDefaultPosition,        # window position
		[ 800, 800 ]                  # size
		 
	);

		#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szColInner = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $gerbers  = $self->__SetLayoutGerbers($self);
	my $mdi      = $self->__SetLayoutMDI($self);
	my $jetPrint = $self->__SetLayoutJetprint($self);
	my $paste    = $self->__SetLayoutPaste($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#my $pnl = Wx::Panel->new( $mainFrm, -1, [50, 50],  [400, 400] );
	#$szMain->Add($pnl,  0,  &Wx::wxALL, 0);

	#
	use aliased 'Programs::Stencil::StencilDrawing';
	my @dim = ( 400, 400 );
	$self->{"drawingPnl"} = StencilDrawing->new( $mainFrm, \@dim );

	my $btn = Wx::Button->new( $mainFrm, -1, "test", &Wx::wxDefaultPosition );

	Wx::Event::EVT_BUTTON( $btn, -1, sub { $self->Test(@_) } );

	$szMain->Add( $self->{"drawingPnl"}, 0, &Wx::wxALL, 100 );
	$szMain->Add( $btn,                  0, &Wx::wxALL, 0 );

	$self->{"cnt"} = 0;
	#
	#
	#
	#	my $layerTest = $d->AddLayer("test");
	#	$layerTest->SetBrush( Wx::Brush->new( 'gray',&Wx::wxBRUSHSTYLE_FDIAGONAL_HATCH ) );
	#	$layerTest->DrawRectangle( 100,100, 200,200 );

	#Wx::Event::EVT_PAINT($self,\&paint);

	$mainFrm->SetSizer($szMain);
	$mainFrm->Layout();

	$self->{"mainFrm"} = $mainFrm;

	$self->{"mainFrm"}->Show(1);

	return $mainFrm;
}


# Set layout for Jetprint
sub __SetLayoutGeneral {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'General' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Type", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Type", &Wx::wxDefaultPosition, [ 120, 22 ] );

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb = Wx::ComboBox->new( $statBox, -1, $last, &Wx::wxDefaultPosition, [ 70, 22 ], \@steps, &Wx::wxCB_READONLY );



	my $exportChb   = Wx::CheckBox->new( $statBox, -1, "Export",          &Wx::wxDefaultPosition );
	my $fiduc3p2Chb = Wx::CheckBox->new( $statBox, -1, "Fiduc holes 3.2mm", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportChb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $fiduc3p2Chb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportJetprintChb"}   = $exportChb;
	$self->{"fiduc3p2Chb"} = $fiduc3p2Chb;

	return $szStatBox;
}



sub Test {
	my ( $self, $event ) = @_;

	$self->{"cnt"}++;
	#
	#	my $layerTest = $self->{"drawingPnl"}->AddLayer("test");
	#
	#	$layerTest->SetBrush( Wx::Brush->new( 'green',&Wx::wxBRUSHSTYLE_CROSSDIAG_HATCH    ) );
	#	my @arr = (Wx::Point->new(10, 10 ), Wx::Point->new(20, 20 ), Wx::Point->new(40, 20 ), Wx::Point->new(40, -10 ));
	#	$layerTest->DrawRectangle( 20, 20,  500,100 );

	#my $max = $layerTest->MaxX();
	#print $max
	 
	$self->{"drawingPnl"}->SetStencilSize( 100, 100 );

	$self->{"drawingPnl"}->SetTopPcbPos( 100, 100, 500 + $self->{"cnt"} * 10, 200 );
	

}

#sub paint {
#	my ( $self, $event ) = @_;
#	#my $dc = Wx::PaintDC->new( $self->{frame} );
#
#
#   $self->{"dc"} = Wx::ClientDC->new( $self->{"mainFrm"} );
#  $self->{"dc"}->SetBrush( Wx::Brush->new( 'gray',&Wx::wxBRUSHSTYLE_FDIAGONAL_HATCH ) );
#  $self->{"dc"}->DrawRectangle( 100,100, 200,200 );
#
#
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my $test = Drawing->new( -1, "f13610" );

# $test->Test();
$test->MainLoop();

1;

