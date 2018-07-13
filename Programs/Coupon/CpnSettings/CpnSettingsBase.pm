
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnSettings::CpnSettingsBase;

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

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

	# Load settings if defined

	$self->{"sett"} = {};

	# use default settings
	my $p = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnSettings\\DefaultSettings.txt";
	die "Global settings file: $p deosn't exist" unless ( -e $p );

	my @lines = @{ FileHelper->ReadAsLines($p) };

	foreach my $l (@lines) {

		if ( $l =~ /.*=.*/ ) {

			my @splited = split( "=", $l );

			$splited[0] =~ s/\s//g;
			$splited[1] =~ s/\s//g;

			$splited[1] =~ s/#.*//i;

			$self->{"sett"}->{ $splited[0] } = $splited[1];
		}
	}

	return $self;

}

# Return deep current settings
# whole object is deep copy, no reference on source instance
sub GetDeepCopy {
	my $self = shift;

	my $sett = dclone($self);

	return $sett;
}

# Update settings by another settings instance
sub UpdateSettings {
	my $self     = shift;
	my $settings = shift;

	$self->{"sett"} = $settings->{"sett"};
}

sub _GetVal {
	my $self = shift;
	my $key  = shift;

	my $v = $self->{"sett"}->{$key};

	die "Value of key: $key is not defined" unless ( defined $v );

	return $v;
}

sub _SetVal {
	my $self = shift;
	my $key  = shift;
	my $val  = shift;

	die "Key  is not defined"   unless ( defined $key );
	die "Value  is not defined" unless ( defined $val );

	$self->{"sett"}->{$key} = $val;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

