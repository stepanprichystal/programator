#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::RowCopperFrm;
use base qw(Wx::Panel);

#3th party library
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $parent      = shift;
	my $copperName  = shift;
	my $outerCore   = shift;
	my $plugging    = shift;
	my $cuFoilOnly  = shift // 0;
	my $cuThickness = shift;
	my $shrink      = shift // 0;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->{"copperName"} = $copperName;
	$self->{"outerCore"}  = $outerCore;
	$self->{"plugging"}   = $plugging;
	$self->{"cuFoilOnly"} = $cuFoilOnly;
	$self->{"rowHeight"}  = 20;

	#build layer name
	my $lName = $self->{"copperName"};
	$lName = "(outer)" . $lName if ( $self->{"outerCore"} );
	$lName = "(plg)" . $lName   if ( $self->{"plugging"} );
	$lName = "(foil)"           if ( $self->{"cuFoilOnly"} );

	$self->__SetLayout( $lName, $cuThickness, $shrink );

	#EVENTS
	$self->{"sigLayerSettChangedEvt"} = Event->new();

	return $self;

}

sub UpdatePlating {
	my $self    = shift;
	my $plating = shift;

	if ( $self->{"plugging"} || $self->{"cuFoilOnly"} ) {
		return 0;
	}

	my $cur  = $self->{"cuThickTxt"}->GetLabel();
	my $base = ( $cur =~ /^(\d+)/ )[0];

	$base .= "+25" if ($plating);

	$self->{"cuThickTxt"}->SetLabel($base);
}

sub GetCopperName {
	my $self = shift;

	return $self->{"copperName"};
}

sub GetOuterCore {
	my $self = shift;

	return $self->{"outerCore"};
}

sub GetPlugging {
	my $self = shift;

	return $self->{"plugging"};
}

sub GetCuFoilOnly {
	my $self = shift;

	return $self->{"cuFoilOnly"};
}

#-------------------------------------------------------------------------------------------#
#  GET/SET frm methods
#-------------------------------------------------------------------------------------------#

sub SetPolarityVal {
	my $self = shift;
	my $val  = shift;

	if ( $val eq "positive" ) {
		$self->{"polarityCb"}->SetValue("+");
	}
	elsif ( $val eq "negative" ) {
		$self->{"polarityCb"}->SetValue("-");
	}
}

sub GetPolarityVal {
	my $self = shift;

	return $self->{"polarityCb"}->GetValue() eq "+" ? "positive" : "negative";
}

sub SetMirrorVal {
	my $self = shift;
	my $val  = shift;

	$self->{"mirrorChb"}->SetValue($val);
}

sub GetMirrorVal {
	my $self = shift;

	if ( $self->{"mirrorChb"}->IsChecked() ) {
		return 1;
	}
	else {
		return 0;

	}
}

sub SetCompVal {
	my $self = shift;
	my $val  = shift;

	$self->{"compTxt"}->SetValue($val);
}

sub GetCompVal {
	my $self = shift;

	return $self->{"compTxt"}->GetValue();
}

sub SetStretchXVal {
	my $self = shift;
	my $val  = shift;

	$self->{"shrinkXTxt"}->SetValue($val);
}

sub GetStretchXVal {
	my $self = shift;

	return $self->{"shrinkXTxt"}->GetValue();
}

sub SetStretchYVal {
	my $self = shift;
	my $val  = shift;

	$self->{"shrinkYTxt"}->SetValue($val);
}

