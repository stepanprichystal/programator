
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Unit::Units;

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased "Packages::Events::Event";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"onCheckEvent"} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub Init {
	my $self = shift;

	#my $parent = shift;
	my @units = @{ shift(@_) };

	$self->{"units"} = \@units;

}

sub InitDataMngr {
	my $self           = shift;
	my $inCAM          = shift;
	my $storedDataMngr = shift;

	#case when group data are taken from disc
	if ($storedDataMngr) {
		
		unless ( $storedDataMngr->ExistGroupData() ) {
			return 0;
		}

		foreach my $unit ( @{ $self->{"units"} } ) {

			my $storedData = $storedDataMngr->GetDataByUnit($unit);
			$unit->InitDataMngr( $inCAM, $storedData );
		}
	}

	#case, when "default" data for group are loaded
	else {

		foreach my $unit ( @{ $self->{"units"} } ) {

			$unit->InitDataMngr($inCAM);
		}

	}

}

sub CheckBeforeExport {
	my $self  = shift;
	my $inCAM = shift;

	#my $totalRes = 1;

	foreach my $unit ( @{ $self->{"units"} } ) {

		#$totalRes = 0;
		my %info = ();
		$info{"unit"} = $unit;

		my $resultMngr = -1;

		# Start checking
		$self->{"onCheckEvent"}->Do( "start", \%info );

		my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

		#unless ($succes) {
		#	$totalRes = 0;
		#}

		$info{"resultMngr"} = $resultMngr;

		# End checking
		$self->{"onCheckEvent"}->Do( "end", \%info );
	}

	#return $totalRes;
}

sub RefreshGUI {
	my $self = shift;

	#my $inCAM = shift;

	foreach my $unit ( @{ $self->{"units"} } ) {

		$unit->RefreshGUI();
	}

}

#sub BuildGUI {
#	my $self = shift;
#
#	foreach my $unit ( @{ $self->{"units"} } ) {
#
#		$unit->BuildGUI();
#	}
#}

sub GetGroupData {
	my $self = shift;

	my %groupData = ();

	foreach my $unit ( @{ $self->{"units"} } ) {

		my $groupData = $unit->GetGroupData();
		my %hashData  = %{ $groupData->{"data"} };
		$groupData{ $unit->{"unitId"} } = \%hashData;
	}

	return %groupData;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

