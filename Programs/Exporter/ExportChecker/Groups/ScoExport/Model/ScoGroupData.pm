
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ScoExport::Model::ScoGroupData;

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::Groups::IGroupData');


#3th party library
use strict;
use warnings;
use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self;    # Return the reference to the hash.
}


# paste info, hash with info

sub GetData {
	my $self = shift;
	return %{ $self->{"data"} };
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

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

