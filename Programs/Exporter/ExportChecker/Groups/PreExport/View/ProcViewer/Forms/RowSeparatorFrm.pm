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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $type   = shift;
	my $width  = shift // 60;
	my $height = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->__SetLayout( $type, $width, $height );

	#EVENTS
	$self->{"onLayerSettChanged"} = Event->new();

	return $self;

}

sub __SetLayout {
	my $self   = shift;
	my $type   = shift;
	my $width  = shift;
	my $height = shift;

	# DEFINE SZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $rowHeadSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CELLS

	my $clr = Wx::Colour->new( 255, 255, 255 );    # white is default
	$height = 5 unless ( defined $height );
	my $widthPerc = 1;                             # 100% of default width

	if ( $type eq Enums->RowSeparator_CORE ) {
		$clr = Wx::Colour->new( 179, 176, 0 );
		$height = 10 unless ( defined $height );
	}
	elsif ( $type eq Enums->RowSeparator_PRPG ) {
		$clr = Wx::Colour->new( 30, 149, 50 );
		$height = 6 unless ( defined $height );
		$widthPerc = 0.8;
	}

	# Row Head
	my $rowHeadPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ $width * $widthPerc, $height ] );

	$rowHeadPnl->SetBackgroundColour($clr);

	# SET EVENTS

	# DEFINE STRUCTURE

	#$rowHeadSz->Add( $rowHeadTxt, 0, &Wx::wxALL, 0 );
	$rowHeadPnl->SetSizer($rowHeadSz);

	$szMain->Add( $rowHeadPnl, 0, &Wx::wxLEFT, ( $width - $width * $widthPerc ) / 2 );

	$self->SetSizer($szMain);

	# SET REFERENCES

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
