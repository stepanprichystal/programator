
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::ClassHEGSize;
use base('Programs::Panelisation::PnlCreator::SizePnlCreator::SizeCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::SizePnlCreator::ISize');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlClassParser';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->SizePnlCreator_CLASSHEG;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"defPnlClass"}  = undef;
	$self->{"settings"}->{"defPnlSize"}   = undef;
	$self->{"settings"}->{"defPnlBorder"} = undef;

	$self->{"settings"}->{"pnlClasses"} = undef;

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

	# Load Pnl class

	my $jobId = $self->{'jobId'};

	my $parser = PnlClassParser->new( $inCAM, $jobId );
	$parser->Parse();

	my @classes = ();
	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		@classes = $parser->GetCustomerPnlClasses(1);
	}
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		@classes = $parser->GetProductionPnlClasses(1);

	}

	my $defClass  = undef;
	my $defSize   = undef;
	my $defBorder = undef;

	$self->{"settings"}->{"pnlClasses"} = \@classes;

	# 1)Set default class (should be only one for specific pcb type)
	$defClass = $classes[0];
	if ( defined $defClass ) {

		$self->{"settings"}->{"defPnlClass"} = $defClass->GetName();

		# 2) Set default size. Take the biger one

		# Check if there is dimension in HEG

		my $dim = HegMethods->GetInfoDimensions($jobId);

		my $ISpnlW = undef;
		my $ISpnlH = undef;

		if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

			$ISpnlW = $dim->{"panel_x"};
			$ISpnlH = $dim->{"panel_y"};

		}    # Load panel size from HEG
		elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

			$ISpnlW = $dim->{"rozmer_x"};
			$ISpnlH = $dim->{"rozmer_y"};
		}

		my @sizes = $classes[0]->GetSizes();

		my $ISSize = first { $_->GetWidth() == $ISpnlW && $_->GetHeight() == $ISpnlH } @sizes;

		if ( defined $ISSize ) {

			# Edit name + set as defalut

			$ISSize->SetName( $ISSize->GetName() . " (HEG)" );

			$defSize = $ISSize;

		}
		else {
			# Create custome HEG size + add borders/spacings + set as default

			my $size = $parser->AddCustomSizeToClass( $defClass, "non standard (HEG)", $ISpnlW, $ISpnlH );
			$defSize = $size;

		}

		if ( defined $defSize ) {

			$self->{"settings"}->{"defPnlSize"} = $defSize->GetName();

			# 3) Set default pnl border/ Should be only one border per specific size
			$defBorder = ( $defSize->GetBorders() )[0];

			if ( defined $defBorder ) {

				$self->{"settings"}->{"defPnlBorder"} = $defBorder->GetName();
			}
		}
		else {

			# add

		}
	}

	# Set width/height
	if ( defined $defSize ) {

		$self->SetWidth( $defSize->GetWidth() );
		$self->SetHeight( $defSize->GetHeight() );
	}

	# Set border

	if ( defined $defBorder ) {

		$self->SetBorderLeft( $defBorder->GetBorderLeft() );
		$self->SetBorderRight( $defBorder->GetBorderRight() );
		$self->SetBorderTop( $defBorder->GetBorderTop() );
		$self->SetBorderBot( $defBorder->GetBorderBot() );

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

	$result = $self->_Process( $inCAM, $errMess );

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub GetPnlClasses {
	my $self = shift;

	return $self->{"settings"}->{"pnlClasses"};
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"settings"}->{"defPnlClass"};
}

sub GetDefPnlSize {
	my $self = shift;

	return $self->{"settings"}->{"defPnlSize"};
}

sub GetDefPnlBorder {
	my $self = shift;

	return $self->{"settings"}->{"defPnlBorder"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
