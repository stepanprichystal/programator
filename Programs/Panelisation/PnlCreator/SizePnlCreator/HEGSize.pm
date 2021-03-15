
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::HEGSize;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::SizePnlCreator::ISize');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $key   = Enums->SizePnlCreator_HEG;

	my $self = $class->SUPER::new( $inCAM, $jobId, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{""} = undef;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self  = shift;
	my $inCAM = shift;

	my $result = 1;

	$self->{"settings"}->{"w"} = 20;
	$self->{"settings"}->{"h"} = 20;

	for ( my $i = 0 ; $i < 1 ; $i++ ) {

		$inCAM->COM("get_user_name");

		my $name = $inCAM->GetReply();

		print STDERR "\nHEG !! $name \n";

		sleep(1);

	}

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	for ( my $i = 0 ; $i < 1 ; $i++ ) {

		$inCAM->COM("get_user_name");

		my $name = $inCAM->GetReply();

		print STDERR "\nChecking  HEG !! $name \n";

		sleep(1);

	}

	$result = 0;
	$$errMess .= "Nelze vytvorit";

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	for ( my $i = 0 ; $i < 1 ; $i++ ) {

		$inCAM->COM("get_user_name");

		my $name = $inCAM->GetReply();

		print STDERR "\nProcessing  HEG !! $name \n";
		die "test";
		sleep(1);

	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub Set {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{""} = $val;

}

sub Get {
	my $self = shift;

	return $self->{"settings"}->{""};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

