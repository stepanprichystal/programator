#-------------------------------------------------------------------------------------------#
# Description: Package contains helper function for InCAM NC manager subszstem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package CamHelpers::CamNCManager;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Create log when export drill or rout file
sub GetNCSet {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;
	my $ncSet    = shift;

	my %NCSet;
	$inCAM->INFO( "units" => 'mm', "entity_type" => 'ncset', "entity_path" => "$jobId/$stepName/$layer/$ncSet" );

	$NCSet{"gREGxorigin"} = ( $inCAM->{doinfo}{"gREGxorigin"} );
	$NCSet{"gREGyorigin"} = ( $inCAM->{doinfo}{"gREGyorigin"} );
	$NCSet{"gMACHINE"} = ( $inCAM->{doinfo}{"gMACHINE"} );
	
	return %NCSet;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamNCManager';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d113609";
	my $stepName = "panel";

	my $materialName = "IS400";
	my $machine      = "machine_g";
	my $layer        = "m";

 
	my %inf = CamNCManager->GetNCSet( $inCAM, $jobId, $stepName, $layer, "ncset.1" );

	print 1;

}

1;
