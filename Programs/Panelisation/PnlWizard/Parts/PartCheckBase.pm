
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::PartCheckBase;
use base 'Packages::InCAMHelpers::AppLauncher::PopupChecker::CheckClassBase';

#3th party library
use utf8;
use strict;
use warnings;

#local library
 
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class           = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $allCreatorModel = shift;
	my $self            = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	# PROPERTIES

	$self->{"inCAM"}           = $inCAM;
	$self->{"jobId"}           = $jobId;
	$self->{"allCreatorModel"} = $allCreatorModel;

	return $self;

}

 
sub _GetSelCreatorModelByPartId {
	my $self   = shift;
	my $partId = shift;

	return $self->{"allCreatorModel"}->{$partId};

}

return 1;
