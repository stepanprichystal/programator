
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::OfferExport::Model::OfferGroupData;



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

sub GetOfferData {
	my $self = shift;
	return %{ $self->{"data"} };
}
 
 # Store  offer job specification to IS
sub SetSpecifToIS {
	my $self  = shift;
	$self->{"data"}->{"storeSpecToIS"} = shift;
}

sub GetSpecifToIS {
	my $self  = shift;
	return $self->{"data"}->{"storeSpecToIS"};
}


# Add pdf stackup to approval email
sub SetAddSpecifToEmail {
	my $self  = shift;
	$self->{"data"}->{"addSpecifToEmail"} = shift;
}

sub GetAddSpecifToEmail {
	my $self  = shift;
	return $self->{"data"}->{"addSpecifToEmail"};
}
 

# Add pdf stackup to approval email
sub SetAddStackupToEmail {
	my $self  = shift;
	$self->{"data"}->{"addStackupToEmail"} = shift;
}

sub GetAddStackupToEmail {
	my $self  = shift;
	return $self->{"data"}->{"addStackupToEmail"};
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

