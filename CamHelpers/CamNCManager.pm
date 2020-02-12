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

# Return information about NCSet
sub GetNCSet {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;
	my $ncSet    = shift;

	my %NCSet;
	$inCAM->INFO( "units" => 'mm', "entity_type" => 'ncset', "entity_path" => "$jobId/$stepName/$layer/$ncSet" );

	# Machine info
	$NCSet{"gMACHINE"} = ( $inCAM->{doinfo}{"gMACHINE"} );

	# Registration info
	$NCSet{"gREGxorigin"} = ( $inCAM->{doinfo}{"gREGxorigin"} );
	$NCSet{"gREGyorigin"} = ( $inCAM->{doinfo}{"gREGyorigin"} );
	$NCSet{"gREGxoff"}    = ( $inCAM->{doinfo}{"gREGxoff"} );
	$NCSet{"gREGyoff"}    = ( $inCAM->{doinfo}{"gREGyoff"} );
	$NCSet{"gREGmirror"}  = ( $inCAM->{doinfo}{"gREGmirror"} );
	$NCSet{"gREGangle"}   = ( $inCAM->{doinfo}{"gREGangle"} );
	$NCSet{"gREGxscale"}  = ( $inCAM->{doinfo}{"gREGxscale"} );
	$NCSet{"gREGyscale"}  = ( $inCAM->{doinfo}{"gREGyscale"} );
	$NCSet{"gREGxorigin"} = ( $inCAM->{doinfo}{"gREGxorigin"} );
	$NCSet{"gREGyorigin"} = ( $inCAM->{doinfo}{"gREGyorigin"} );

	return %NCSet;
}

# Return information about NCRSet
sub GetNCRSet {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;
	my $ncrSet    = shift;

	my %NCRSet;
	$inCAM->INFO( "units" => 'mm', "entity_type" => 'ncrset', "entity_path" => "$jobId/$stepName/$layer/$ncrSet" );

	# Machine info
	$NCRSet{"gMACHINE"} = ( $inCAM->{doinfo}{"gMACHINE"} );

	# Registration info
	$NCRSet{"gREGxorigin"} = ( $inCAM->{doinfo}{"gREGxorigin"} );
	$NCRSet{"gREGyorigin"} = ( $inCAM->{doinfo}{"gREGyorigin"} );
	$NCRSet{"gREGxoff"}    = ( $inCAM->{doinfo}{"gREGxoff"} );
	$NCRSet{"gREGyoff"}    = ( $inCAM->{doinfo}{"gREGyoff"} );
	$NCRSet{"gREGmirror"}  = ( $inCAM->{doinfo}{"gREGmirror"} );
	$NCRSet{"gREGangle"}   = ( $inCAM->{doinfo}{"gREGangle"} );
	$NCRSet{"gREGxscale"}  = ( $inCAM->{doinfo}{"gREGxscale"} );
	$NCRSet{"gREGyscale"}  = ( $inCAM->{doinfo}{"gREGyscale"} );
	$NCRSet{"gREGxorigin"} = ( $inCAM->{doinfo}{"gREGxorigin"} );
	$NCRSet{"gREGyorigin"} = ( $inCAM->{doinfo}{"gREGyorigin"} );

	return %NCRSet;
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
