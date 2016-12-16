
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper;

#3th party library
use strict;
use warnings;
use Wx;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetPcbMaskColors {
	my $self = shift;

	my @color = ( "Green", "Black", "White", "Blue", "Red", "Transparent" );

	return @color;
}

sub GetPcbSilkColors {
	my $self = shift;

	my @color = ( "White", "Yellow", "Black" );

	return @color;
}



sub GetColorDef {
	my $self  = shift;
	my $color = shift;

	my %colorMap = ();
	$colorMap{"Green"}       = Wx::Colour->new( 85,  128, 0 );
	$colorMap{"Black"}       = Wx::Colour->new( 0,   0,   0 );
	$colorMap{"White"}       = Wx::Colour->new( 255, 255, 255 );
	$colorMap{"Blue"}        = Wx::Colour->new( 0,   0,   255 );
	$colorMap{"Transparent"} = Wx::Colour->new( 245, 245, 245 );
	$colorMap{"Red"}         = Wx::Colour->new( 230, 46,  0 );
	$colorMap{"Yellow"}      = Wx::Colour->new( 255, 255, 0 );

	return $colorMap{$color};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

