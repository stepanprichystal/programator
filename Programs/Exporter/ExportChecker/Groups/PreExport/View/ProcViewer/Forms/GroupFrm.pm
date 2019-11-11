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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $parent    = shift;
	my $groupId   = shift;
	my $groupType = shift;
	
	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

 
	bless($self);

	# Items references
	# PROPERTIES
	$self->{"subGroups"} = [];
	$self->{"groupId"} = $groupId;
	$self->{"groupType"} = $groupType;

	$self->__SetLayout();

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();
	$self->{"technologyChanged"}  = Event->new();
	$self->{"tentingChanged"}     = Event->new();

	return $self;

}

sub AddSubGroup {
	my $self        = shift;
	my $producId    = shift;
	my $productType = shift;
	my $techCntrls = shift;
	my $productObj  = shift;

	my $subGroup = GroupSubFrm->new( $self, $producId, $productType, $techCntrls, $productObj );
	$self->{"szGroups"}->Add( $subGroup, 0, &Wx::wxALL, 0 );
	push( @{ $self->{"subGroups"} }, $subGroup );

	$subGroup->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );

	#$self->AddItemToQueue($row);

	return $subGroup;
}

sub AddSeparator {
	my $self        = shift;
	 
	$self->{"szGroups"}->Add( 5, 5, &Wx::wxALL, 0 );
 
}

sub GetSubGroups {
	my $self        = shift;
	 
	return @{ $self->{"subGroups"} };
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

	if ( $self->{"groupType"} eq Enums->Group_PRODUCTINPUT ) {

		$groupHeadPnl->SetBackgroundColour(Enums->Color_PRODUCTINPUT );
	}
	elsif ( $self->{"groupType"} eq Enums->Group_PRODUCTPRESS ) {
		$groupHeadPnl->SetBackgroundColour( Enums->Color_PRODUCTPRESS  );
	}

	my $groupHeadTxt = Wx::StaticText->new( $groupHeadPnl, -1, $self->{"groupId"}, [ -1, -1 ] );
	my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	$groupHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	$groupHeadTxt->SetFont($fontLblBold);

	$groupHeadSz->Add( $groupHeadTxt, 1, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );

	$groupHeadPnl->SetSizer($groupHeadSz);

	$szMain->Add( $groupHeadPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $szCol2,       0, &Wx::wxLEFT, 5 );
	$szMain->Add( $szCol3,       0, &Wx::wxLEFT, 5 );

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES

	$self->{"szGroups"} = $szCol2;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
