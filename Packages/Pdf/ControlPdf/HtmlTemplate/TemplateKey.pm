
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::HtmlTemplate::TemplateKey;
use base("Packages::Pdf::Template2Pdf::TemplateKeyBase");


use Class::Interface;
&implements('Packages::Pdf::Template2Pdf::ITemplateKey');

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

sub SetJobId{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("JobId", $en, $cz);
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

