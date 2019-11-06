#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcRowCopperFrm;
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
	my $class     = shift;
	my $parent    = shift;
	my $layerName = shift;
	my $cuFoilOnly = shift // 0;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->{"layerName"} = $layerName;
	$self->{"rowHeight"} = 22;

	$self->__SetLayout();

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();

	return $self;

}

sub __SetLayout {
	my $self = shift;
	my $cuFoilOnly = shift;
	# DEFINE SZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $rowHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CELLS

	# Row Head
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 60, $self->{"rowHeight"} ] );
	$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 180, 0, 0 ) );
	my $rowHeadTxt = Wx::StaticText->new( $rowHeadPnl, -1, $self->{"layerName"}, [ -1, -1 ] );
	$rowHeadTxt->SetForegroundColour( Wx::Colour->new( 255, 255, 255 ) );    # set text color

	my @polar = ( "+", "-" );
	my $polarityCb =
	  Wx::ComboBox->new( $self, -1, $polar[0], &Wx::wxDefaultPosition, [ 40, $self->{"rowHeight"} ], \@polar, &Wx::wxCB_READONLY );
	my $fontPolar = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_MAX );
	$polarityCb->SetFont($fontPolar);
	my $mirrorChb = Wx::CheckBox->new( $self, -1, "", [ -1, -1 ], [ 20, $self->{"rowHeight"} ] );
	my $compTxt    = Wx::TextCtrl->new( $self, -1, "105",   &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} ] );
	my $shrinkXTxt = Wx::TextCtrl->new( $self, -1, "113.5", &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} ], &Wx::wxCB_READONLY );
	my $shrinkYTxt = Wx::TextCtrl->new( $self, -1, "95",    &Wx::wxDefaultPosition, [ 50, $self->{"rowHeight"} ], &Wx::wxCB_READONLY );

	if ($cuFoilOnly) {
		$polarityCb->Hide();
		$mirrorChb->Hide();
		$compTxt->Hide();
		$shrinkXTxt->Hide();
		$shrinkYTxt->Hide();

	}

	# SET EVENTS
	#	Wx::Event::EVT_CHECKBOX( $mirrorChb, -1, sub { $self->__OnRowChanged(@_) } );
	#	Wx::Event::EVT_COMBOBOX( $polarityCb, -1, sub { $self->__OnRowChanged(@_) } );
	#	Wx::Event::EVT_TEXT( $compTxt,       -1, sub { $self->__OnRowChanged(@_) } );
	#	Wx::Event::EVT_TEXT( $technologyTxt, -1, sub { $self->__OnRowChanged(@_) } );

	# DEFINE STRUCTURE

	$rowHeadSz->Add( $rowHeadTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );
	$rowHeadPnl->SetSizer($rowHeadSz);

	$szMain->Add( $rowHeadPnl, 0, &Wx::wxALL,  0 );
	$szMain->Add( $polarityCb, 0, &Wx::wxLEFT, 10 );
	$szMain->Add( $mirrorChb,  0, &Wx::wxLEFT, 15 );
	$szMain->Add( $compTxt,    0, &Wx::wxLEFT, 5 );
	$szMain->Add( $shrinkXTxt, 0, &Wx::wxLEFT, 5 );
	$szMain->Add( $shrinkYTxt, 0, &Wx::wxLEFT, 5 );

	$self->SetSizer($szMain);

	# SET REFERENCES

	$self->{"polarityCb"} = $polarityCb;
	$self->{"mirrorChb"}  = $mirrorChb;
	$self->{"compTxt"}    = $compTxt;
	$self->{"shrinkXTxt"} = $shrinkXTxt;
	$self->{"shrinkYTxt"} = $shrinkYTxt;

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

	$lInfo{"plot"} = $self->IsSelected();

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

sub GetLayerName {
	my $self = shift;

	return $self->{"layerName"};

}

sub GetIsCopperLayer {
	my $self = shift;

	return 1;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
