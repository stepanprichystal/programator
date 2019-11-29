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
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
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
	my $pltNC       = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES
	$self->{"copperRows"}  = [];
	$self->{"productId"}   = $productId;
	$self->{"productType"} = $productType;

	$self->__SetLayout($pltNC);

	#EVENTS
	$self->{"sigLayerSettChangedEvt"} = Event->new();
	$self->{"technologyChangedEvt"}   = Event->new();
	$self->{"etchingChangedEvt"}      = Event->new();

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
	my $cuFoil     = shift;
	my $cuThick    = shift;
	my $coreShrink = shift;

	my $row = RowCopperFrm->new( $self, $copperName, $outerCore, $plugging, $cuFoil, $cuThick, $coreShrink);
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );
	push( @{ $self->{"copperRows"} }, $row );

	$row->{"sigLayerSettChangedEvt"}->Add( sub { $self->{"sigLayerSettChangedEvt"}->Do(@_) } );

	#$self->AddItemToQueue($row);

	return $row;
}

sub AddPrepregRow {
	my $self       = shift;
	my $extraPress = shift;

	my $text = "<= Prepreg lamination after press" if ($extraPress);

	my $rowPrpg = RowSeparatorFrm->new( $self, Enums->RowSeparator_PRPG, $text );
	$self->{"szRows"}->Add( $rowPrpg, 0, &Wx::wxALL, 0 );

}

sub AddPrepregCoverlayRow {
	my $self       = shift;
	my $extraPress = shift;

	my $text = "<= Prepreg + Coverlay lamination after press" if ($extraPress);

	my $rowPrpg = RowSeparatorFrm->new( $self, Enums->RowSeparator_PRPGCOVERLAY, $text );
	$self->{"szRows"}->Add( $rowPrpg, 0, &Wx::wxALL, 0 );

}

sub AddCoreRow {
	my $self = shift;

	my $row = RowSeparatorFrm->new( $self, Enums->RowSeparator_CORE );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );

}

sub AddCoverlayRow {
	my $self       = shift;
	my $type       = shift;
	my $extraPress = shift;

	my $text = "<= Coverlay lamination after press" if ($extraPress);

	my $row = RowSeparatorFrm->new( $self, Enums->RowSeparator_COVERLAY, $text );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );

}

sub AddProductRow {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;

	my $row = RowProductFrm->new( $self, $productId, $productType );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );

	$row->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );

	return $row;
}

sub GetCopperRow {
	my $self      = shift;
	my $layerName = shift;

	return ( grep { $_->GetCopperName() eq $layerName } @{ $self->{"copperRows"} } )[0];
}

sub GetAllCopperRows {
	my $self      = shift;
	my $layerName = shift;

	return @{ $self->{"copperRows"} };
}

sub GetProductId {
	my $self = shift;

	return $self->{"productId"};
}

sub GetProductType {
	my $self = shift;

	return $self->{"productType"};
}

#-------------------------------------------------------------------------------------------#
#  GET/SET frm methods
#-------------------------------------------------------------------------------------------#

sub SetTechnologyVal {
	my $self = shift;
	my $val  = shift;

	$self->{"technologyCb"}->SetValue($val);

	if ( $val ne EnumsGeneral->Technology_GALVANICS ) {
		$self->{"tentingCb"}->Hide();

	}
	else {
		$self->{"tentingCb"}->Show();
	}

}

sub GetTechnologyVal {
	my $self = shift;

	return $self->{"technologyCb"}->GetValue();
}

sub SetTentingVal {
	my $self = shift;
	my $val  = shift;

	$self->{"tentingCb"}->SetValue($val);

}

sub GetTentingVal {
	my $self = shift;

	return $self->{"tentingCb"}->GetValue();
}

#-------------------------------------------------------------------------------------------#
#  Layout settings
#-------------------------------------------------------------------------------------------#
sub HideSubGroupTitle {
	my $self = shift;

	# 1) Hidesubgroups, where is no layer except product layer
	$self->{"headPnl"}->Hide();
}

sub HideSubGroupTechnology {
	my $self = shift;

	$self->{"technologyCb"}->Hide();
	$self->{"tentingCb"}->Hide();

}

