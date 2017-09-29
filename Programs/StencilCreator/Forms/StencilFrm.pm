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
use aliased 'Packages::Events::Event';

#local library

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::StencilCreator::Forms::StencilDrawing';
use aliased 'Programs::StencilCreator::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my @dimension = ( 800, 800 );
	my $self = $class->SUPER::new( $parent, "Stencil creator", \@dimension );

	bless($self);

	# Properties
	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	# Events
	$self->{"fmrDataChanged"} = Event->new();
	$self->{"prepareClick"}   = Event->new();

	return $self;
}

# Set data necessary for proper GUI loading
sub Init {
	my $self = shift;

	$self->{"dataMngr"}   = shift;
	$self->{"layoutMngr"} = shift;

	$self->{"stepsSize"} = $self->{"dataMngr"}->{"stepsSize"};
	$self->{"steps"}     = $self->{"dataMngr"}->{"steps"};
	$self->{"topExist"}  = $self->{"dataMngr"}->{"topExist"};
	$self->{"botExist"}  = $self->{"dataMngr"}->{"botExist"};

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

	return $tVal;
}

sub SetStencilType {
	my $self = shift;
	my $type = shift;

	$self->{"stencilTypeCb"}->SetValue($type);

	$self->__DisableControls();

}

sub GetStencilSize {
	my $self = shift;

	my %size = ( "w" => 0, "h" => 0, "custom" => 0 );

	my $sVal = $self->{"sizeCb"}->GetValue();

	if ( $sVal =~ /custom/ ) {

		$size{"w"}            = $self->{"sizeXTextCtrl"}->GetValue();
		$size{"h"}            = $self->{"sizeYTextCtrl"}->GetValue();
		$self->{"customSize"} = 1;

	}
	else {

		( $size{"w"}, $size{"h"} ) = $sVal =~ /(\d+)\s*x\s*(\d+)mm/i;
		$self->{"customSize"} = 0;
	}

	return %size;
}

