
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::UnitsDataContracts::ScoData;
 
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

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self; 
}
 
 
# core thick in mm
sub SetCoreThick {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"coreThick"} = $value;
}

sub GetCoreThick {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"coreThick"};
}
 
 
# Optimize yes/no/manual
sub SetOptimize {
	my $self  = shift;
	$self->{"data"}->{"optimize"} = shift;
} 


sub GetOptimize {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"optimize"};
}
 
# Scoring type classic/one direction
sub SetScoringType {
	my $self  = shift;
	$self->{"data"}->{"scoringType"} = shift;
}

sub GetScoringType {
	my $self  = shift;
	return $self->{"data"}->{"scoringType"};
} 


# Customer jump scoring
sub SetCustomerJump {
	my $self  = shift;
	$self->{"data"}->{"customerJump"} = shift;
}

sub GetCustomerJump {
	my $self  = shift;
	return $self->{"data"}->{"customerJump"};
} 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