sub __SetLayout {
	my $self  = shift;
	my $pltNC = shift;    # Show/hode technology controls

	my $szMain    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRows    = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRigh    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $cntrlsSz  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szNCDrill = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE PANELS
	my $rightPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 140, -1 ], );

	my $groupHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	#$self->SetBackgroundColour( Wx::Colour->new( 0, 255, 0 ) );
	$rightPnl->SetBackgroundColour( Wx::Colour->new( 230, 230, 230 ) );

	# Group head
	my $groupHeadPnl =
	  Wx::Panel->new( $self, -1, [ -1, -1 ], [ ( $self->{"productType"} eq StackEnums->Product_PRESS ? 18 + 6 : 18 ), -1 ], );

	# product press has title always invisible
	if ( $self->{"productType"} eq StackEnums->Product_INPUT ) {

		$groupHeadPnl->SetBackgroundColour( Enums->Color_PRODUCTINPUT );

	}
	elsif ( $self->{"productType"} eq StackEnums->Product_PRESS ) {

		$groupHeadPnl->SetBackgroundColour( Enums->Color_PRODUCTPRESS );
	}

	my $title = $self->{"productType"} eq StackEnums->Product_INPUT ? $self->{"productId"} : "";
	my $groupHeadTxt = Wx::StaticText->new( $groupHeadPnl, -1, $title, [ -1, -1 ] );

	#my $fontLblBold = Wx::Font->new( 9, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL );

	$groupHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	                                                                        #$groupHeadTxt->SetFont($fontLblBold);
	my @tech = ( EnumsGeneral->Technology_GALVANICS, EnumsGeneral->Technology_RESIST, EnumsGeneral->Technology_OTHER );
	my $technologyCb = Wx::ComboBox->new( $rightPnl, -1, $tech[0], &Wx::wxDefaultPosition, [ 75, 23 ], \@tech, &Wx::wxCB_READONLY );
	my @pltType = ( EnumsGeneral->Etching_PATTERN, EnumsGeneral->Etching_TENTING, EnumsGeneral->Etching_ONLY );
	my $tentingCb = Wx::ComboBox->new( $rightPnl, -1, $pltType[0], &Wx::wxDefaultPosition, [ 75, 23 ], \@pltType, &Wx::wxCB_READONLY );

	# NC drill

	foreach my $ncL ( @{$pltNC} ) {

		my $ncTxt = Wx::StaticText->new( $rightPnl, -1, "• " . $ncL->{"gROWname"} );
		$szNCDrill->Add( $ncTxt, 0, &Wx::wxLEFT, 10 );                      # expander

	}

	#$groupHeadSz->Add( $groupHeadTxt, 1, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER | &Wx::wxALIGN_CENTER_HORIZONTAL, 0 );
	$groupHeadSz->Add( 0, 0, 1 );                                           # expander
	$groupHeadSz->Add( $groupHeadTxt, 1, &Wx::wxALIGN_CENTER_VERTICAL, 0 );
	$groupHeadSz->Add( 0, 0, 1 );                                           # expander

	$groupHeadPnl->SetSizer($groupHeadSz);

	$cntrlsSz->Add( $technologyCb, 0, &Wx::wxALL, 1 );
	$cntrlsSz->Add( $tentingCb,    0, &Wx::wxALL, 1 );

	$szRigh->Add( $cntrlsSz,  0, &Wx::wxLEFT, 2 );
	$szRigh->Add( $szNCDrill, 0, &Wx::wxALL,  0 );
	$szRigh->Add( 0, 50, 0 );                                              # Expander (min height of right panel)

	$szMain->Add( $groupHeadPnl, 0, &Wx::wxEXPAND | &Wx::wxLEFT, ( $self->{"productType"} eq StackEnums->Product_INPUT ? 6 : 0 ) );
	$szMain->Add( $szRows, 0, &Wx::wxLEFT, 8 );
	$szMain->Add( $rightPnl, 1, &Wx::wxLEFT | &Wx::wxEXPAND, 5 );

	#$szCol1->Add( $groupHeadPnl,   1, &Wx::wxEXPAND);
	$rightPnl->SetSizer($szRigh);
	$self->SetSizer($szMain);

	# SET EVENTS

	Wx::Event::EVT_COMBOBOX( $technologyCb, -1, sub { $self->__OnTechnologyChanged(@_) } );
	Wx::Event::EVT_COMBOBOX( $tentingCb,    -1, sub { $self->__OnTentingChanged(@_) } );

	# SET REFERENCES

	$self->{"szRows"}       = $szRows;
	$self->{"headPnl"}      = $groupHeadPnl;
	$self->{"technologyCb"} = $technologyCb;
	$self->{"tentingCb"}    = $tentingCb;

}

sub __OnTechnologyChanged {
	my $self = shift;

	my $technology = $self->{"technologyCb"}->GetValue();

	# Disable enable tenting according technology value

	if ( $technology ne EnumsGeneral->Technology_GALVANICS ) {
		$self->{"tentingCb"}->Hide();

	}
	else {
		$self->{"tentingCb"}->Show();
	}

	$self->{"technologyChangedEvt"}->Do( $self->{"productId"}, $self->{"productType"}, $technology );
}

sub __OnTentingChanged {
	my $self = shift;

	$self->{"etchingChangedEvt"}->Do( $self->{"productId"}, $self->{"productType"}, $self->{"tentingCb"}->GetValue() );
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
