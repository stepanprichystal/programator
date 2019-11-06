#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcGroupStackupFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';


use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcRowCopperFrm';

use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcRowSeparatorFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $parent    = shift;
	my $groupId   = shift;
	my $groupType = shift;

	my $self = $class->SUPER::new( $parent, $groupId );

	bless($self);

	# Items references
	# PROPERTIES
	$self->{"copperRows"} = [];
	$self->{"groupType"}  = $groupType;

	$self->__SetLayout();

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();
	$self->{"technologyChanged"}  = Event->new();
	$self->{"tentingChanged"}     = Event->new();

	return $self;

}

sub AddCopperRow {
	my $self      = shift;
	my $layerName = shift;

	my $row = ProcRowCopperFrm->new( $self, $layerName );
	$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );
	push( @{ $self->{"copperRows"} }, $row );

	$row->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );

	#$self->AddItemToQueue($row);

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

sub AddIsolRow {
	my $self = shift;
	my $type = shift;

	if ( $type eq Enums->RowSeparator_PRPG ) {

		my $rowGapT = ProcRowSeparatorFrm->new( $self, Enums->RowSeparator_GAP );
		$self->{"szRows"}->Add( $rowGapT, 0, &Wx::wxALL, 0 );
		my $rowPrpg = ProcRowSeparatorFrm->new( $self, Enums->RowSeparator_PRPG );
		$self->{"szRows"}->Add( $rowPrpg, 0, &Wx::wxALL, 0 );
		my $rowGapB = ProcRowSeparatorFrm->new( $self, Enums->RowSeparator_GAP );
		$self->{"szRows"}->Add( $rowGapB, 0, &Wx::wxALL, 0 );

	}
	else {

		my $row = ProcRowSeparatorFrm->new( $self, $type );
		$self->{"szRows"}->Add( $row, 0, &Wx::wxALL, 0 );
	}

}

sub AddSemiProducRow {
	my $self = shift;

	my $row = ProcRowSemiFrm->new( $self->GetParentForItem() );

	#$row->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );

	$self->AddItemToQueue($row);

	return $row;
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $groupHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	# Group head
	my $groupHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 20, -1 ], );

	if ( $self->{"groupType"} eq Enums->Group_SEMIPRODUC ) {

		$groupHeadPnl->SetBackgroundColour( Wx::Colour->new( 255, 192, 0 ) );
	}
	elsif ( $self->{"groupType"} eq Enums->Group_PRESSING ) {
		$groupHeadPnl->SetBackgroundColour( Wx::Colour->new( 155, 194, 230 ) );
	}

	my $groupHeadTxt = Wx::StaticText->new( $groupHeadPnl, -1, "1", [ -1, -1 ] );
	my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	$groupHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	$groupHeadTxt->SetFont($fontLblBold);
	my @tech = ( EnumsGeneral->Technology_GALVANICS, EnumsGeneral->Technology_RESIST, EnumsGeneral->Technology_OTHER );
	my $technologyCb = Wx::ComboBox->new( $self, -1, $tech[0], &Wx::wxDefaultPosition, [ 77, 23 ], \@tech, &Wx::wxCB_READONLY );

	my @pltType = ( EnumsGeneral->Etching_PATTERN, EnumsGeneral->Etching_TENTING, EnumsGeneral->Etching_ONLY );
	my $tentingCb = Wx::ComboBox->new( $self, -1, $pltType[0], &Wx::wxDefaultPosition, [ 77, 23 ], \@pltType, &Wx::wxCB_READONLY );

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
