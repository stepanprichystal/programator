
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
  
	$self->{"labelsTxt"} = {};  
	$self->{"helpsTxt"}  = {};
	$self->{"unitsTxt"}  = {};

	# Load all settings
	my $p = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnSettings\\DefaultSettings\\";
	die "Global settings file: $p deosn't exist" unless ( -e $p );

	opendir( DIR, $p ) or die $!;

	while ( my $file = readdir(DIR) ) {

		if ( $file =~ /\w+settings\.txt/i ) {
 
			$self->__LoadSettings($p . $file);
		}
	}

	close(DIR);

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

sub __LoadSettings {
	my $self = shift;
	my $file = shift;

	my @lines = @{ FileHelper->ReadAsLines($file) };

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

			$l =~ s/\s//g;
			my @splited = split( "=", $l );

			$self->{"labelsTxt"}->{ $splited[0] } = $labelText;
			$self->{"helpsTxt"}->{ $splited[0] }  = $helpText;
			$self->{"unitsTxt"}->{ $splited[0] }  = $unitText;

			$labelText = "";
			$helpText  = "";
			$unitText  = "";
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

