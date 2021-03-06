#-------------------------------------------------------------------------------------------#
# Description: Conversion layername to titles, infos, file names, etc...
# Here put all "conversion" stuff
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::ValueConvertor;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsImp';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub GetNifCodeValue {
	my $self = shift;
	my $code = shift;

	my $info = "";

	# inner layer
	if ( $code =~ /^pc$/i ) {

		$info = "Silk screen top";
	}

	elsif ( $code =~ /^ps$/i ) {

		$info = "Silk screen bot";
	}

	elsif ( $code =~ /^mc$/i ) {

		$info = "Solder mask top";
	}
	elsif ( $code =~ /^ms$/i ) {

		$info = "Solder mask bot";
	}
	elsif ( $code =~ /^c$/i ) {

		$info = "Component side";
	}
	elsif ( $code =~ /^s$/i ) {

		$info = "Solder side";

	}
	elsif ( $code =~ /^v(\d)$/i ) {

		$info = "Inner layer $1";
	}

	return $info;
}

sub GetMaskColorToCode {
	my $self  = shift;
	my $color = shift;

	if ( $color eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"Green"}        = "Z";
	$colorMap{"Black"}        = "B";
	$colorMap{"WhiteMat"}     = "W";
	$colorMap{"WhiteGloss"}   = "X";
	$colorMap{"Blue"}         = "M";
	$colorMap{"Transparent"}  = "T";
	$colorMap{"Red"}          = "R";
	$colorMap{"GreenSMDFlex"} = "G";

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
	$colorMap{"W"} = "WhiteMat";
	$colorMap{"X"} = "WhiteGloss";
	$colorMap{"M"} = "Blue";
	$colorMap{"T"} = "Transparent";
	$colorMap{"R"} = "Red";
	$colorMap{"G"} = "GreenSMDFlex";

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

	#
}

# Return full name of impedance line type by shortcut
#EnumsImp->Type_SE     => "se",
#EnumsImp->Type_DIFF   => "diff",
#EnumsImp->Type_COSE   => "coplanar_se",
#EnumsImp->Type_CODIFF => "coplanar_diff",
sub GetImpedanceType {
	my $self = shift;
	my $type = shift;

	return "Single ended"          if ( $type eq EnumsImp->Type_SE );
	return "Differential"          if ( $type eq EnumsImp->Type_DIFF );
	return "Coplanar single ended" if ( $type eq EnumsImp->Type_COSE );
	return "Coplanar differential" if ( $type eq EnumsImp->Type_CODIFF );
}

# Convert "technology" name to IS code
sub GetTechNameToCode {
	my $self = shift;
	my $name = shift;

	if ( $name eq "" ) {
		return "";
	}

	my %techMap = ();
	$techMap{ EnumsGeneral->Technology_GALVANICS }   = "G";
	$techMap{ EnumsGeneral->Technology_RESIST }      = "M";
	$techMap{ EnumsGeneral->Technology_OTHER }       = "J";
	$techMap{ EnumsGeneral->Technology_SCREENPRINT } = "S";

	return $techMap{$name};
}

# Convert "technology" IS code to name
sub GetTechCodeToName {
	my $self = shift;
	my $code = shift;

	if ( $code eq "" ) {
		return "";
	}

	my %techMap = ();
	$techMap{"G"} = EnumsGeneral->Technology_GALVANICS;
	$techMap{"M"} = EnumsGeneral->Technology_RESIST;
	$techMap{"J"} = EnumsGeneral->Technology_OTHER;
	$techMap{"S"} = EnumsGeneral->Technology_SCREENPRINT;
	return $techMap{$code};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Helpers::JobHelper';

	#print JobHelper->GetBaseCuThick("F13608", "v3");

	#print "\n1";
}

1;

