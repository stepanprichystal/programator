
#-------------------------------------------------------------------------------------------#
# Description: Open/send mail in outlook
# Author:SPR
#-------------------------------------------------------------------------------------------#

#  ============  HOW to use system call ====================

#	my $script = "../Packages/SystemCall/Exmaple.pl";
#	my %hash   = ( "k" => "1" );
#	my @cmds   = ( "par1", "par2", \%hash );
#
#	my $call = SystemCall->new( $script, \@cmds );
#	my $result = $call->Run();
#
#	my %output = $call->GetOutput();

#3th party library
use threads;
use strict;
use warnings;
use Mail::Outlook;

# These 2 lines below are necessary in order show email in UTF8
use Win32::OLE 'CP_UTF8';

# Set the code page of Win32::OLE.
$Win32::OLE::CP = CP_UTF8;

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $output      = shift(@_);    # save here output message (hash reference)
my $to          = shift(@_);
my $cc          = shift(@_);
my $subject     = shift(@_);
my $body        = shift(@_);
my $attachments = shift(@_);
my $type        = shift(@_);    # send/open

#print "to:" . $to . "\n";
#print "cc:" . $cc . "\n";
#print "sub:" . $subject . "\n";
#print "bod" . $body . "\n";
#print "att:" . $attachments->[0] . $attachments->[1] . "\n";
#print "type:" . $type . "\n";

my $outlook = new Mail::Outlook();
my $message = $outlook->create();

# Set adresses
$message->To( join( ";", @{$to} ) ) if ( defined $to );
$message->Cc( join( ";", @{$cc} ) ) if ( defined $cc );

# Set subject
$message->Subject($subject);

# Set body
 
 $message->Body($body);
 

foreach my $attach ( @{$attachments} ) {

	$message->Attach($attach);
}

if ( $type eq "open" ) {
	$output->{"myResult"} = $message->display;
}
else {
	$output->{"myResult"} = $message->send;
}

1;
