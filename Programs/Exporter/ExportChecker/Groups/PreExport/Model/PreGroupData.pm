
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

 
# layers
sub SetLayers {
	my $self  = shift;
	$self->{"data"}->{"layers"} = shift;
}

sub GetLayers {
	my $self  = shift;
	return $self->{"data"}->{"layers"};
}

# Tenting
sub SetTenting {
	my $self  = shift;
	$self->{"data"}->{"tenting"} = shift;
}

sub GetTenting {
	my $self  = shift;
	return $self->{"data"}->{"tenting"};
}


# Technology
sub SetTechnology {
	my $self  = shift;
	
	$self->{"data"}->{"technology"} = shift;
}

sub GetTechnology {
	my $self  = shift;
	
	return $self->{"data"}->{"technology"};
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

