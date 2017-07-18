#-------------------------------------------------------------------------------------------#
# Description:Programs::Stencil::StencilDrawing Popup, which shows result from export checking
# Allow terminate thread, which does checking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::StencilFrm;
use base 'Widgets::Forms::StandardFrm';

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

	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my @dimension = ( 800, 800 );
	my $self = $class->SUPER::new( $parent, "Quick notes", \@dimension );

	bless($self);

	# Properties
	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	# Load layer data, dimension etc
 
	return $self;
}

# Set data necessary for proper GUI loading
sub Init {
	my $self      = shift;
	my $stepsSize = shift;
	my $steps     = shift;
	my $saExist   = shift;
	my $sbExist   = shift;

	$self->{"stepsSize"} = $stepsSize;
	$self->{"steps"}     = $steps;
	$self->{"topExist"}  = $saExist;
	$self->{"botExist"}  = $sbExist;
	
	$self->__SetLayout();
}

sub OnInit {
	my $self = shift;

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub GetStencilType {
	my $self = shift;

	my $tVal = $self->{"stencilTypeCb"}->GetValue();
	my ( %topPcb, %botPcb ) = ( "exist" => 0 );

	my $result = undef;

	if ( $tVal =~ /top/i && $tVal =~ /bot/i ) {

		$result = "both";

	}
	elsif ( $tVal =~ /top/i ) {

		$result = "top";

	}
	elsif ( $tVal =~ /bot/i ) {

		$result = "bot";
	}

	return $result;
}

sub SetStencilType {
	my $self = shift;
	my $type = shift;
	if ( $type eq "top" ) {

		$self->{"stencilTypeCb"}->SetValue("Top");
	}
	elsif ( $type eq "bot" ) {

		$self->{"stencilTypeCb"}->SetValue("Bot");
	}
	elsif ( $type eq "Top + Bot" ) {

		$self->{"stencilTypeCb"}->SetValue("Bot");
	}
}

sub GetStencilSize {
	my $self = shift;

	my %size = ( "width" => 0, "height" => 0 );

	my $sVal = $self->{"sizeCb"}->GetValue();

	if ( $sVal =~ /custom/ ) {

		$size{"width"}  = $self->{"sizeXTextCtrl"};
		$size{"height"} = $self->{"sizeYTextCtrl"};

	}
	else {

		( $size{"width"}, $size{"height"} ) = $sVal =~ /(\d+)mm\s*x\s*(\d+)mm/i;
	}

	return %size;
}

sub SetStencilSize {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	# "300mm x 480mm", "300mm x 520mm", "custom"

	if ( $width = 300 && $height = 400 ) {
		$self->{"sizeCb"}->SetValue("300mm x 480mm");
	}
	elsif ( $width = 300 && $height = 520 ) {
		$self->{"sizeCb"}->SetValue("300mm x 520mm");
	}
	else {
		$self->{"sizeCb"}->SetValue("custom");
		$self->{"sizeXTextCtrl"} = $width;
		$self->{"sizeYTextCtrl"} = $height;
	}
}

sub GetStencilStep {
	my $self = shift;

	return $self->{"stepCb"}->GetValue();
}

sub SetStencilStep {
	my $self = shift;
	my $step = shift;
	$self->{"stepCb"}->SetValue($step);
}

sub GetSpacing {
	my $self = shift;

	return $self->{"spacingCtrl"}->GetValue();
}

sub SetSpacing {
	my $self = shift;
	my $spacing = shift;
	
	$self->{"spacingCtrl"}->SetValue($spacing);
}

# 1 - profile2profile
# 2- pad2pad
sub GetSpacingType {
	my $self = shift;

	

	return $self->{"spacingTypeCb"}->GetSelection();
}

# 1 - profile2profile
# 2- pad2pad
sub SetSpacingType {
	my $self = shift;
	my $type = shift;
	
	$self->{"spacingTypeCb"}->SetSelection($type, $type);
}
#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnDataChanged {
	my $self = shift;

	$self->{"drawing"}->DataChanged($self->__PrepareDrawData());
}

