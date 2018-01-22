
#-------------------------------------------------------------------------------------------#
# Description: Inherit class, which help save keys and values to template
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::MailTemplate::TemplateKey;
use base("Packages::Other::HtmlTemplate::TemplateKeyBase");


use Class::Interface;
&implements('Packages::Other::HtmlTemplate::ITemplateKey');

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $self      = $class->SUPER::new(@_ );
	bless $self;
 
	return $self;    # Return the reference to the hash.
}

# Method allow set key and values to this class
sub SetKey{
	my $self      = shift;
	my $key      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData($key, $en, $cz);
}
 
sub SetAppName{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("AppName", $en, $cz);
} 

 
sub SetMessageType{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("MessageType", $en, $cz);
} 

sub SetMessageTypeClr{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("MessageTypeClr", $en, $cz);
} 

 
 
sub SetTaskType{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("TaskType", $en, $cz);
}

sub SetJobId{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("JobId", $en, $cz);
}


sub SetJobAuthor{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("JobAuthor", $en, $cz);
}

sub SetMessage{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("Message", $en, $cz);
}

 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

