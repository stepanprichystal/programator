
#-------------------------------------------------------------------------------------------#
# Description: Helper class provide title, description, units to each setting key
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::Settings::SettingsInfo;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	# Load settings info for each settings

	$self->{"labelsTxt"} = {};
	$self->{"helpsTxt"}  = {};
	$self->{"unitsTxt"} = {};

	# use default settings
	my $p = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnSettings\\DefaultSettings.txt";
	die "Global settings file: $p deosn't exist" unless ( -e $p );

	my @lines = @{ FileHelper->ReadAsLines($p) };

	my $labelText = "";
	my $helpText  = "";
	my $unitText  = "";

	foreach my $l (@lines) {

		if ( $l =~ /\[t.*=.*\]/ ) {
			$l =~ s/[\[\]]//ig;
			my @splited = split( "=", $l );
			$splited[1] =~ s/\n//g;
			$labelText = $splited[1]

		}
		elsif ( $l =~ /\[h.*=.*\]/ ) {
			$l =~ s/[\[\]]//ig;
			my @splited = split( "=", $l );
			$splited[1] =~ s/\n//g;
			$helpText = $splited[1];

		}
		elsif ( $l =~ /\[u.*=.*\]/ ) {
			$l =~ s/[\[\]]//ig;
			my @splited = split( "=", $l );
			$splited[1] =~ s/\n//g;
			$unitText = $splited[1];

		}
		elsif ( $l =~ /^[^\[#].*=.*/ ) {

			my @splited = split( "=", $l );

			my $key =~ s/\s//g;
 
			$self->{"labelsTxt"}->{ $key } = $labelText;
			$self->{"helpsTxt"}->{ $key }  = $helpText;
			$self->{"unitsTxt"}->{ $key }  = $unitText;

			$labelText = "";
			$helpText  = "";
			$unitText = "";
		}
	}

	return $self;
}

sub GetHelpText {
	my $self = shift;
	my $key  = shift;

	return $self->{"helpsTxt"}->{$key};
}

sub GetLabelText {
	my $self = shift;
	my $key  = shift;

	return $self->{"labelsTxt"}->{$key}

}

sub GetUnitText {
	my $self = shift;
	my $key  = shift;

	return $self->{"unitsTxt"}->{$key};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