sub __PrepareDrawData {
	my $self = shift;

	my %d = ();

	# Type of stencil
	my $typeVal = $self->GetStencilType();
	my ( %topPcb, %botPcb ) = ( "exist" => 0 );

	$d{"topPcb"} = \%topPcb;
	$d{"botPcb"} = \%botPcb;

	if ( $typeVal =~ /top/i ) {
		$d{"topPcb"}{"exists"} = 1;
	
	}elsif ( $typeVal =~ /bot/i ) {
		$d{"botPcb"}{"exist"} = 1;
	
	}elsif( $typeVal =~ /both/i ) {
		$d{"topPcb"}{"exists"} = 1;
		$d{"botPcb"}{"exists"} = 1;
	}

	# Size of stencil
	my %size = $self->GetStencilSize();
	$d{"width"}  = $size{"width"};
	$d{"height"} = $size{"height"};

	# Step
	$d{"step"} = $self->GetStencilStep();

	# Set profile and data size TOP + BOT
	if ( $d{"topPcb"}{"exists"} ) {
		$d{"topPcb"}->{"w"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"width"};
		$d{"topPcb"}->{"h"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"width"};
		$d{"topPcb"}->{"wData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"top"}->{"width"};
		$d{"topPcb"}->{"hData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"top"}->{"width"};
	}

	if ( $d{"botPcb"}{"exists"} ) {
		$d{"botPcb"}->{"w"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"width"};
		$d{"botPcb"}->{"h"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"width"};
		$d{"botPcb"}->{"wData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"bot"}->{"width"};
		$d{"botPcb"}->{"hData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"bot"}->{"width"};
	}

	# Compute positons of paste profile, siye
	my $spacing = $self->GetSpacing();
	my $spacingType = $self->GetSpacingType();
 
 	# profile to profile
 	if($spacingType == 0){
 		my $posX =  ($d{"width"} - $d{"topPcb"}->{"w"}) /2;
 
 		# compute position with actual spacing
 		if ( $typeVal eq "both") {
 
 			$d{"topPcb"}->{"posX"} = ($d{"width"} - $d{"topPcb"}->{"w"}) /2;
 			$d{"topPcb"}->{"posY"} = $d{"height"}/2 + $spacing/2;
 			$d{"topPcb"}->{"posX"} = ($d{"width"} - $d{"topPcb"}->{"w"}) /2;
 			$d{"topPcb"}->{"posY"} = $d{"height"}/2 - ($spacing/2 +$d{"botPcb"}->{"h"});
 			
 		}
 		# centre pcb vertical
 		elsif($typeVal eq "top"){
 			
 			$d{"topPcb"}->{"posX"} = ($d{"width"} - $d{"topPcb"}->{"w"}) /2;
 			$d{"topPcb"}->{"posY"} = $d{"height"}/2 - ($d{"topPcb"}->{"h"} /2);
 			
 		}elsif($typeVal eq "bot"){
 			
 			$d{"botPcb"}->{"posX"} = ($d{"width"} - $d{"botPcb"}->{"w"}) /2;
 			$d{"botPcb"}->{"posY"} = $d{"height"}/2 - ($d{"botPcb"}->{"h"} /2);
 		}
 	}
 
	 return \%d;
}

sub __PrepareClick {
	my $self = shift;
#
#	if ( $size{"width"} !~ /\d+/ || $size{"width"} = 0 ) {
#		die "wrong stencil X size";
#	}
#	if ( $size{"height"} !~ /\d+/ || $size{"height"} = 0 ) {
#		die "wrong stencil Y size";
#	}
}

#-------------------------------------------------------------------------------------------#
#  Layout methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self   = shift;
 
 
	#define panels
	my $pnlMain = Wx::Panel->new( $self->{"mainFrm"}, -1 );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szcol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $general = $self->__SetLayoutGeneral($pnlMain);
	my $schema  = $self->__SetLayoutSchema($pnlMain);
	my $other   = $self->__SetLayoutOther($pnlMain);

	my $drawing = $self->__SetLayoutDrawing($pnlMain);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szcol1->Add( $general, 0, &Wx::wxALL, 0 );
	$szcol1->Add( $schema,  0, &Wx::wxALL, 0 );
	$szcol1->Add( $other,   1, &Wx::wxALL, 0 );

	$szMain->Add( $szcol1,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $drawing, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	
	$pnlMain->SetSizer($szMain);

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(30);

	$self->AddButton( "Prepare stencil", sub { $self->__PrepareClick(@_) } );

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
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Type", &Wx::wxDefaultPosition, [ 120, 22 ] );

	my @types = ();
	push( @types, "Top" )       if ( $self->{"topExist"} );
	push( @types, "Bot" )       if ( $self->{"botExist"} );
	push( @types, "Top + Bot" ) if ( $self->{"topExist"} && $self->{"botExist"} );
	my $stencilTypeCb = Wx::ComboBox->new( $statBox, -1, $types[0], &Wx::wxDefaultPosition, [ 70, 22 ], \@types, &Wx::wxCB_READONLY );

	my $stepTxt = Wx::StaticText->new( $statBox, -1, "Step", &Wx::wxDefaultPosition, [ 120, 22 ] );

	my $stepCb = Wx::ComboBox->new( $statBox, -1, $self->{"steps"}->[0], &Wx::wxDefaultPosition, [ 70, 22 ], $self->{"steps"}, &Wx::wxCB_READONLY );

	my $sizeTxt = Wx::StaticText->new( $statBox, -1, "Size", &Wx::wxDefaultPosition, [ 120, 22 ] );

	my @sizes = ();
	push( @sizes, "300mm x 480mm", "300mm x 520mm", "custom" );
	my $sizeCb = Wx::ComboBox->new( $statBox, -1, $sizes[0], &Wx::wxDefaultPosition, [ 70, 22 ], \@sizes, &Wx::wxCB_READONLY );

	my $customSize = Wx::StaticText->new( $statBox, -1, "Custom size", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $sizeXTextCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );
	my $sizeYTextCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	# SET EVENTS
	Wx::Event::EVT_TEXT( $stencilTypeCb, -1, sub { $self->__OnDataChanged(@_) } );
	Wx::Event::EVT_TEXT( $stepCb,        -1, sub { $self->__OnDataChanged(@_) } );
	Wx::Event::EVT_TEXT( $sizeXTextCtrl, -1, sub { $self->__OnDataChanged(@_) } );
	Wx::Event::EVT_TEXT( $sizeYTextCtrl, -1, sub { $self->__OnDataChanged(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $typeTxt,       0, &Wx::wxALL, 1 );
	$szRow1->Add( $stencilTypeCb, 0, &Wx::wxALL, 1 );

	$szRow2->Add( $stepTxt, 0, &Wx::wxALL, 1 );
	$szRow2->Add( $stepCb,  0, &Wx::wxALL, 1 );

	$szRow3->Add( $sizeTxt, 0, &Wx::wxALL, 1 );
	$szRow3->Add( $sizeCb,  0, &Wx::wxALL, 1 );

	$szRow4->Add( $customSize,    0, &Wx::wxALL, 1 );
	$szRow4->Add( $sizeXTextCtrl, 0, &Wx::wxALL, 1 );
	$szRow4->Add( $sizeYTextCtrl, 0, &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow4, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"stencilTypeCb"} = $stencilTypeCb;
	$self->{"stepCb"}        = $stepCb;
	$self->{"sizeCb"}        = $sizeCb;
	$self->{"sizeXTextCtrl"} = $sizeXTextCtrl;
	$self->{"sizeYTextCtrl"} = $sizeYTextCtrl;

	return $szStatBox;
}

# Set layout general group
sub __SetLayoutSchema {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Schema' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

		my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	#	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	#	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	#	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	#
	#	# DEFINE CONTROLS
	#
		my $typeTxt = Wx::StaticText->new( $statBox, -1, "Type", &Wx::wxDefaultPosition, [ 120, 22 ] );
	#
	#	my @types = ();
	#	push( @types, "Top" )       if ( $self->{"topExist"} );
	#	push( @types, "Bot" )       if ( $self->{"botExist"} );
	#	push( @types, "Top + Bot" ) if ( $self->{"topExist"} && $self->{"botExist"} );
	#	my $stencilTypeCb = Wx::ComboBox->new( $statBox, -1, -1, &Wx::wxDefaultPosition, [ 70, 22 ], \@types, &Wx::wxCB_READONLY );
	#
	#	my $stepTxt = Wx::StaticText->new( $statBox, -1, "Step", &Wx::wxDefaultPosition, [ 120, 22 ] );
	#
	#	my @steps = ();
	#	push( @steps, "mpanel" ) if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "mpanel" ) );
	#	push( @steps, "o+1" )    if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "o+1" ) );
	#	my $stepCb = Wx::ComboBox->new( $statBox, -1, -1, &Wx::wxDefaultPosition, [ 70, 22 ], \@steps, &Wx::wxCB_READONLY );
	#
	#	my $sizeTxt = Wx::StaticText->new( $statBox, -1, "Size", &Wx::wxDefaultPosition, [ 120, 22 ] );
	#
	#	my @sizes = ();
	#	push( @sizes, "300mm x 480mm", "300mm x 520mm", "custom" ) my $sizeCb =
	#	  Wx::ComboBox->new( $statBox, -1, -1, &Wx::wxDefaultPosition, [ 70, 22 ], \@sizes, &Wx::wxCB_READONLY );
	#
	#	my $customSize = Wx::StaticText->new( $statBox, -1, "Custom size", &Wx::wxDefaultPosition, [ 120, 22 ] );
	#	my $sizeXTextCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );
	#	my $sizeYTextCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );
	#
	#	# SET EVENTS
	#	Wx::Event::EVT_TEXT( $typeCb,        -1, sub { $self->__OnDataChanged(@_) } );
	#	Wx::Event::EVT_TEXT( $stepCb,        -1, sub { $self->__OnDataChanged(@_) } );
	#	Wx::Event::EVT_TEXT( $sizeXTextCtrl, -1, sub { $self->__OnDataChanged(@_) } );
	#	Wx::Event::EVT_TEXT( $sizeYTextCtrl, -1, sub { $self->__OnDataChanged(@_) } );
	#
	#	# BUILD STRUCTURE OF LAYOUT
	#
		$szRow1->Add( $typeTxt,       0, &Wx::wxALL, 1 );
	#	$szRow1->Add( $stencilTypeCb, 0, &Wx::wxALL, 1 );
	#
	#	$szRow2->Add( $stepTxt, 0, &Wx::wxALL, 1 );
	#	$szRow2->Add( $stepCb,  0, &Wx::wxALL, 1 );
	#
	#	$szRow3->Add( $sizeTxt, 0, &Wx::wxALL, 1 );
	#	$szRow3->Add( $sizeCb,  0, &Wx::wxALL, 1 );
	#
	#	$szRow4->Add( $customSize,    0, &Wx::wxALL, 1 );
	#	$szRow4->Add( $sizeXTextCtrl, 0, &Wx::wxALL, 1 );
	#	$szRow4->Add( $sizeYTextCtrl, 0, &Wx::wxALL, 1 );
	#
		$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#	$szStatBox->Add( $szRow4, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#
	#	# Set References
	#	$self->{"stencilTypeCb"} = $stencilTypeCb;
	#	$self->{"stepCb"}        = $stepCb;
	#	$self->{"sizeCb"}        = $sizeCb;
	#	$self->{"sizeXTextCtrl"} = $sizeXTextCtrl;
	#	$self->{"sizeYTextCtrl"} = $sizeYTextCtrl;

	return $szStatBox;
}

# Set layout general group
sub __SetLayoutOther {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Other' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	
	# DEFINE CONTROLS

	my $spacingTypeTxt  = Wx::StaticText->new( $statBox, -1, "Spacing type", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my @types = ("Profile to profile", "Pad to pad"); 
	my $spacingTypeCb   = Wx::ComboBox->new( $statBox, -1, $types[0], &Wx::wxDefaultPosition, [ 70, 22 ], \@types, &Wx::wxCB_READONLY );

	my $spacingTxt  = Wx::StaticText->new( $statBox, -1, "Spacing", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $spacingCtrl = Wx::TextCtrl->new( $statBox, -1, 90,        &Wx::wxDefaultPosition, [ 120, 22 ] );

	my $centerTxt = Wx::StaticText->new( $statBox, -1, "Center data", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $centerChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	# SET EVENTS
	Wx::Event::EVT_TEXT( $spacingCtrl, -1, sub { $self->__OnDataChanged(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $spacingTypeTxt,  0, &Wx::wxALL, 1 );
	$szRow1->Add( $spacingTypeCb, 0, &Wx::wxALL, 1 );	
	
	$szRow2->Add( $spacingTxt,  0, &Wx::wxALL, 1 );
	$szRow2->Add( $spacingCtrl, 0, &Wx::wxALL, 1 );

	$szRow3->Add( $centerTxt, 0, &Wx::wxALL, 1 );
	$szRow3->Add( $centerChb, 0, &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"spacingTypeCb"} = $spacingTypeCb;
	$self->{"spacingCtrl"} = $spacingCtrl;
	$self->{"centerChb"}   = $centerChb;

	return $szStatBox;
}

# Set layout general group
sub __SetLayoutDrawing {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Preview' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS
	my @dim = (500, 600);
	my $drawing = StencilDrawing->new($parent, \@dim);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $drawing, 1,   &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"drawing"} = $drawing;

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

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	
	my $test = Drawing->new( -1, "f13610" );

	# $test->Test();
	$test->MainLoop();

}

1;


 

