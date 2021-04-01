
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::HEGSize;
use base('Programs::Panelisation::PnlCreator::SizePnlCreator::SizeCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::SizePnlCreator::ISize');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->SizePnlCreator_USER;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"ISDimensionFilled"} = undef;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	my $result = 1;

	$self->_Init( $inCAM, $stepName );

	my $jobId = $self->{"jobId"};

	my $dim = HegMethods->GetInfoDimensions($jobId);

	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		$self->{"settings"}->{"width"}  = $dim->{"panel_x"} if ( defined $dim->{"panel_x"} );
		$self->{"settings"}->{"height"} = $dim->{"panel_y"} if ( defined $dim->{"panel_y"} );

		if (    defined $dim->{"panel_x"}
			 && $dim->{"panel_x"} > 0
			 && defined $dim->{"panel_y"}
			 && $dim->{"panel_y"} > 0 )
		{

			$self->SetISDimensionFilled(1);
		}
		else {

			$self->SetISDimensionFilled(0);
		}

	}    # Load panel size from HEG
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		$self->{"settings"}->{"width"}  = $dim->{"rozmer_x"} if ( defined $dim->{"rozmer_x"} );
		$self->{"settings"}->{"height"} = $dim->{"rozmer_y"} if ( defined $dim->{"rozmer_y"} );

		if (    defined $dim->{"rozmer_x"}
			 && $dim->{"rozmer_x"} > 0
			 && defined $dim->{"rozmer_y"}
			 && $dim->{"rozmer_y"} > 0 )
		{

			$self->SetISDimensionFilled(1);
		}
		else {

			$self->SetISDimensionFilled(0);
		}
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

	$result = $self->_Check( $inCAM, $errMess );

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	#	for ( my $i = 0 ; $i < 1 ; $i++ ) {
	#
	#		$inCAM->COM("get_user_name");
	#
	#		my $name = $inCAM->GetReply();
	#
	#		print STDERR "\nProcessing  HEG !! $name \n";
	#		die "test";
	#		sleep(1);
	#
	#	}

	$result = $self->_Process( $inCAM, $errMess );

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#
sub SetISDimensionFilled {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"ISDimensionFilled"} = $val;
}

sub GetISDimensionFilled {
	my $self = shift;

	return $self->{"settings"}->{"ISDimensionFilled"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

