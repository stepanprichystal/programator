#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::SettingsHelper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"serverMngr"} = shift;
	my $packageFull = shift;    # name of AsyncJobMngr child. Used for log file name..

	my $package = ( split '::', $packageFull )[-1];
	$self->{"logPath"} = EnumsPaths->Client_INCAMTMPJOBMNGR . $package;

	$self->__SetDefault();

	return $self;
}

sub __SetDefault {
	my $self = shift;

	my $maxCntUser;
	my $destroyDelay;

	my $f;

	unless ( -e $self->{"logPath"} ) {

		$maxCntUser   = 5;
		$destroyDelay = 60;

		open( $f, ">", $self->{"logPath"} );
		print $f "maxCntUser = $maxCntUser\n";
		print $f "destroyDelay = $destroyDelay\n";
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
				
				($destroyDelay)  = $lines[$i] =~ /(\d+)/;
				next;
			}
		}
	}

	$self->{"serverMngr"}->SetDestroyDelay($destroyDelay);
	$self->{"serverMngr"}->SetMaxServerCount($maxCntUser);
}

sub SetMaxServerCount {
	my $self       = shift;
	my $maxCntUser = shift;

	my $f;

	open( $f, "<", $self->{"logPath"} );
	my @lines = <$f>;
	close($f);
	unlink( $self->{"logPath"} );

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		if ( $lines[$i] =~ /maxCntUser/ ) {

			$lines[$i] = "maxCntUser = $maxCntUser\n";
			last;
		}
	}

	open( $f, ">", $self->{"logPath"} );
	print $f @lines;
	close($f);

	$self->{"serverMngr"}->SetMaxServerCount($maxCntUser);
}

sub SetDestroyDelay {
	my $self         = shift;
	my $destroyDelay = shift;    # in second

	my $f;

	open( $f, "<", $self->{"logPath"} );
	my @lines = <$f>;
	close($f);
	unlink( $self->{"logPath"} );

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		if ( $lines[$i] =~ /destroyDelay/ ) {

			$lines[$i] = "destroyDelay = $destroyDelay\n";
			last;
		}
	}

	open( $f, ">", $self->{"logPath"} );
	print $f @lines;
	close($f);

	$self->{"serverMngr"}->SetDestroyDelay($destroyDelay);
}

1;
