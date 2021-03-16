
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::MatrixSize;
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
	my $key   = Enums->SizePnlCreator_MATRIX;

	my $self = $class->SUPER::new( $inCAM, $jobId, $key );
	bless $self;

		# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"width"}       = undef;
	$self->{"settings"}->{"height"}      = undef;
	$self->{"settings"}->{"borderLeft"}  = undef;
	$self->{"settings"}->{"borderRight"} = undef;
	$self->{"settings"}->{"borderTop"}   = undef;
	$self->{"settings"}->{"borderBot"}   = undef;

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

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"width"} = $val;
}

sub GetWidth {
	my $self = shift;

	return $self->{"settings"}->{"width"};
}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"height"} = $val;
}

sub GetHeight {
	my $self = shift;

	return $self->{"settings"}->{"height"};
}

sub SetBorderLeft {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderLeft"} = $val;
}

sub GetBorderLeft {
	my $self = shift;

	return $self->{"settings"}->{"borderLeft"};
}

sub SetBorderRight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderRight"} = $val;
}

sub GetBorderRight {
	my $self = shift;

	return $self->{"settings"}->{"borderRight"};
}

sub SetBorderTop {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderTop"} = $val;
}

sub GetBorderTop {
	my $self = shift;

	return $self->{"settings"}->{"borderTop"};
}

sub SetBorderBot {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderBot"} = $val;
}

sub GetBorderBot {
	my $self = shift;

	return $self->{"settings"}->{"borderBot"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

