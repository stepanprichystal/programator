
#-------------------------------------------------------------------------------------------#
# Description: Allow add application, and do tracking "app" status every second
# If Condition is fulfiled, special action is launched
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::AppChecker::AppChecker;

#3th party library
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Other::AppChecker::Helper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"apps"}    = [];
	$self->{"logPath"} = "\\\\gatema.cz\\fs\\r\\pcb\\pcb\\appLogs\\";

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

	my %appInf = ();
	$appInf{"appName"}   = $appName;
	$appInf{"appCond"}   = $appCondition;
	$appInf{"appAction"} = $appAction;

	push( @{ $self->{"apps"} }, \%appInf );

}

sub Run {
	my $self = shift;

	while (1) {

		foreach my $app ( @{ $self->{"apps"} } ) {

			if ( $app->{"appCond"}->( $self, $app ) ) {

				$app->{"appAction"}->( $self, $app );

			}

		}

	}

}

sub CreateLogPath {
	my $self    = shift;
	my $appName = shift;

	$appName =~ s/\s//g;
	my $logname = $ENV{USERNAME};
	
	my $d = DateTime->now;
 
	my $p = $self->{"logPath"} . $appName . "_" . $d->ymd('-')."_".$d->hms('-') . "_" . $logname;

	unless ( -e $p ) {
		mkdir($p) or die "Can't create dir: " . $p;
	}
  
	return $p;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

