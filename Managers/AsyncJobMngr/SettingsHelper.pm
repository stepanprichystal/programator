#-------------------------------------------------------------------------------------------#
# Description: Helper, which is responsible for saving/reading AszynMngr settings
# to/from file located in temporary dirs
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::SettingsHelper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::AsyncJobMngr::AppConf';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"serverMngr"} = shift;
	my $packageFull = shift;    # name of AsyncJobMngr child. Used for log file name..

	my $fileName = AppConf->GetValue("appName");
	$fileName =~ s/\s//g;
	$self->{"logPath"} = EnumsPaths->Client_INCAMTMPJOBMNGR . $fileName;

	$self->__SetDefault();

	return $self;
}

# Set default Mngr settings, if no settings was set before
sub __SetDefault {
	my $self = shift;

	my $maxCntUser;
	my $destroyDelay;
	my $destroyOnDemand;
	my $f;

	unless ( -e $self->{"logPath"} ) {

		$maxCntUser      = 2;
		$destroyDelay    = 120;
		$destroyOnDemand = 1;

		open( $f, ">", $self->{"logPath"} );
		print $f "maxCntUser = $maxCntUser\n";
		print $f "destroyDelay = $destroyDelay\n";
		print $f "destroyOnDemand = $destroyOnDemand\n";

		close($f);

	}
	else {

		open( $f, "<", $self->{"logPath"} );
		my @lines = <$f>;
		close($f);

		for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

			if ( $lines[$i] =~ /maxCntUser/ ) {

				($maxCntUser) = $lines[$i] =~ /(\d+)/;
				next;
			}
			if ( $lines[$i] =~ /destroyDelay/ ) {

				($destroyDelay) = $lines[$i] =~ /(\d+)/;
				next;
			}
			if ( $lines[$i] =~ /destroyOnDemand/ ) {

				($destroyOnDemand) = $lines[$i] =~ /(\d+)/;
				next;
			}
		}
	}

	$self->{"serverMngr"}->SetDestroyDelay($destroyDelay);
	$self->{"serverMngr"}->SetMaxServerCount($maxCntUser);
	$self->{"serverMngr"}->SetDestroyOnDemand($destroyOnDemand);

}

sub SetMaxServerCount {
	my $self       = shift;
	my $maxCntUser = shift;

	$self->__SetAttribute( "maxCntUser", $maxCntUser );

	$self->{"serverMngr"}->SetMaxServerCount($maxCntUser);
}

sub SetDestroyDelay {
	my $self         = shift;
	my $destroyDelay = shift;    # in second

	$self->__SetAttribute( "destroyDelay", $destroyDelay );

	$self->{"serverMngr"}->SetDestroyDelay($destroyDelay);
}

sub SetDestroyOnDemand {
	my $self            = shift;
	my $destroyOnDemand = shift;    # in second

	$self->__SetAttribute( "destroyOnDemand", $destroyOnDemand );

	$self->{"serverMngr"}->SetDestroyOnDemand($destroyOnDemand);
}

sub __SetAttribute {
	my $self      = shift;
	my $attribute = shift;
	my $value     = shift;

	my $f;

	open( $f, "<", $self->{"logPath"} );
	my @lines = <$f>;
	close($f);
	unlink( $self->{"logPath"} );

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		if ( $lines[$i] =~ /$attribute/ ) {
			$lines[$i] = "$attribute = $value\n";
			last;
		}
	}

	open( $f, ">", $self->{"logPath"} );
	print $f @lines;
	close($f);

}

1;
