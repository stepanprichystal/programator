
#-------------------------------------------------------------------------------------------#
# Description: Helper for InCAMCall class
# DO NOT USE WITH THREADS !!!!
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::Win32Helper;

#3th party library
use strict;
use Log::Log4perl qw(get_logger :levels);
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);
use Win32::Process;
use Win32::Process::Info;
use Win32::Process::List;
use Getopt::Std;
use Win32::Console;

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#


sub ShowWindowByTitle {
	my $self  = shift;
	my $show  = shift;
	my $title = shift;

	my @windows = FindWindowLike( 0, $title );
	for (@windows) {

		ShowWindow( $_, $show );

		return 1;
	}

	return 0;
}

 


sub CheckRunningInstance {
	my $self       = shift;
	my $scriptName = shift;    # name of running script

	my $exist = 0;

	my $procName;
	my $args;
	my $p    = Win32::Process::List->new();
	my $pi   = Win32::Process::Info->new();
	my %list = $p->GetProcesses();

	foreach my $pid ( sort { $a <=> $b } keys %list ) {
		$procName = $list{$pid};

		if ( $procName =~ /^perl.exe/i ) {

			my $procInfo = $pi->GetProcInfo($pid);
			if ( defined $procInfo && scalar( @{$procInfo} ) ) {

				$args = @{$procInfo}[0]->{"CommandLine"};

				if ( defined $args && $args =~ /$scriptName/ ) {

					$exist = 1;
					last;
				}
			}
		}

	}

	return $exist;
}


sub GetRunningInstanceCnt {
	my $self       = shift;
	my $scriptName = shift;    # name of running script

	my $cnt = 0;

	my $procName;
	my $args;
	my $p    = Win32::Process::List->new();
	my $pi   = Win32::Process::Info->new();
	my %list = $p->GetProcesses();

	foreach my $pid ( sort { $a <=> $b } keys %list ) {
		$procName = $list{$pid};

		if ( $procName =~ /^perl.exe/i ) {

			my $procInfo = $pi->GetProcInfo($pid);
			if ( defined $procInfo && scalar( @{$procInfo} ) ) {

				$args = @{$procInfo}[0]->{"CommandLine"};

				if ( defined $args && $args =~ /$scriptName/ ) {

					

					$cnt++;
					
					print STDERR "\nprog $args - $cnt\n";
				}
			}
		}

	}

	 

	return $cnt;
}


sub SetConsoleTitle{
	my $self = shift;
	my $title = shift;
	
	my $console = Win32::Console->new;

	$console->Title( $title );
}


#sub SetLogging {
#	my $self       = shift;
#	 
#
#	# 1) Create dir
#	unless ( -e $logDir ) {
#		mkdir($logDir) or die "Can't create dir: " . $logDir . $_;
#	}
#
#	# 2) Log controled
#	my $mainLogger = get_logger("serverLog");
#	$mainLogger->level($DEBUG);
#
#	# Appenders
#	my $appenderFile = Log::Log4perl::Appender->new(
#		'Log::Log4perl::Appender::File::FixedSize',
#		filename => $logDir . "\\log.txt",
#
#		#mode     => "append",
#		size => $maxLogSize . "Mb"
#	);
#
#	my $appenderScreen = Log::Log4perl::Appender->new(
#													   'Log::Dispatch::Screen',
#													   min_level => 'debug',
#													   stderr    => 1,
#													   newline   => 1
#	);
#
#	my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %p> %F{1}:%L  %M \n- %m%n \n");
#	$appenderFile->layout($layout);
#	$appenderScreen->layout($layout);
#	$mainLogger->add_appender($appenderFile);
#	$mainLogger->add_appender($appenderScreen);
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

