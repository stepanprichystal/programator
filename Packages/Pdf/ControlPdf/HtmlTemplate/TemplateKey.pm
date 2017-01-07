
#-------------------------------------------------------------------------------------------#
# Description: Inherit class, which help save keys and values to template
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

# Method allow set key and values to this class
sub SetKey{
	my $self      = shift;
	my $key      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData($key, $en, $cz);
}
 






























sub SetJobId{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("JobId", $en, $cz);
}

sub SetPreviewTop{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("PreviewTop", $en, $cz);
}

sub SetPreviewBot{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("PreviewBot", $en, $cz);
}

sub SetPreviewStackup{
	my $self      = shift;
	my $en      = shift;
	my $cz      = shift;
	
	$self->_SaveKeyData("PreviewStackup", $en, $cz);
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

