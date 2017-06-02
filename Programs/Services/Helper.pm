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
	my $logConfDir = shift;
	 
	# 1) Create dir
	unless ( -e $logDir ) {
		mkdir($logDir) or die "Can't create dir: " . $logDir . $_;
	}

	# 2) Log controled
	Log::Log4perl->init( $logConfDir."\\Logger.conf" );
  
}

1;