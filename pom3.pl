#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use utf8;
use strict;
use warnings;

use Win32::GuiTest qw(FindWindowLike GetWindowText GetDesktopWindow GetScreenRes SendKeys SendRawKey :VK SetActiveWindow SetFocus SendMessage);

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

my $jobId = "d222606";

my $pnlWizard      = GetWindowByTitle(qr/^Panelisation.*${jobId}/i);
my $pnlWizardInCAM = GetWindowByTitle(qr/InCAM.*PID.*${jobId}/i);

if ( defined $pnlWizard && defined $pnlWizardInCAM ) {

	 SendMessage($pnlWizard, 0x0112, 0xF030, 0);
	  SendMessage($pnlWizardInCAM, 0x0112, 0xF030, 0);
	 #   SendMessage($pnlWizardInCAM, 0xF040, 0xF160, 0);
	 
	  
	SetFocus($pnlWizard);
	SendRawKey( VK_LWIN, 0 );
	SendKeys("{LEFT}");
	SendRawKey( VK_LWIN, KEYEVENTF_KEYUP );
	
#	SetFocus($pnlWizardInCAM);
#
#	#SetActiveWindow($pnlWizard);
#
#	SendRawKey( VK_LWIN, 0 );
#	SendKeys("{RIGHT}");
#	SendRawKey( VK_LWIN, KEYEVENTF_KEYUP );

	die;

}
else {

	print STDERR "Windows not found";
}

#foreach my $pid (@jobId){
#
#	Win32::Process::KillProcess( $pid, 0 );
#}

# Return InCAM editor PIDS, based on jobId in windows title
sub GetWindowByTitle {

	my $regexp = shift;

	my $win = undef;

	my @windows = FindWindowLike( 0, $jobId );
	foreach my $win (@windows) {

		my $winTitle = GetWindowText($win);

		if ( $winTitle =~ m/$regexp/ ) {

			return $win;
		}

	}
}
