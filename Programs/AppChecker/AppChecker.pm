
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
	$self->{"logPath"}   = "\\\\gatema.cz\\fs\\r\\pcb\\pcb\\appLogs\\";
	$self->{"maxLogCnt"} = 100;                                           # period which appa are checked
	$self->{"period"}    = 2;                                             # period which appa are checked

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

	my $dir   = $self->{"logPath"};
	my @files = <$dir/*>;
	my $count = @files;

#	while ( 1) {
#
#		# test if many logs
#		if ( $count > $self->{"maxLogCnt"} ) {
#			return 0;
#		}
#
#		# Test if there is too many logs
#		# If more than 100,
#
#		foreach my $app ( @{ $self->{"apps"} } ) {
#
#			# store only one log from one app and one user per hour
#			my $logName = __GetLogName($app->{"appName"});
#			
#			
#			
#			if ( $app->{"appCond"}->( $self, $app ) ) {
#
#				$app->{"appAction"}->( $self, $app );
#			}
#		}
#		
#		sleep($self->{"period"} );
#	}

}

sub CreateLogPath {
	my $self    = shift;
	my $appName = shift;

	$appName =~ s/\s//g;
	my $logname = $ENV{USERNAME};

	my $d = DateTime->now;

	my $p = $self->{"logPath"} . $appName . "_" . $d->ymd('-') . "_" . $d->hms('-') . "_" . $logname;

	unless ( -e $p ) {
		mkdir($p) or die "Can't create dir: " . $p;
	}

	return $p;
}

sub __GetLogName{
	my $self    = shift;
	my $appName = shift;

	$appName =~ s/\s//g;
	my $logname = $ENV{USERNAME};

	my $d = DateTime->now;
 
	return $appName . "_" . $d->ymd('-') . "_" . $d->hms('-') . "_" . $logname;
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

