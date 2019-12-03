#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::REVISION;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# check if pcb is in Revision
sub Run {
	my $self = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $needChange = 0;

	# check if pcb is in revision
	my $pcbInfo = HegMethods->GetBasePcbInfo($jobId);

	my $revize = $pcbInfo->{"stav"} eq 'R' ? 1 : 0;    # indicate if pcb need user-manual process before go to produce

	if ($revize) {

		$self->_AddChange(
						   "Deska je ve stavu \"revize\", uprav data jobu. Pokud: \n "
							 . "a) opakovaná přišla z OÚ, najdi papír o změnách v kastlíku\n "
							 . "b) požadavek z výroby, informuj se o změnách v dps u autora opakované objednávky",
						   0
		);

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::KADLEC_PANEL' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

