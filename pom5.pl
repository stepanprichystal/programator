#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Win32::Process;
	use Config;
	my $processObj;
	my $perl = $Config{perlpath};

	my @cmd = ("perl");
	push( @cmd, 'y:\server\site_data\Scripts\Programs\Panelisation\PnlWizard\RunPnlWizard\RunWizardApp_tmp.pl' );
	 

	my $cmdStr = join( " ", @cmd );
	my $newConsole = 1;
	Win32::Process::Create( $processObj, $perl, $cmdStr, 0, ( $newConsole ? CREATE_NO_WINDOW : THREAD_PRIORITY_NORMAL ), "." )
	  || die "$!\n";

	$processObj->Wait(INFINITE);