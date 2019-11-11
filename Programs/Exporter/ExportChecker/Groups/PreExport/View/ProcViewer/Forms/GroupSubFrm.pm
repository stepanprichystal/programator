#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupSubFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';

use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::RowCopperFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::RowProductFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::RowSeparatorFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $parent      = shift;
	my $productId   = shift;
	my $productType = shift;
	my $techCntrls  = shift;    # Show/hode technology controls
	my $productObj  = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES
	$self->{"copperRows"}  = [];
	$self->{"productId"}   = $productId;
	$self->{"productType"} = $productType;
	$self->{"techCntrls"}  = $techCntrls;
	$self->{"productObj"}  = $productObj;

	$self->__SetLayout($techCntrls);

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();
	$self->{"technologyChanged"}  = Event->new();
	$self->{"tentingChanged"}     = Event->new();

	return $self;

}

sub AddCopperRow {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	my $row = RowCopperFrm->new( $self, $copperName, $outerCore, $plugging );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );
	push( @{ $self->{"copperRows"} }, $row );

	$row->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );

	#$self->AddItemToQueue($row);

	return $row;
}

sub AddPrepregRow {
	my $self = shift;

	my $rowGapT = RowSeparatorFrm->new( $self, Enums->RowSeparator_GAP );
	$self->{"szRows"}->Add( $rowGapT, 0, &Wx::wxALL, 0 );
	my $rowPrpg = RowSeparatorFrm->new( $self, Enums->RowSeparator_PRPG );
	$self->{"szRows"}->Add( $rowPrpg, 0, &Wx::wxALL, 0 );
	my $rowGapB = RowSeparatorFrm->new( $self, Enums->RowSeparator_GAP );
	$self->{"szRows"}->Add( $rowGapB, 0, &Wx::wxALL, 0 );

}

sub AddCoreRow {
	my $self = shift;

	my $row = RowSeparatorFrm->new( $self, Enums->RowSeparator_CORE );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );

}

sub AddCoverlayRow {
	my $self = shift;
	my $type = shift;

	my $row = RowSeparatorFrm->new( $self, Enums->RowSeparator_COVERLAY );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );

}

sub AddProductRow {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;

	my $row = RowProductFrm->new( $self, $productId, $productType );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );
	push( @{ $self->{"copperRows"} }, $row );

	$row->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );

	return $row;
}

sub GetCopperRow {
	my $self      = shift;
	my $layerName = shift;

	return ( grep { $_->GetLayerName() eq $layerName } @{ $self->{"copperRows"} } )[0];
}

sub GetAllCopperRows {
	my $self      = shift;
	my $layerName = shift;

	return @{ $self->{"copperRows"} };
}

sub __SetLayout {
	my $self       = shift;
	my $techCntrls = shift;    # Show/hode technology controls

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $groupHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	# Group head
	my $groupHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 20, -1 ], );

	if ( $self->{"productType"} eq Enums->Group_PRODUCTINPUT ) {

		$groupHeadPnl->SetBackgroundColour( Wx::Colour->new( 255, 192, 0 ) );
	}
	elsif ( $self->{"productType"} eq Enums->Group_PRODUCTPRESS ) {
		$groupHeadPnl->SetBackgroundColour( Wx::Colour->new( 155, 194, 230 ) );
	}

	my $groupHeadTxt = Wx::StaticText->new( $groupHeadPnl, -1, $self->{"productId"}, [ -1, -1 ] );

	#my $fontLblBold = Wx::Font->new( 9, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL );

	$groupHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	                                                                        #$groupHeadTxt->SetFont($fontLblBold);
	my @tech = ( EnumsGeneral->Technology_GALVANICS, EnumsGeneral->Technology_RESIST, EnumsGeneral->Technology_OTHER );
	my $technologyCb = Wx::ComboBox->new( $self, -1, $tech[0], &Wx::wxDefaultPosition, [ 77, 23 ], \@tech, &Wx::wxCB_READONLY );
	my @pltType = ( EnumsGeneral->Etching_PATTERN, EnumsGeneral->Etching_TENTING, EnumsGeneral->Etching_ONLY );
	my $tentingCb = Wx::ComboBox->new( $self, -1, $pltType[0], &Wx::wxDefaultPosition, [ 77, 23 ], \@pltType, &Wx::wxCB_READONLY );

	$technologyCb->Hide() unless ( $self->{"techCntrls"} );
	$tentingCb->Hide()    unless ( $self->{"techCntrls"} );

	$groupHeadSz->Add( $groupHeadTxt, 1, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );

	$groupHeadPnl->SetSizer($groupHeadSz);

	$szMain->Add( $groupHeadPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $szCol2,       0, &Wx::wxLEFT, 5 );
	$szMain->Add( $szCol3,       0, &Wx::wxLEFT, 5 );

	#$szCol1->Add( $groupHeadPnl,   1, &Wx::wxEXPAND);

	$szCol3->Add( $technologyCb, 0, &Wx::wxALL, 1 );
	$szCol3->Add( $tentingCb,    0, &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES

	$self->{"szRows"} = $szCol2;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
