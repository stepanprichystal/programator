
#-------------------------------------------------------------------------------------------#
# Description: Check class for checking before processing panel creator
# Class should contain OnItemResult event
# Class must implement ICheckClass
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SchemePart::Control::SchemePartCheck;
use base 'Packages::InCAMHelpers::AppLauncher::PopupChecker::CheckClassBase';

use Class::Interface;

&implements('Packages::InCAMHelpers::AppLauncher::PopupChecker::ICheckClass');

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $self    = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	# PROPERTIES

	$self->{"inCAM"}   = $inCAM;
	$self->{"jobId"}   = $jobId;
	

	return $self;

}

# Do check of creator settings and part settings
sub Check {
	my $self  = shift;
	my $model = shift;

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	
	$inCAM->COM("get_user_name");

	for(my $i= 0; $i  < 2; $i++){
		
		print STDERR "check";
		sleep(1);
	}
	#die "chyba scriptu.";
	
	 
	#if ( $model->GetWidth() > 10 ) {

		#$self->_AddError( "Velikost", "Nelze".$inCAM->GetReply() );
	#}
}
