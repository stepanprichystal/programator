
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading stencil serialization data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::CpnConfigMngr::CpnConfigMngr;
use base('Packages::ObjectStorable::JsonStorable::JsonStorableMngr');

#3th party library
use strict;
use warnings;
use utf8;
use JSON;
use DateTime;

#local library

use aliased "Enums::EnumsPaths";
use aliased "Helpers::FileHelper";
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';
use aliased 'Programs::Coupon::CpnWizard::CpnConfigMngr::CpnConfig';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $jobId = shift;
	my $path  = EnumsPaths->Client_INCAMTMPIMPGEN . $jobId;

	my $self = $class->SUPER::new($path);
	bless $self;

	$self->{"restoredConfig"} = undef;

	FileHelper->DeleteTempFilesFrom( EnumsPaths->Client_INCAMTMPIMPGEN, 3600 * 24 );    #delete 24 hours old settings

	return $self;
}

sub ConfigFileExist {
	my $self = shift;

	return $self->SerializedDataExist();
}

sub GetConfigFilePath {
	my $self = shift;

	return $self->{"filePath"};

}

sub GetConfigFileDate {
	my $self = shift;
	my $time = shift // 1;
	my $date = shift // 0;

	die "Time or Date argument has to be 1" if ( !$time && !$date );

	my @stats       = stat( $self->{"filePath"} );
	my $fileCreated = $stats[9];

	my $dt = DateTime->from_epoch( epoch => $fileCreated, "time_zone" => 'Europe/Prague' );

	my $str = "";
	$str = $dt->hms() if ($time);
	$str = $dt->dmy() if ($date);
	$str = $dt->hms() . " " . $dt->dmy() if ( $time && $date );

	return $str;
}

# Load serialized cpn config data
sub LoadConfig {
	my $self = shift;

	$self->{"restoredConfig"} = $self->LoadData();

	if ( defined $self->{"restoredConfig"} ) {
		return 1;
	}
	else {
		return 0;
	}

}

# Serialize and store cpn config data
sub SaveConfig {
	my $self           = shift;
	my $userFilter     = shift;    # keys represent strip id and value if strip is used in coupon
	my $userGroups     = shift;    # contain strips splitted into group. Key is strip id, val is group number
	my $globalSett     = shift;    # global settings of coupon
	my $cpnGroupSett   = shift;    # group settings for each group
	my $cpnStripSett   = shift;    # strip settings for each strip by constraint id
	my $cpnConstraints = shift;		# Constraints from CpnSource


	my %constrInfo = ();
	foreach my $c  (@{$cpnConstraints}){
	
		my %inf = ();
		$inf{"type"} = $c->GetType();
		$inf{"model"} = $c->GetModel();
		$inf{"layer"} = $c->GetTrackLayer();
		$constrInfo{$c->GetId()} = \%inf;
	}
 
	my $cpnConfig = CpnConfig->new( $userFilter, $userGroups, $globalSett, $cpnGroupSett, $cpnStripSett, \%constrInfo );

	# create dir path unless exist
	unless ( -e EnumsPaths->Client_INCAMTMPIMPGEN ) {
		mkdir( EnumsPaths->Client_INCAMTMPIMPGEN ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPIMPGEN . $_;
	}

	if ( $self->StoreData($cpnConfig) ) {

		$self->{"restoredConfig"} = undef;
		return 1;

	}
	else {
		return 0;
	}
}

#-------------------------------------------------------------------------------------------#
#  Method which return restored cpn config data
#-------------------------------------------------------------------------------------------#

sub GetUserFilter {
	my $self = shift;

	die "Config data are not restored" if ( !defined $self->{"restoredConfig"} );

	return $self->{"restoredConfig"}->GetUserFilter();
}

sub GetUserGroups {
	my $self = shift;

	die "Config data are not restored" if ( !defined $self->{"restoredConfig"} );

	return $self->{"restoredConfig"}->GetUserGroups();
}

sub GetGlobalSett {
	my $self = shift;

	die "Config data are not restored" if ( !defined $self->{"restoredConfig"} );

	return $self->{"restoredConfig"}->GetGlobalSett();
}

sub GetCpnStripSett {
	my $self = shift;

	die "Config data are not restored" if ( !defined $self->{"restoredConfig"} );

	return $self->{"restoredConfig"}->GetCpnStripSett();
}

sub GetCpnGroupSett {
	my $self = shift;

	die "Config data are not restored" if ( !defined $self->{"restoredConfig"} );

	return $self->{"restoredConfig"}->GetCpnGroupSett();
}

sub GetCpnConstraints {
	my $self = shift;

	die "Config data are not restored" if ( !defined $self->{"restoredConfig"} );

	return $self->{"restoredConfig"}->GetCpnConstraints();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Coupon::CpnWizard::CpnConfigMngr::CpnConfigMngr';
	use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
	use aliased 'Programs::Coupon::CpnWizard::CpnConfigMngr::CpnConfig';

	my $configMngr = CpnConfigMngr->new("d113608");

	my $sett = CpnSettings->new();

	$configMngr->SaveConfig( undef, undef, $sett );

	if ( $configMngr->LoadConfig() ) {

		my $sett = $configMngr->GetGlobalSett();

		print $sett;

	}

}

1;

