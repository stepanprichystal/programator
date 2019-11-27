#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::RowSeparatorFrm;
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
	my $class  = shift;
	my $parent = shift;
	my $type   = shift;
	my $text   = shift;

	my $width = 70;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->{"textSize"} = 8;

	if ( $type eq Enums->RowSeparator_PRPG ) {
		$self->__SetLayoutPrepreg( $text, $width, 10 );
	}
	elsif ( $type eq Enums->RowSeparator_PRPGCOVERLAY ) {
		$self->__SetLayoutPrepregCvrl( $text, $width, 10 );
	}
	elsif ( $type eq Enums->RowSeparator_CORE ) {
		$self->__SetLayoutCore( $width, 17 );
	}
	elsif ( $type eq Enums->RowSeparator_COVERLAY ) {
		$self->__SetLayoutCvrl( $text, $width, 10 );
	}

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();

	return $self;

}

sub __SetLayoutPrepreg {
	my $self   = shift;
	my $text   = shift;
	my $width  = shift;
	my $height = shift;

	my $widthPerc = 0.8;

	# DEFINE SZERS

	my $szMain    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $rowHeadSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CELLS

	my $rowTxt = Wx::StaticText->new( $self, -1, $text, [ -1, $height ] ) if ( defined $text );
	$rowTxt->SetFont( Wx::Font->new( $self->{"textSize"}, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL ) )
	  if ( defined $text );
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ $width * $widthPerc, $height / 2 ] );
	$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 71, 143, 71 ) );

	# DEFINE STRUCTURE

	$rowHeadSz->Add( 1, ( $text ? 5 : 2 ), 1, &Wx::wxEXPAND );
	$rowHeadSz->Add( $rowHeadPnl, 0, &Wx::wxLEFT, ( $width - $width * $widthPerc ) / 2 );
	$rowHeadSz->Add( 1, ( $text ? 5 : 2 ), 1, &Wx::wxEXPAND );

	$szMain->Add( $rowHeadSz, 0, );
	$szMain->Add( $rowTxt, 0, &Wx::wxLEFT, 10 ) if ( defined $text );

	$self->SetSizer($szMain);

}

sub __SetLayoutCvrl {
	my $self   = shift;
	my $text   = shift;
	my $width  = shift;
	my $height = shift;

	# DEFINE SZERS

	my $szMain    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $rowHeadSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CELLS

	my $rowTxt = Wx::StaticText->new( $self, -1, $text, [ -1, $height ] ) if ( defined $text );
	$rowTxt->SetFont( Wx::Font->new( $self->{"textSize"}, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL ) )
	  if ( defined $text );
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ $width, $height / 2 ] );
	$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 251, 210, 49 ) );

	# DEFINE STRUCTURE

	$rowHeadSz->Add( 1, ( $text ? 5 : 2 ), 1, &Wx::wxEXPAND );
	$rowHeadSz->Add( $rowHeadPnl, 0, &Wx::wxLEFT, 0 );
	$rowHeadSz->Add( 1, ( $text ? 5 : 2 ), 1, &Wx::wxEXPAND );

	$szMain->Add( $rowHeadSz, 0, );
	$szMain->Add( $rowTxt, 0, &Wx::wxLEFT, 10 ) if ( defined $text );

	$self->SetSizer($szMain);
}

sub __SetLayoutCore {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	# DEFINE SZERS

	my $szMain    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $rowHeadSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CELLS

	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ $width, $height / 2 ] );
	$rowHeadPnl->SetBackgroundColour( Wx::Colour->new( 159, 149, 19 ) );

	# DEFINE STRUCTURE

	$rowHeadSz->Add( $rowHeadPnl, 0, &Wx::wxLEFT, 0 );

	$szMain->Add( $rowHeadSz, 0, );

	$self->SetSizer($szMain);
}

sub __SetLayoutPrepregCvrl {
	my $self   = shift;
	my $text   = shift;
	my $width  = shift;
	my $height = shift;

	# DEFINE SZERS

	my $szMain     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $rowHead1Sz = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $rowHead2Sz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CELLS

	my $rowTxt = Wx::StaticText->new( $self, -1, $text, [ -1, $height ] ) if ( defined $text );
	$rowTxt->SetFont( Wx::Font->new( $self->{"textSize"}, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL ) )
	  if ( defined $text );
	my $prpgLPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ $width * 0.2, $height / 2 ] );
	$prpgLPnl->SetBackgroundColour( Wx::Colour->new( 71, 143, 71 ) );
	my $cvrlPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ $width * 0.6, $height / 2 ] );
	$cvrlPnl->SetBackgroundColour( Wx::Colour->new( 251, 210, 49 ) );
	my $prpgRPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ $width * 0.2, $height / 2 ] );
	$prpgRPnl->SetBackgroundColour( Wx::Colour->new( 71, 143, 71 ) );

	# DEFINE STRUCTURE
	$rowHead2Sz->Add( $prpgLPnl, 0, );
	$rowHead2Sz->Add( $cvrlPnl,  0, );
	$rowHead2Sz->Add( $prpgRPnl, 0, );

	$rowHead1Sz->Add( 1, ( $text ? 5 : 2 ), 1, &Wx::wxEXPAND );
	$rowHead1Sz->Add( $rowHead2Sz, 0, &Wx::wxALL, 0 );
	$rowHead1Sz->Add( 1, ( $text ? 5 : 2 ), 1, &Wx::wxEXPAND );

	$szMain->Add( $rowHead1Sz, 0, );
	$szMain->Add( $rowTxt, 0, &Wx::wxLEFT, 10 ) if ( defined $text );

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
