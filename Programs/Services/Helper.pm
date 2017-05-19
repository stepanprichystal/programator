#-------------------------------------------------------------------------------------------#
# Description: Helper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::Helper;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library

use aliased 'Packages::Other::AppConf';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
# Set logging, errors are loged to file defined by config
# All STDERR + STDOUT are printed to another log file too
sub SetLogging {
	my $self       = shift;
	my $logDir     = shift;
	my $maxLogSize = shift;    # in MB
	


	# 1) Create dir
	unless ( -e $logDir ) {
		mkdir($logDir) or die "Can't create dir: " . $logDir . $_;
	}

	# 2) Log controled
	my $mainLogger = get_logger("serviceLog");
	$mainLogger->level($DEBUG);

	# Appenders
	my $appenderFile = Log::Log4perl::Appender->new(
		'Log::Log4perl::Appender::File::FixedSize',
		filename => $logDir . "\\log.txt",
		#mode     => "append",
		size => $maxLogSize . "Mb"
	);

	my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %p> %F{1}:%L  %M \n- %m%n \n");
	$appenderFile->layout($layout);
	$mainLogger->add_appender($appenderFile);

		

	# 2) Log all output on STDERR + STDOUT
	my $mainLoggerOut = get_logger("stdOutput");
	$mainLoggerOut->level($DEBUG);

	# Appenders
	my $appenderFileOut = Log::Log4perl::Appender->new(
		'Log::Log4perl::Appender::File::FixedSize',
		filename =>  $logDir . "\\logAllOutput.txt",
		#mode     => "append",
		size => $maxLogSize . "Mb"
	);
	

	my $layoutOut = Log::Log4perl::Layout::PatternLayout->new("%d> %m%n ");
	$appenderFileOut->layout($layoutOut);
	$mainLoggerOut->add_appender($appenderFileOut);

	tie *STDERR, "Trapper";
	tie *STDOUT, "Trapper";
}


########################################
# this class is connected to stderr or stdout and catch print which send to log
package Trapper;
########################################

#use Log::Log4perl qw(:easy);
use Log::Log4perl qw(get_logger :levels);

sub TIEHANDLE {
	my $class = shift;
	bless [], $class;
}

sub PRINT {
	my $self = shift;

	# $Log::Log4perl::caller_depth++;
	#DEBUG @_;
	#$Log::Log4perl::caller_depth--;
	get_logger("stdOutput")->error(@_);
}

1;
