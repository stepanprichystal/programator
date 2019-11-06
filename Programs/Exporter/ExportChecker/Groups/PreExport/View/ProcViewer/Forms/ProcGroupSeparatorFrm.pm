
#-------------------------------------------------------------------------------------------#
# Description: Base item class, wchich is managed by container MyWxCustomQueue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcGroupSeparatorFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $parent     = shift;
	my $groupSepId = shift;
	my $groupType  = shift;

	my $self = $class->SUPER::new( $parent, $groupSepId );

	bless($self);

	# Items references
	# PROPERTIES

	$self->__SetLayout($groupType);

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();
	$self->{"technologyChanged"}  = Event->new();
	$self->{"tentingChanged"}     = Event->new();

	return $self;

}

sub __SetLayout {
	my $self      = shift;
	my $groupType = shift;

	# DEFINE SIZERS
	my $szMain       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $groupTitleSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $groupTitlePnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
	my $groupTitleTxt = Wx::StaticText->new( $groupTitlePnl, -1, "", [ -1, -1 ] );

	if ( $groupType eq Enums->Group_SEMIPRODUC ) {

		$groupTitlePnl->SetBackgroundColour( Wx::Colour->new( 255, 192, 0 ) );
		$groupTitleTxt->SetLabel("Input semi-product");
	}
	elsif ( $groupType eq Enums->Group_PRESSING ) {
		$groupTitlePnl->SetBackgroundColour( Wx::Colour->new( 155, 194, 230 ) );
		$groupTitleTxt->SetLabel("Pressing");
	}

	my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	$groupTitleTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	$groupTitleTxt->SetFont($fontLblBold);

	# BUILD LAYOUT STRUCTURE
	$groupTitleSz->Add( $groupTitleTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );
	$groupTitlePnl->SetSizer($groupTitleSz);

	$szMain->Add( $groupTitlePnl, 1, &Wx::wxALL, 4 );

	$self->SetSizer($szMain);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
