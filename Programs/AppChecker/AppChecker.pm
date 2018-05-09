
#-------------------------------------------------------------------------------------------#
# Description: Allow add application, and do tracking "app" status every second
# If Condition is fulfiled, special action is launched
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::AppChecker::AppChecker;

#3th party library
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::AppChecker::Helper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"apps"}      = [];
	$self->{"logPath"}   = EnumsPaths->App_LOGS;
	$self->{"maxLogCnt"} = 1000;                   # period which appa are checked
	$self->{"period"}    = 2;                      # period which appa are checked

	unless ( -e $self->{"logPath"} ) {
		mkdir( $self->{"logPath"} ) or die "Can't create dir: " . $self->{"logPath"};
	}

	return $self;
}

# Return if exist customer record in db
sub AddApp {
	my $self         = shift;
	my $appName      = shift;
	my $appCondition = shift;
	my $appAction    = shift;
	my $appData      = shift;    # helper data for app

	my %appInf = ();
	$appInf{"appName"}   = $appName;
	$appInf{"appCond"}   = $appCondition;
	$appInf{"appAction"} = $appAction;
	$appInf{"appData"}   = $appData;

	push( @{ $self->{"apps"} }, \%appInf );

}

sub Run {
	my $self = shift;

	# check if another app is not running

	while (1) {

		my @files = ();
		opendir( DIR, $self->{"logPath"} ) or die $!;
		
		while ( my $file = readdir(DIR) ) {

			next if ( $file =~ m/^\./ );
			push( @files, $file );
		}

		closedir(DIR);

		# test if many logs
		if ( scalar(@files) > $self->{"maxLogCnt"} ) {
			last;
		}

		# Test if there is too many logs
		# If more than 100,

		foreach my $app ( @{ $self->{"apps"} } ) {

			# store only one log from one app and one user per hour

			#if ( $app->{"appCond"}->( $self, $app ) ) {
			if (1) {

				next if ( $self->__SameLogExist( $app->{"appName"}, \@files ) );

				my $p = $self->__CreateLogPath( $app->{"appName"} );

				$app->{"appAction"}->( $self, $app, $p );
			}
		}

		sleep( $self->{"period"} );
	}

}

sub __CreateLogPath {
	my $self    = shift;
	my $appName = shift;
 
	my $logname = $ENV{USERNAME};

 
	my $p = $self->{"logPath"} . $self->__GetLogName($appName);
	unless ( -e $p ) {
		mkdir($p) or die "Can't create dir: " . $p;
	}

	return $p;
}

sub __GetLogName {
	my $self    = shift;
	my $appName = shift;

	$appName =~ s/\s//g;
	my $logname = $ENV{USERNAME};

	my $d = DateTime->now("time_zone" => 'Europe/Prague');

	return $appName . "_" . $d->ymd('-') . "_" . $d->hms('-') . "_" . $logname;

}

# Return if same log exist for one app in one hour from same user
sub __SameLogExist {
	my $self    = shift;
	my $appName = shift;
	my @files   = @{ shift(@_) };

	my $logName = $self->__GetLogName($appName);

	my ( $AppName, $y, $m, $d, $h, $user ) = $logName =~ /(.*)_(\d+)-(\d+)-(\d+)_(\d+).*_(\w+)/i;

	my $logExist = 0;

	foreach my $f (@files) {

		if ( $f =~ m/(.*)_(\d+)-(\d+)-(\d+)_(\d+).*_(\w+)/i ) {

			if ( $AppName eq $1 && $y == $2 && $m == $3 && $d == $4 && $h == $5 && $user eq $6 ) {
				$logExist = 1;
				last;
			}
		}
	}

	return $logExist;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

