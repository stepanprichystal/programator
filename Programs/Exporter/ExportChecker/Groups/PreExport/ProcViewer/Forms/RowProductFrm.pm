#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::RowProductFrm;
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
	my $class     = shift;
	my $parent    = shift;
	my $productId   = shift;
	my $productType = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->{"rowHeight"} = 20;

	$self->__SetLayout( $productId, $productType );

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();

	return $self;

}

sub __SetLayout {
	my $self      = shift;
	my $productId   = shift;
	my $productType = shift;

	# DEFINE SZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $rowHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CELLS

	# Row Head
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 60, $self->{"rowHeight"} ] );

	if ( $productType eq StackEnums->Product_INPUT ) {

		$rowHeadPnl->SetBackgroundColour( Enums->Color_PRODUCTINPUT );
	}
	elsif ( $productType eq StackEnums->Product_PRESS ) {
		$rowHeadPnl->SetBackgroundColour( Enums->Color_PRODUCTPRESS );
	}

	my $rowHeadTxt = Wx::StaticText->new( $rowHeadPnl, -1, $productId, [ -1, -1 ] );

	#my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	$rowHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	#$rowHeadTxt->SetFont($fontLblBold);

	# SET EVENTS

	# DEFINE STRUCTURE

	$rowHeadSz->Add( $rowHeadTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );
	$rowHeadPnl->SetSizer($rowHeadSz);

	$szMain->Add( $rowHeadPnl, 0, &Wx::wxALL, 0 );

	$self->SetSizer($szMain);

	# SET REFERENCES

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
