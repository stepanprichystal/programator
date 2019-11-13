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
	$self->{"layerSettChangedEvt"}  = Event->new();
	$self->{"technologyChangedEvt"} = Event->new();
	$self->{"tentingChangedEvt"}    = Event->new();

	return $self;

}

#sub AddCopperRow {
#	my $self       = shift;
#	my $copperName = shift;
#	my $outerCore  = shift;
#	my $plugging   = shift;
#
#	# DEFINE SIZERS
#	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#
#	# DEFINE CONTROLS
#	my $sepPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 100, 20 ] );
#	$sepPnl->SetBackgroundColour( Wx::Colour->new( 40, 40, 40 ) );
#
#	# BUILD LAYOUT STRUCTURE
#
#	$self->{"szRows"}->Add( $sepPnl, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
#
#	#$self->AddItemToQueue($row);
#
#	#return $row;
#}

sub AddCopperRow {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	my $row = RowCopperFrm->new( $self, $copperName, $outerCore, $plugging );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );
	push( @{ $self->{"copperRows"} }, $row );

	$row->{"layerSettChangedEvt"}->Add( sub { $self->{"layerSettChangedEvt"}->Do(@_) } );

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

#-------------------------------------------------------------------------------------------#
#  Layout settings
#-------------------------------------------------------------------------------------------#
sub HideSubGroupTitle {
	my $self = shift;

	# 1) Hidesubgroups, where is no layer except product layer
	$self->{"headPnl"}->Hide();
}

sub __SetLayout {
	my $self       = shift;
	my $techCntrls = shift;    # Show/hode technology controls

	my $szMain          = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $cntrlsWrapperSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE PANELS
	my $cntrlsWrapperPnl = Wx::Panel->new($self);

	#my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $groupHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	$self->SetBackgroundColour( Wx::Colour->new( 0, 255, 0 ) );

	# Group head
	my $groupHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 20, -1 ], );

	# product press has title always invisible
	if ( $self->{"productType"} eq Enums->Group_PRODUCTINPUT ) {

		$groupHeadPnl->SetBackgroundColour( Wx::Colour->new( 255, 192, 0 ) );
	}

	my $title = $self->{"productType"} eq Enums->Group_PRODUCTINPUT ? $self->{"productId"} : "";
	my $groupHeadTxt = Wx::StaticText->new( $groupHeadPnl, -1, $title, [ -1, -1 ] );

	#my $fontLblBold = Wx::Font->new( 9, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL );

	$groupHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	                                                                        #$groupHeadTxt->SetFont($fontLblBold);
	my @tech = ( EnumsGeneral->Technology_GALVANICS, EnumsGeneral->Technology_RESIST, EnumsGeneral->Technology_OTHER );
	my $technologyCb = Wx::ComboBox->new( $cntrlsWrapperPnl, -1, $tech[0], &Wx::wxDefaultPosition, [ 77, 23 ], \@tech, &Wx::wxCB_READONLY );
	my @pltType = ( EnumsGeneral->Etching_PATTERN, EnumsGeneral->Etching_TENTING, EnumsGeneral->Etching_ONLY );
	my $tentingCb = Wx::ComboBox->new( $cntrlsWrapperPnl, -1, $pltType[0], &Wx::wxDefaultPosition, [ 77, 23 ], \@pltType, &Wx::wxCB_READONLY );

	$technologyCb->Hide() unless ( $self->{"techCntrls"} );
	$tentingCb->Hide()    unless ( $self->{"techCntrls"} );

	$groupHeadSz->Add( $groupHeadTxt, 1, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );
	$groupHeadPnl->SetSizer($groupHeadSz);

	$cntrlsWrapperSz->Add( $technologyCb, 0, &Wx::wxALL, 1 );
	$cntrlsWrapperSz->Add( $tentingCb,    0, &Wx::wxALL, 1 );

	$szMain->Add( $groupHeadPnl,     0, &Wx::wxEXPAND );
	$szMain->Add( $szCol2,           1, &Wx::wxLEFT, 5 );
	$szMain->Add( $cntrlsWrapperPnl, 0, &Wx::wxLEFT, 5 );

	#$szCol1->Add( $groupHeadPnl,   1, &Wx::wxEXPAND);
	$cntrlsWrapperPnl->SetSizer($cntrlsWrapperSz);
	$self->SetSizer($szMain);

	# SET EVENTS

	Wx::Event::EVT_COMBOBOX( $technologyCb, -1, sub { $self->__OnTechnologyChanged(@_) } );
	Wx::Event::EVT_COMBOBOX( $tentingCb,    -1, sub { $self->__OnTentingChanged(@_) } );

	# SET REFERENCES

	$self->{"szRows"}       = $szCol2;
	$self->{"headPnl"}      = $groupHeadPnl;
	$self->{"technologyCb"} = $technologyCb;
	$self->{"tentingCb"}    = $tentingCb;

}

sub __OnTechnologyChanged {
	my $self = shift;

	$self->{"technologyChangedEvt"}->Do( $self->{"productId"}, $self->{"technologyCb"}->GetValue() );
}

sub __OnTentingChanged {
	my $self = shift;

	$self->{"tentingChangedEvt"}->Do( $self->{"productId"}, $self->{"tentingCb"}->GetValue() );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamDrilling';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d152456";
	my $stepName = "o+1";

	#my $layerName = "fstiffs";

	my @layers = ( CamDrilling->GetPltNCLayers( $inCAM, $jobId ), CamDrilling->GetNPltNCLayers( $inCAM, $jobId ) );

	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	die;

}

1;
