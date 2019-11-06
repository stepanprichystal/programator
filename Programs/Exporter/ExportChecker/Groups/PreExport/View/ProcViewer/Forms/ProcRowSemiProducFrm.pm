#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcSemiProducFrm;
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
	my $groupId   = shift;
	my $groupType = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->{"rowHeight"} = 40;

	$self->__SetLayout( $groupId, $groupType );

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();

	return $self;

}

sub __SetLayout {
	my $self      = shift;
	my $groupId   = shift;
	my $groupType = shift;

	# DEFINE SZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $rowHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CELLS

	# Row Head
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 60, $self->{"rowHeight"} ] );

	if ( $groupType eq Enums->Group_SEMIPRODUC ) {

		$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 255, 192, 0 ) );
	}
	elsif ( $groupType eq Enums->Group_PRESSING ) {
		$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 155, 194, 230 ) );
	}

	my $rowHeadTxt = Wx::StaticText->new( $rowHeadPnl, -1, $groupId, [ -1, -1 ] );

	my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	$groupHeadTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	$groupHeadTxt->SetFont($fontLblBold);

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
