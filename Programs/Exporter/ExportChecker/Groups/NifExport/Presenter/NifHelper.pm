
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

sub GetMaskColorToCode {
	my $self  = shift;
	my $color = shift;

	if ( $color eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"Green"}       = "Z";
	$colorMap{"Black"}       = "B";
	$colorMap{"White"}       = "W";
	$colorMap{"Blue"}        = "M";
	$colorMap{"Transparent"} = "T";
	$colorMap{"Red"}         = "R";

	return $colorMap{$color};
}

sub GetMaskCodeToColor {
	my $self = shift;
	my $code = shift;

	if ( $code eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"Z"} = "Green";
	$colorMap{"B"} = "Black";
	$colorMap{"W"} = "White";
	$colorMap{"M"} = "Blue";
	$colorMap{"T"} = "Transparent";
	$colorMap{"R"} = "Red";

	return $colorMap{$code};
}

sub GetSilkColorToCode {
	my $self  = shift;
	my $color = shift;

	if ( $color eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"White"}  = "B";
	$colorMap{"Yellow"} = "Z";
	$colorMap{"Black"}  = "C";

	return $colorMap{$color};
}

sub GetSilkCodeToColor {
	my $self = shift;
	my $code = shift;

	if ( $code eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"B"} = "White";
	$colorMap{"Z"} = "Yellow";
	$colorMap{"C"} = "Black";

	return $colorMap{$code};
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

