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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $parent     = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;
	my $cuFoilOnly = shift // 0;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->{"copperName"} = $copperName;
	$self->{"outerCore"}  = $outerCore;
	$self->{"plugging"}   = $plugging;
	$self->{"cuFoilOnly"} = $cuFoilOnly;
	$self->{"rowHeight"}  = 22;

	#build layer name
	my $lName = $self->{"copperName"};
	$lName = "outer" . $lName   if ( $self->{"outerCore"} );
	$lName = "plg" . $lName     if ( $self->{"plugging"} );
	$lName = $lName . " (foil)" if ( $self->{"cuFoilOnly"} );

	$self->__SetLayout($lName);

	#EVENTS
	$self->{"layerSettChangedEvt"} = Event->new();

	return $self;

}


sub SetLayerValues {
	my $self  = shift;
	my %lInfo = %{ shift(@_) };

	$self->SetSelected( $lInfo{"plot"} );

	if ( $lInfo{"polarity"} eq "positive" ) {
		$self->{"polarityCb"}->SetValue("+");
	}
	elsif ( $lInfo{"polarity"} eq "negative" ) {
		$self->{"polarityCb"}->SetValue("-");
	}

	$self->{"mirrorChb"}->SetValue( $lInfo{"mirror"} );
	$self->{"compTxt"}->SetValue( $lInfo{"comp"} );
	$self->{"shrinkX"}->SetValue( $lInfo{"shrinkX"} );
	$self->{"shrinkY"}->SetValue( $lInfo{"shrinkX"} );
}

sub GetLayerValues {
	my $self = shift;

	my %lInfo = ();

	$lInfo{"name"} = $self->GetRowText();

	$lInfo{"polarity"} = $self->{"polarityCb"}->GetValue() eq "+" ? "positive" : "negative";

	if ( $self->{"mirrorChb"}->IsChecked() ) {
		$lInfo{"mirror"} = 1;
	}
	else {
		$lInfo{"mirror"} = 0;

	}
	$lInfo{"comp"} = $self->{"compTxt"}->GetValue();

	$lInfo{"shrinkX"} = $self->{"shrinkXTxt"}->GetValue();

	$lInfo{"shrinkY"} = $self->{"shrinkYTxt"}->GetValue();

	return %lInfo;
}
 

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnRowChanged {
	my $self = shift;

	$self->{"layerSettChangedEvt"}->Do( $self->{"copperName"}, $self->{"outerCore"}, $self->{"plugging"} );
}



sub __SetLayout {
	my $self  = shift;
	my $lName = shift;

	# DEFINE SZERS

	my $szMain          = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $rowHeadSz       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $cntrlsWrapperSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE PANELS
	my $cntrlsWrapperPnl = Wx::Panel->new($self);

	# DEFINE CELLS

	# Row Head
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 60, $self->{"rowHeight"} ] );
	$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 180, 0, 0 ) );
	my $rowHeadTxt = Wx::StaticText->new( $rowHeadPnl, -1, $lName, [ -1, -1 ] );
	$rowHeadTxt->SetForegroundColour( Wx::Colour->new( 255, 255, 255 ) );    # set text color

	my @polar = ( "+", "-" );
	my $polarityCb =
	  Wx::ComboBox->new( $cntrlsWrapperPnl, -1, $polar[0], &Wx::wxDefaultPosition, [ 40, $self->{"rowHeight"} ], \@polar, &Wx::wxCB_READONLY );

	my $fontPolar = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_MAX );
	$polarityCb->SetFont($fontPolar);
	my $mirrorChb = Wx::CheckBox->new( $cntrlsWrapperPnl, -1, "", [ -1, -1 ], [ 20, $self->{"rowHeight"} ] );
	my $compTxt    = Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "105",   &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} ] );
	my $shrinkXTxt = Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "113.5", &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} ], &Wx::wxCB_READONLY );
	my $shrinkYTxt = Wx::TextCtrl->new( $cntrlsWrapperPnl, -1, "95",    &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} ], &Wx::wxCB_READONLY );

	#	if ( $self->{"cuFoilOnly"} ) {
	#		$polarityCb->Hide();
	#		$mirrorChb->Hide();
	#		$compTxt->Hide();
	#		$shrinkXTxt->Hide();
	#		$shrinkYTxt->Hide();
	#	}

	$self->SetBackgroundColour( Wx::Colour->new( 255, 0, 0 ) );

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

	$cntrlsWrapperSz->Add( $polarityCb, 0, &Wx::wxLEFT, 10 );
	$cntrlsWrapperSz->Add( $mirrorChb,  0, &Wx::wxLEFT, 15 );
	$cntrlsWrapperSz->Add( $compTxt,    0, &Wx::wxLEFT, 5 );
	$cntrlsWrapperSz->Add( $shrinkXTxt, 0, &Wx::wxLEFT, 5 );
	$cntrlsWrapperSz->Add( $shrinkYTxt, 0, &Wx::wxLEFT, 5 );
	$szMain->Add( $cntrlsWrapperPnl, 0, &Wx::wxALL, 0 );

	$cntrlsWrapperPnl->SetSizer($cntrlsWrapperSz);
	$self->SetSizer($szMain);

	# SET REFERENCES

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