sub SetStencilSize {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	# "300mm x 480mm", "300mm x 520mm", "custom"
	if ( $self->{"customSize"} == 1 ) {
		$self->{"sizeCb"}->SetValue( Enums->StencilSize_CUSTOM );
		$self->{"sizeXTextCtrl"}->SetValue($width);
		$self->{"sizeYTextCtrl"}->SetValue($height);
	}
	else {

		my @t = (
				  Enums->StencilSize_150x200, Enums->StencilSize_200x300, Enums->StencilSize_300x300, Enums->StencilSize_300x480,
				  Enums->StencilSize_300x520
		);

		my $selType = undef;
		foreach my $t (@t) {

			my ( $w, $h ) = $t =~ /(\d+)\s*x\s*(\d+)mm/i;

			if ( $w == $width && $h == $height ) {
				$selType = $t;
				last;
			}
		}

		unless ( defined $selType ) {

			$self->{"customSize"} = 1;
			$self->{"sizeCb"}->SetValue( Enums->StencilSize_CUSTOM );
			$self->{"sizeXTextCtrl"}->SetValue($width);
			$self->{"sizeYTextCtrl"}->SetValue($height);

		}

		$self->{"sizeCb"}->SetValue($selType);

		$self->__DisableControls();
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

	$self->__DisableControls();
}

sub GetSpacing {
	my $self = shift;

	return $self->{"spacingCtrl"}->GetValue();
}

sub SetSpacing {
	my $self    = shift;
	my $spacing = shift;

	$self->{"spacingCtrl"}->SetValue($spacing);

	$self->__DisableControls();
}

# Spacing between stencil type
# 1 - profile2profile
# 2- pad2pad
sub GetSpacingType {
	my $self = shift;

	return $self->{"spacingTypeCb"}->GetValue();
}

sub SetSpacingType {
	my $self = shift;
	my $type = shift;

	$self->{"spacingTypeCb"}->SetValue($type);

	$self->__DisableControls();
}

# Horiyontal aligment type
sub GetCenterType {
	my $self = shift;

	return $self->{"hCenterTypeCb"}->GetValue();
}

sub SetCenterType {
	my $self = shift;
	my $type = shift;

	$self->{"hCenterTypeCb"}->SetValue($type);

	$self->__DisableControls();
}

sub SetSchemaType {
	my $self = shift;
	my $val  = shift;

	$self->{"schemaCb"}->SetValue($val);

	$self->__DisableControls();
}

sub GetSchemaType {
	my $self = shift;

	return $self->{"schemaCb"}->GetValue();
}

sub SetHoleSize {
	my $self = shift;
	my $val  = shift;

	$self->{"holeSizeSpin"}->SetValue($val);

	$self->__DisableControls();
}

sub GetHoleSize {
	my $self = shift;
	my $val  = shift;

	return $self->{"holeSizeSpin"}->GetValue();
}

sub SetHoleDist {
	my $self = shift;
	my $val  = shift;

	$self->{"holeSpaceSpin"}->SetValue($val);

	$self->__DisableControls();
}

sub GetHoleDist {
	my $self = shift;

	return $self->{"holeSpaceSpin"}->GetValue();
}

sub SetHoleDist2 {
	my $self = shift;
	my $val  = shift;

	$self->{"holeDist2Spin"}->SetValue($val);

	$self->__DisableControls();
}

sub GetHoleDist2 {
	my $self = shift;
	return $self->{"holeDist2Spin"}->GetValue();
}

sub SetAddPcbNumber {
	my $self = shift;
	my $val  = shift;

	$self->{"addNumberChb"}->SetValue($val);

	$self->__DisableControls();
}

sub GetAddPcbNumber {
	my $self = shift;

	my $val = $self->{"addNumberChb"}->GetValue();

	if ( $val != 1 ) {
		$val = 0;
	}
	return $val;
}

sub UpdateDrawing {
	my $self     = shift;
	my $autoZoom = shift;

	$self->{"drawing"}->StencilDataChanged($autoZoom);
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnControlDataChanged {
	my $self        = shift;
	my $controlName = shift;
	my $newValue    = shift;
	my $autoZoom    = shift;

	if ( $self->{"raiseEvt"} ) {

		$self->{"fmrDataChanged"}->Do( $self, $controlName, $newValue );
	}

	#	# Update GUI
	#
	#	$self->__DisableControls();
	#
	#	# Update Layout manager
	#	$self->{"layoutMngr"}->Inited(0);
	#
	#	# 1) update type of stencil
	#	my $stencilType = $self->GetStencilType();
	#	$self->{"layoutMngr"}->SetStencilType($stencilType);
	#
	#	# 2) update profile data
	#	my $stencilStep = $self->GetStencilStep();
	#
	#	if ( $self->{"topExist"} ) {
	#
	#		my $pd = PasteData->new( $self->{"stepsSize"}->{$stencilStep}->{"top"}->{"w"}, $self->{"stepsSize"}->{$stencilStep}->{"top"}->{"h"} );
	#		my $pp = PasteProfile->new( $self->{"stepsSize"}->{$stencilStep}->{"w"}, $self->{"stepsSize"}->{$stencilStep}->{"h"} );
	#
	#		$pp->SetPasteData( $pd, $self->{"stepsSize"}->{$stencilStep}->{"top"}->{"x"}, $self->{"stepsSize"}->{$stencilStep}->{"top"}->{"y"} );
	#
	#		$self->{"layoutMngr"}->SetTopProfile($pp);
	#	}
	#
	#	if ( $self->{"botExist"} ) {
	#
	#		my $botKye = $stencilType eq Enums->StencilType_BOT ? "bot" : "botMirror";
	#
	#		my $pd = PasteData->new( $self->{"stepsSize"}->{$stencilStep}->{$botKye}->{"w"}, $self->{"stepsSize"}->{$stencilStep}->{$botKye}->{"h"} );
	#		my $pp = PasteProfile->new( $self->{"stepsSize"}->{$stencilStep}->{"w"}, $self->{"stepsSize"}->{$stencilStep}->{"h"} );
	#
	#		$pp->SetPasteData( $pd, $self->{"stepsSize"}->{$stencilStep}->{$botKye}->{"x"}, $self->{"stepsSize"}->{$stencilStep}->{$botKye}->{"y"} );
	#
	#		$self->{"layoutMngr"}->SetBotProfile($pp);
	#	}
	#
	#	# 3)update stencil size
	#
	#	my %size = $self->GetStencilSize();
	#	$self->{"layoutMngr"}->SetWidth( $size{"w"} );
	#	$self->{"layoutMngr"}->SetHeight( $size{"h"} );
	#
	#
	#
	#	# 4) Update schema
	#
	#	my $schema = Schema->new( $size{"w"},  $size{"h"});
	#
	#	$schema->SetSchemaType($self->GetSchemaType());
	#	$schema->SetHoleSize($self->GetHoleSize());
	#	$schema->SetHoleDist($self->GetHoleDist());
	#	$schema->SetHoleDist2($self->GetHoleDist2());
	#
	# 	$self->{"layoutMngr"}->SetSchema($schema);
	#
	# 	# 5) Spacing type
	# 	$self->{"layoutMngr"}->SetSpacingType( $self->GetSpacingType() );
	#
	#	# 4) Set spacing size. Default or set by user
	#	if($defaultSpacing && $self->GetSpacingType() eq Enums->Spacing_PROF2PROF){
	#
	#		my $spac = $self->{"layoutMngr"}->GetDefaultSpacing();
	#		$self->{"layoutMngr"}->SetSpacing( $spac);
	#
	#		# set spacing to control
	#		#$self->SetSpacing($spac);
	#
	#	}else{
	#
	#		$self->{"layoutMngr"}->SetSpacing( $self->GetSpacing() );
	#	}
	#
	#	# 5)Set horiyontal aligment type
	#	$self->{"layoutMngr"}->SetCenterType( $self->GetCenterType() );
	#
	#
	#	$self->{"layoutMngr"}->Inited(1);
	#
	#	$self->{"drawing"}->DataChanged($autoZoom);
}

sub __DisableControls {
	my $self = shift;

	my $st = $self->GetStencilType();

	if ( $st eq Enums->StencilType_TOPBOT ) {

		$self->{"pnlSpacing"}->Show();
	}
	else {

		$self->{"pnlSpacing"}->Hide();

	}

	my $sVal = $self->{"sizeCb"}->GetValue();

	if ( $sVal =~ /custom/ ) {

		$self->{"sizeXTextCtrl"}->Enable();
		$self->{"sizeYTextCtrl"}->Enable();
	}
	else {
		$self->{"sizeXTextCtrl"}->Disable();
		$self->{"sizeYTextCtrl"}->Disable();
	}

	my $schType = $self->{"schemaCb"}->GetValue();

	$self->{"pnlSchStandard"}->Hide();
	$self->{"pnlSchVlepeni"}->Hide();
	$self->{"pnlSchIncluded"}->Hide();

	if ( $schType eq Enums->Schema_STANDARD ) {

		$self->{"pnlSchStandard"}->Show();

	}
	elsif ( $schType eq Enums->Schema_FRAME ) {

	}
	elsif ( $schType eq Enums->Schema_INCLUDED ) {

	}

	# if center by profile, spacing type only prof2prof
	if ( $self->{"hCenterTypeCb"}->GetValue() eq Enums->Center_BYPROF ) {

		$self->{"spacingTypeCb"}->SetValue( Enums->Spacing_PROF2PROF );

	}
	elsif ( $self->{"hCenterTypeCb"}->GetValue() eq Enums->Center_BYDATA ) {

		$self->{"spacingTypeCb"}->SetValue( Enums->Spacing_DATA2DATA );
	}

	$self->{"szMain"}->Layout();
	$self->{"mainFrm"}->Refresh();

}

#
#sub __PrepareDrawData {
#	my $self = shift;
#
#	my %d = ();
#
#	# Type of stencil
#	my $typeVal = $self->GetStencilType();
#	my ( %topPcb, %botPcb ) = ( "exist" => 0 );
#
#	$d{"topPcb"} = \%topPcb;
#	$d{"botPcb"} = \%botPcb;
#
#	if ( $typeVal =~ /top/i ) {
#		$d{"topPcb"}{"exists"} = 1;
#
#	}
#	elsif ( $typeVal =~ /bot/i ) {
#		$d{"botPcb"}{"exist"} = 1;
#
#	}
#	elsif ( $typeVal =~ /both/i ) {
#		$d{"topPcb"}{"exists"} = 1;
#		$d{"botPcb"}{"exists"} = 1;
#	}
#
#	# Size of stencil
#	my %size = $self->GetStencilSize();
#	$d{"w"} = $size{"w"};
#	$d{"h"} = $size{"h"};
#
#	# Step
#	$d{"step"} = $self->GetStencilStep();
#
#	# Set profile and data size TOP + BOT
#	if ( $d{"topPcb"}{"exists"} ) {
#		$d{"topPcb"}->{"w"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"w"};
#		$d{"topPcb"}->{"h"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"h"};
#		$d{"topPcb"}->{"wData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"top"}->{"w"};
#		$d{"topPcb"}->{"hData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"top"}->{"h"};
#	}
#
#	if ( $d{"botPcb"}{"exists"} ) {
#		$d{"botPcb"}->{"w"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"w"};
#		$d{"botPcb"}->{"h"}     = $self->{"stepsSize"}->{ $d{"step"} }->{"h"};
#		$d{"botPcb"}->{"wData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"bot"}->{"w"};
#		$d{"botPcb"}->{"hData"} = $self->{"stepsSize"}->{ $d{"step"} }->{"bot"}->{"h"};
#	}
#
#	# Compute positons of paste profile, siye
#	my $spacing     = $self->GetSpacing();
#	my $spacingType = $self->GetSpacingType();
#
#	# profile to profile
#	if ( $spacingType == 0 ) {
#		my $posX = ( $d{"w"} - $d{"topPcb"}->{"w"} ) / 2;
#
#		# compute position with actual spacing
#		if ( $typeVal eq "both" ) {
#
#			$d{"topPcb"}->{"posX"} = ( $d{"w"} - $d{"topPcb"}->{"w"} ) / 2;
#			$d{"topPcb"}->{"posY"} = $d{"h"} / 2 + $spacing / 2;
#			$d{"topPcb"}->{"posX"} = ( $d{"w"} - $d{"topPcb"}->{"w"} ) / 2;
#			$d{"topPcb"}->{"posY"} = $d{"h"} / 2 - ( $spacing / 2 + $d{"botPcb"}->{"h"} );
#
#		}
#
#		# centre pcb vertical
#		elsif ( $typeVal eq "top" ) {
#
#			$d{"topPcb"}->{"posX"} = ( $d{"w"} - $d{"topPcb"}->{"w"} ) / 2;
#			$d{"topPcb"}->{"posY"} = $d{"h"} / 2 - ( $d{"topPcb"}->{"h"} / 2 );
#
#		}
#		elsif ( $typeVal eq "bot" ) {
#
#			$d{"botPcb"}->{"posX"} = ( $d{"w"} - $d{"botPcb"}->{"w"} ) / 2;
#			$d{"botPcb"}->{"posY"} = $d{"h"} / 2 - ( $d{"botPcb"}->{"h"} / 2 );
#		}
#	}
#
#	return \%d;
#}

#-------------------------------------------------------------------------------------------#
#  Layout methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	#define panels
	my $pnlMain = Wx::Panel->new( $self->{"mainFrm"}, -1 );
	my $szMain  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szcol1  = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $general  = $self->__SetLayoutGeneral($pnlMain);
	my $schema   = $self->__SetLayoutSchema($pnlMain);
	my $other    = $self->__SetLayoutOther($pnlMain);
	my $custInfo = $self->__SetLayoutCustomerInfo($pnlMain);

	my $drawing = $self->__SetLayoutDrawing($pnlMain);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szcol1->Add( $general, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szcol1->Add( $schema,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szcol1->Add( $other,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szcol1->Add( $custInfo,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szcol1,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $drawing, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$pnlMain->SetSizer($szMain);

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(30);

	$self->AddButton( "Prepare stencil", sub { $self->{"prepareClick"}->Do(@_) } );

	$self->{"szMain"} = $szMain;

	$self->__DisableControls();

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

	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Type", &Wx::wxDefaultPosition, [ 170, 22 ] );

	my @types = ();
	push( @types, Enums->StencilType_TOP )    if ( $self->{"topExist"} );
	push( @types, Enums->StencilType_BOT )    if ( $self->{"botExist"} );
	push( @types, Enums->StencilType_TOPBOT ) if ( $self->{"topExist"} && $self->{"botExist"} );
	my $stencilTypeCb = Wx::ComboBox->new( $statBox, -1, $types[0], &Wx::wxDefaultPosition, [ 120, 22 ], \@types, &Wx::wxCB_READONLY );

	my $stepTxt = Wx::StaticText->new( $statBox, -1, "Step", &Wx::wxDefaultPosition, [ 170, 22 ] );

	my $stepCb =
	  Wx::ComboBox->new( $statBox, -1, $self->{"steps"}->[0], &Wx::wxDefaultPosition, [ 120, 22 ], $self->{"steps"}, &Wx::wxCB_READONLY );

	my $sizeTxt = Wx::StaticText->new( $statBox, -1, "Size", &Wx::wxDefaultPosition, [ 170, 22 ] );

	my @sizes = ();
	push( @sizes,
		  Enums->StencilSize_150x200, Enums->StencilSize_200x300, Enums->StencilSize_300x300,
		  Enums->StencilSize_300x480, Enums->StencilSize_300x520, Enums->StencilSize_CUSTOM );
	my $sizeCb = Wx::ComboBox->new( $statBox, -1, $sizes[0], &Wx::wxDefaultPosition, [ 120, 22 ], \@sizes, &Wx::wxCB_READONLY );

	my $customSize = Wx::StaticText->new( $statBox, -1, "Custom size [mm]", &Wx::wxDefaultPosition, [ 170, 22 ] );

	my $sizeXTextCtrl = Wx::TextCtrl->new( $statBox, -1, 300, &Wx::wxDefaultPosition, [ 60, 22 ] );
	my $sizeYTextCtrl = Wx::TextCtrl->new( $statBox, -1, 480, &Wx::wxDefaultPosition, [ 60, 22 ] );

	# SET EVENTS
	Wx::Event::EVT_TEXT( $stencilTypeCb, -1, sub { $self->__OnControlDataChanged( "stencilType", $self->GetStencilType() ) } );
	Wx::Event::EVT_TEXT( $stepCb,        -1, sub { $self->__OnControlDataChanged( "step",        $self->GetStencilStep() ) } );
	Wx::Event::EVT_TEXT( $sizeCb,        -1, sub { $self->__OnControlDataChanged( "size",        $self->GetStencilSize() ) } );
	Wx::Event::EVT_TEXT( $sizeXTextCtrl, -1, sub { $self->__OnControlDataChanged( "sizeX",       $self->GetStencilSize() ) } );
	Wx::Event::EVT_TEXT( $sizeYTextCtrl, -1, sub { $self->__OnControlDataChanged( "sizeY",       $self->GetStencilSize() ) } );

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

	my $pnlSchStandard = Wx::Panel->new($statBox);
	my $pnlSchVlepeni  = Wx::Panel->new($statBox);
	my $pnlSchIncluded = Wx::Panel->new($statBox);

	my $szSchStandard = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSchVlepeni  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSchIncluded = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szSchStandardRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szSchStandardRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szSchStandardRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#
	#	# DEFINE CONTROLS
	#
	my $schemaTxt = Wx::StaticText->new( $statBox, -1, "Type", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my @types = ( Enums->Schema_STANDARD, Enums->Schema_FRAME, Enums->Schema_INCLUDED );
	my $schemaCb = Wx::ComboBox->new( $statBox, -1, $types[0], &Wx::wxDefaultPosition, [ 120, 22 ], \@types, &Wx::wxCB_READONLY );

	# Type - standard

	my $holeSizeTxt = Wx::StaticText->new( $pnlSchStandard, -1, "Hole size [mm]", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $holeSizeSpin = Wx::TextCtrl->new( $pnlSchStandard, -1, 0, &Wx::wxDefaultPosition, [ 120, 22 ] );

	my $holeSpaceTxt = Wx::StaticText->new( $pnlSchStandard, -1, "Hole distance X [mm]", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $holeSpaceSpin = Wx::TextCtrl->new( $pnlSchStandard, -1, 0, &Wx::wxDefaultPosition, [ 120, 22 ] );

	my $holeDist2Txt = Wx::StaticText->new( $pnlSchStandard, -1, "Hole distance Y [mm]", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $holeDist2Spin = Wx::TextCtrl->new( $pnlSchStandard, -1, 0, &Wx::wxDefaultPosition, [ 120, 22 ] );

	# SET EVENTS
	Wx::Event::EVT_TEXT( $schemaCb,      -1, sub { $self->__OnControlDataChanged( "schemaType", $self->GetSchemaType() ) } );
	Wx::Event::EVT_TEXT( $holeSizeSpin,  -1, sub { $self->__OnControlDataChanged( "holeSize",   $self->GetHoleSize() ) } );
	Wx::Event::EVT_TEXT( $holeSpaceSpin, -1, sub { $self->__OnControlDataChanged( "holeDist",   $self->GetHoleDist() ) } );
	Wx::Event::EVT_TEXT( $holeDist2Spin, -1, sub { $self->__OnControlDataChanged( "holeDist2",  $self->GetHoleDist2() ) } );

	#	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $schemaTxt, 0, &Wx::wxALL, 1 );
	$szRow1->Add( $schemaCb,  0, &Wx::wxALL, 1 );

	$szSchStandardRow1->Add( $holeSizeTxt,  0, &Wx::wxALL, 1 );
	$szSchStandardRow1->Add( $holeSizeSpin, 0, &Wx::wxALL, 1 );

	$szSchStandardRow2->Add( $holeSpaceTxt,  0, &Wx::wxALL, 1 );
	$szSchStandardRow2->Add( $holeSpaceSpin, 0, &Wx::wxALL, 1 );

	$szSchStandardRow3->Add( $holeDist2Txt,  0, &Wx::wxALL, 1 );
	$szSchStandardRow3->Add( $holeDist2Spin, 0, &Wx::wxALL, 1 );

	$szSchStandard->Add( $szSchStandardRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szSchStandard->Add( $szSchStandardRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szSchStandard->Add( $szSchStandardRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$pnlSchStandard->SetSizer($szSchStandard);
	$pnlSchVlepeni->SetSizer($szSchVlepeni);
	$pnlSchIncluded->SetSizer($szSchIncluded);

	$szStatBox->Add( $szRow1,         0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $pnlSchStandard, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $pnlSchVlepeni,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $pnlSchIncluded, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#	# Set References
	$self->{"schemaCb"}      = $schemaCb;
	$self->{"holeSizeSpin"}  = $holeSizeSpin;
	$self->{"holeSpaceSpin"} = $holeSpaceSpin;
	$self->{"holeDist2Spin"} = $holeDist2Spin;

	$self->{"pnlSchStandard"} = $pnlSchStandard;
	$self->{"pnlSchVlepeni"}  = $pnlSchVlepeni;
	$self->{"pnlSchIncluded"} = $pnlSchIncluded;

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

	my $szSpacing   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSpacingR1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szSpacingR2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szRowPcbNum = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $pnlSpacing = Wx::Panel->new($statBox);

	# DEFINE CONTROLS

	my $centerTxt = Wx::StaticText->new( $statBox, -1, "Center pcb data", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my @typesC = ( Enums->Center_BYPROF, Enums->Center_BYDATA );
	my $hCenterTypeCb = Wx::ComboBox->new( $statBox, -1, $typesC[0], &Wx::wxDefaultPosition, [ 120, 22 ], \@typesC, &Wx::wxCB_READONLY );

	my $spacingTypeTxt = Wx::StaticText->new( $pnlSpacing, -1, "Spacing type", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my @types = ( Enums->Spacing_PROF2PROF, Enums->Spacing_DATA2DATA );
	my $spacingTypeCb = Wx::ComboBox->new( $pnlSpacing, -1, $types[0], &Wx::wxDefaultPosition, [ 120, 22 ], \@types, &Wx::wxCB_READONLY );
	$spacingTypeCb->Disable();

	my $spacingTxt = Wx::StaticText->new( $pnlSpacing, -1, "Spacing between pcb [mm]", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $spacingCtrl = Wx::TextCtrl->new( $pnlSpacing, -1, 15, &Wx::wxDefaultPosition, [ 120, 22 ] );

	my $addNumberTxt = Wx::StaticText->new( $statBox, -1, "Add pcb number", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $addNumberChb = Wx::CheckBox->new( $statBox, -1, "", [ -1, -1 ], [ -1, -1 ] );

	# SET EVENTS
	Wx::Event::EVT_TEXT( $spacingCtrl,   -1, sub { $self->__OnControlDataChanged( "spacing",     $self->GetSpacing() ) } );
	Wx::Event::EVT_TEXT( $spacingTypeCb, -1, sub { $self->__OnControlDataChanged( "spacingType", $self->GetSpacingType() ) } );
	Wx::Event::EVT_TEXT( $hCenterTypeCb, -1, sub { $self->__OnControlDataChanged( "hCenterType", $self->GetCenterType() ) } );
	Wx::Event::EVT_CHECKBOX( $addNumberChb, -1, sub { $self->__OnControlDataChanged( "addPcbNumber", $self->GetAddPcbNumber() ) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $centerTxt,     0, &Wx::wxALL, 1 );
	$szRow1->Add( $hCenterTypeCb, 0, &Wx::wxALL, 1 );

	$szSpacingR1->Add( $spacingTypeTxt, 0, &Wx::wxALL, 1 );
	$szSpacingR1->Add( $spacingTypeCb,  0, &Wx::wxALL, 1 );

	$szSpacingR2->Add( $spacingTxt,  0, &Wx::wxALL, 1 );
	$szSpacingR2->Add( $spacingCtrl, 0, &Wx::wxALL, 1 );

	$szRowPcbNum->Add( $addNumberTxt, 0, &Wx::wxALL, 1 );
	$szRowPcbNum->Add( $addNumberChb, 0, &Wx::wxALL, 1 );

	$pnlSpacing->SetSizer($szSpacing);
	$szSpacing->Add( $szSpacingR1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szSpacing->Add( $szSpacingR2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1,      0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $pnlSpacing,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRowPcbNum, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"spacingTypeCb"} = $spacingTypeCb;
	$self->{"spacingCtrl"}   = $spacingCtrl;
	$self->{"hCenterTypeCb"} = $hCenterTypeCb;
	$self->{"pnlSpacing"}    = $pnlSpacing;
	$self->{"addNumberChb"}  = $addNumberChb;

	return $szStatBox;
}

# Set layout general group
sub __SetLayoutCustomerInfo {
	my $self   = shift;
	my $parent = shift;

	my $custInfo = HegMethods->GetCustomerInfo( $self->{"jobId"} );
	my $custNote = CustomerNote->new( $custInfo->{"reference_subjektu"} );

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, "Requests - " . $custInfo->{"customer"} );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# build array of customer request

	my @request = ();

	if ( defined $custNote->HoleDistX() ) {

		push( @request, "- Vertical distance between hole: " . $custNote->HoleDistX() . "mm" );
	}
	if ( defined $custNote->HoleDistY() ) {

		push( @request, "- Horizontal distance between hole: " . $custNote->HoleDistY() . "mm" );
	}
	if ( defined $custNote->OuterHoleDist() ) {

		push( @request, "- Outer hole distance (vertical): " . $custNote->OuterHoleDist() . "mm" );
	}
	if ( defined $custNote->CenterByData() ) {

		push( @request, "- Center pcb by data (not by profile)" );
	}
	if ( defined $custNote->MinHoleDataDist() ) {

		push( @request, "- Minimal distance of paste data to holes: " . $custNote->MinHoleDataDist() . "mm" );
	}
	if ( defined $custNote->NoHalfHoles() ) {

		push( @request, "- No holes on edges of stencil (no halfholes)" );
	}
	if ( defined $custNote->NoFiducial() ) {

		push( @request, "- No fiducial mark in stencil" );
	}

	foreach my $r (@request) {

		my $rTxt = Wx::StaticText->new( $statBox, -1, $r, &Wx::wxDefaultPosition, [ 170, 22 ] );
		$szStatBox->Add( $rTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	}

	# Set References

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
	my @dim = ( 500, 600 );
	my $drawing = StencilDrawing->new( $parent, \@dim, $self->{"dataMngr"}, $self->{"layoutMngr"} );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $drawing, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

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

