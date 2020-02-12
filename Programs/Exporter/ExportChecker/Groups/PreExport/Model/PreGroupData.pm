
#-------------------------------------------------------------------------------------------#
# Description: Class contain state properties, used as model for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreGroupData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# state data for gui controls
	my %exportData = ();
	$self->{"data"} = \%exportData;
	
	# state of whole group. Value is enum GroupState_xx
	$self->{"state"} = Enums->GroupState_DISABLE;

	return $self;
}

 
# signal layers
sub SetSignalLayers {
	my $self  = shift;
	$self->{"data"}->{"signalLayers"} = shift;
}

sub GetSignalLayers {
	my $self  = shift;
	return $self->{"data"}->{"signalLayers"};
}

# other layers
sub SetOtherLayers {
	my $self  = shift;
	$self->{"data"}->{"otherLayers"} = shift;
}

sub GetOtherLayers {
	my $self  = shift;
	return $self->{"data"}->{"otherLayers"};
}


#NC layer scale settings
sub SetNCLayersSett {
	my $self = shift;
	$self->{"data"}->{"NCLayerSett"} = shift;
}

sub GetNCLayersSett {
	my $self = shift;
	return $self->{"data"}->{"NCLayerSett"};
}
 
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

