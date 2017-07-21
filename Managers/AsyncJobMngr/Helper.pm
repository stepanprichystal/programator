#-------------------------------------------------------------------------------------------#
# Description: Helper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::Helper;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Sys::Hostname;

#local library

use aliased 'Packages::Other::AppConf';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::AsyncJobMngr::Enums';
use aliased 'Packages::Other::AppConf';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return file name from full path
sub Print {

	my $self = shift;
	my $mess = shift;

	print STDERR '====== E X P O R T ======= ' . $mess;
}

#Return file name from full path
sub PrintServer {

	my $self = shift;
	my $mess = shift;

	print STDERR '====== E X P O R T ======= ' . $mess;
}

sub SetLogging {
	my $self = shift;

	my $dir = $self->GetLogDir();

	unless ( -e $dir ) {
		mkdir($dir) or die "Can't create dir: " . $dir . $_;
	}

	$self->__CreateLogger( Enums->Logger_APP );
	$self->__CreateLogger( Enums->Logger_SERVERTH );
	$self->__CreateLogger( Enums->Logger_TASKTH );
	$self->__CreateLogger( Enums->Logger_INCAM );
}

sub __CreateLogger {
	my $self       = shift;
	my $loggerName = shift;

	my $mainLogger = get_logger($loggerName);
	$mainLogger->level($DEBUG);

	my $path = $self->GetLogDir() . "\\$loggerName";

	# Appenders
	my $appenderFile = Log::Log4perl::Appender->new(
													 'Log::Dispatch::File',
													 filename => $path,
													 mode     => "write"
	);

	my $appenderScreen = Log::Log4perl::Appender->new(
													   'Log::Dispatch::Screen',
													   min_level => 'debug',
													   stderr    => 1,
													   newline   => 1
	);

	my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %p> %F{1}:%L  %M \n- %m%n \n");
	$appenderFile->layout($layout);
	$appenderScreen->layout($layout);

	$mainLogger->add_appender($appenderFile);
	$mainLogger->add_appender($appenderScreen);

}

sub GetLogDir {
	my $self = shift;

	my $appName = AppConf->GetValue("appName");

	$appName =~ s/\s//g;

	my $dir = EnumsPaths->Client_INCAMTMPJOBMNGR . $appName . "Logs";

	return $dir;
}

# Return if actual program is running on server (server name is defined in config)
sub ServerVersion {
	my $self = shift;

	my $serverName = AppConf->GetValue("serverName");

	# If runining on server, close directly
	if ( hostname =~ /$serverName/i ) {
		return 1;
	}
	else {
		return 0;
	}
}

1;
