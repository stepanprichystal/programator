#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupFrm;
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

use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupSubFrm';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $parent      = shift;
	my $productId   = shift;
	my $productType = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES
	$self->{"subGroups"}   = [];
	$self->{"productId"}   = $productId;
	$self->{"productType"} = $productType;

	$self->__SetLayout();

	#EVENTS
	$self->{"sigLayerSettChangedEvt"} = Event->new();
	$self->{"technologyChangedEvt"}   = Event->new();
	$self->{"etchingChangedEvt"}      = Event->new();

	return $self;

}

sub AddSubGroup {
	my $self        = shift;
	my $producId    = shift;
	my $productType = shift;
	my $pltNC       = shift;
	my $otherNC     = shift;

	if ( scalar( @{ $self->{"subGroups"} } ) ) {
		$self->__AddSeparator();
	}

	my $subGroup = GroupSubFrm->new( $self, $producId, $productType, $pltNC, $otherNC );
	$self->{"szSubGroups"}->Add( $subGroup, 0, &Wx::wxALL | &Wx::wxEXPAND, 0 );

	push( @{ $self->{"subGroups"} }, $subGroup );

	$subGroup->{"sigLayerSettChangedEvt"}->Add( sub { $self->{"sigLayerSettChangedEvt"}->Do(@_) } );
	$subGroup->{"technologyChangedEvt"}->Add( sub   { $self->{"technologyChangedEvt"}->Do(@_) } );
	$subGroup->{"etchingChangedEvt"}->Add( sub      { $self->{"etchingChangedEvt"}->Do(@_) } );

	#$self->AddItemToQueue($row);

	return $subGroup;
}

sub GetSubGroups {
	my $self = shift;

	return @{ $self->{"subGroups"} };
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $szCol3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $groupHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	# Group head
	my $groupHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 17, -1 ], );

	if ( $self->{"productType"} eq StackEnums->Product_INPUT ) {

		$groupHeadPnl->SetBackgroundColour( Enums->Color_PRODUCTINPUT );
	}
	elsif ( $self->{"productType"} eq StackEnums->Product_PRESS ) {
		$groupHeadPnl->SetBackgroundColour( Enums->Color_PRODUCTPRESS );
	}

	my $groupHeadTxt = Wx::StaticText->new( $groupHeadPnl, -1, $self->{"productId"}, [ -1, -1 ] );
	my $fontLblBold = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	$groupHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	$groupHeadTxt->SetFont($fontLblBold);

	$groupHeadSz->Add( $groupHeadTxt, 1, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 6 );

	$groupHeadPnl->SetSizer($groupHeadSz);

	$szMain->Add( $groupHeadPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $szCol2, 1, &Wx::wxLEFT, 0 );

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES

	$self->{"szSubGroups"} = $szCol2;

}

sub __AddSeparator {
	my $self = shift;

	# DEFINE SIZERS
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $sepPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, 1 ] );
	$sepPnl->SetBackgroundColour( Wx::Colour->new( 200, 200, 200 ) );

	# BUILD LAYOUT STRUCTURE
	$szMain->Add( ( $self->{"productType"} eq StackEnums->Product_INPUT ? 6 : 0 ), 0, 0 );    # Expander
	$szMain->Add( $sepPnl, 1 );                                                               # Expander
	$self->{"szSubGroups"}->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxTOP | &Wx::wxBOTTOM, 4 );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