sub GetStretchYVal {
	my $self = shift;

	return $self->{"shrinkYTxt"}->GetValue();
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnRowChanged {
	my $self = shift;

	$self->{"sigLayerSettChangedEvt"}->Do( $self->{"copperName"}, $self->{"outerCore"}, $self->{"plugging"} );
}

sub __SetLayout {
	my $self        = shift;
	my $lName       = shift;
	my $cuThickness = shift;
	my $shrink      = shift;

	# DEFINE SZERS

	my $szMain          = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $rowHeadSz       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $cntrlsWrapperSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE PANELS
	my $cntrlsWrapperPnl = Wx::Panel->new($self);

	# DEFINE CELLS

	# Row Head
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 70, $self->{"rowHeight"} ] );
	$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 180, 0, 0 ) );

	my $lTitle = $lName;

	my $rowHeadTxt = Wx::StaticText->new( $rowHeadPnl, -1, $lTitle, [ -1, -1 ] );
	$rowHeadTxt->SetForegroundColour( Wx::Colour->new( 255, 255, 255 ) );    # set text color

	my $cuThickTxt = Wx::StaticText->new( $cntrlsWrapperPnl, -1, $cuThickness, &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} - 2 ] );
	my @polar = ( "+", "-" );
	my $polarityCb =
	  Wx::ComboBox->new( $cntrlsWrapperPnl, -1, $polar[0], &Wx::wxDefaultPosition, [ 40, $self->{"rowHeight"} - 2 ], \@polar, &Wx::wxCB_READONLY );

	my $fontPolar = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_MAX );
	$polarityCb->SetFont($fontPolar);
	my $mirrorChb = Wx::CheckBox->new( $cntrlsWrapperPnl, -1, "", [ -1, -1 ], [ 40, $self->{"rowHeight"} - 2 ] );
	my $compTxt    = Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "undef", &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} - 2 ] );
	my $shrinkXTxt = undef;
	my $shrinkYTxt = undef;

	if ($shrink) {
		$shrinkXTxt = Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "undef", &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} - 2 ] );
		$shrinkYTxt =
		  Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "undef", &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} - 2 ] );
	}
	else {

		$shrinkXTxt =
		  Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "undef", &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} - 2 ], &Wx::wxCB_READONLY );
		$shrinkYTxt =
		  Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "undef", &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} - 2 ], &Wx::wxCB_READONLY );
	}

	if ( $self->{"cuFoilOnly"} ) {
		$polarityCb->Hide();
		$mirrorChb->Hide();
		$compTxt->Hide();
		$shrinkXTxt->Hide();
		$shrinkYTxt->Hide();

	}

	if ( $self->{"plugging"} || $self->{"cuFoilOnly"} ) {
		$cuThickTxt->SetLabel("-");
	}

	$self->SetBackgroundColour( Wx::Colour->new( 235, 235, 235 ) );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $mirrorChb, -1, sub { $self->__OnRowChanged(@_) } );
	Wx::Event::EVT_COMBOBOX( $polarityCb, -1, sub { $self->__OnRowChanged(@_) } );
	Wx::Event::EVT_TEXT( $compTxt,    -1, sub { $self->__OnRowChanged(@_) } );
	Wx::Event::EVT_TEXT( $shrinkXTxt, -1, sub { $self->__OnRowChanged(@_) } );
	Wx::Event::EVT_TEXT( $shrinkYTxt, -1, sub { $self->__OnRowChanged(@_) } );

	# DEFINE STRUCTURE

	$rowHeadSz->Add( $rowHeadTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );
	$rowHeadPnl->SetSizer($rowHeadSz);

	$szMain->Add( $rowHeadPnl, 0, &Wx::wxALL, 0 );

	$cntrlsWrapperSz->Add( $cuThickTxt, 0, &Wx::wxLEFT, 10 );
	$cntrlsWrapperSz->Add( $polarityCb, 0, &Wx::wxLEFT, 5 );
	$cntrlsWrapperSz->Add( $mirrorChb,  0, &Wx::wxLEFT, 5 );
	$cntrlsWrapperSz->Add( $compTxt,    0, &Wx::wxLEFT, 5 );
	$cntrlsWrapperSz->Add( $shrinkXTxt, 0, &Wx::wxLEFT, 5 );
	$cntrlsWrapperSz->Add( $shrinkYTxt, 0, &Wx::wxLEFT, 5 );
	

	$szMain->Add( $cntrlsWrapperPnl, 0, &Wx::wxALL, 1 );

	$cntrlsWrapperPnl->SetSizer($cntrlsWrapperSz);
	$self->SetSizer($szMain);

	# SET REFERENCES

	$self->{"cuThickTxt"} = $cuThickTxt;
	$self->{"polarityCb"} = $polarityCb;
	$self->{"mirrorChb"}  = $mirrorChb;
	$self->{"compTxt"}    = $compTxt;
	$self->{"shrinkXTxt"} = $shrinkXTxt;
	$self->{"shrinkYTxt"} = $shrinkYTxt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
