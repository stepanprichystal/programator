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
use aliased 'Helpers::JobHelper';
use aliased 'Packages::TifFile::TifRevision';

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

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $needChange = 0;

	# 1) check if pcb is in Salec revision
	my $pcbInfo = HegMethods->GetBasePcbInfo($jobId);

	my $revize = $pcbInfo->{"stav"} eq 'R' ? 1 : 0;    # indicate if pcb need user-manual process before go to produce

	if ($revize) {

		$self->_AddChange(
						   "Deska m� nastaveno v IS stav \"revize\", uprav data jobu. Pokud: \n "
							 . "a) opakovan� p�i�la z O� najdi pap�r se zm�nou v kastl�ku nebo kontaktuj O�\n "
							 . "b) se jedn� o po�adavek z v�roby, informuj se o zm�n�ch u autora opakovan� v�roby",
						   0
		);

	}

	# 2) Check if PCB is in TPV revision
	my $difFile = TifRevision->new($jobId);
	if ( $difFile->TifFileExist() && $difFile->GetRevisionIsActive() ) {

		$self->_AddChange(
						   "V DIF osuboru byla dohled�na aktivn� revize na z�klad� po�adavku TPV. "
							 . "Prove� instrukce v revizi a deaktivuj (sma�) ji (RevisionScript.pl)"
							 . "\nText revize:\n"
							 . $difFile->GetRevisionText(),
						   1
		);

	}

	# 2) All flexible PCB must go through TPV
	if ( JobHelper->GetIsFlex($jobId) ) {
		$self->_AddChange(
				"Flexibilni DPS jde do v�roby, je t�eba zkontrolovat, jestli nedo�lo k z�sadn�m zm�n�m na p��prav�.\n ",
				0 );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::REVISION' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	use Data::Dump qw(dump);

	my $inCAM = InCAM->new();
	my $jobId = "d298300";
	my $orderId = "d298300-01";

	my $check = Change->new( "key", $inCAM, $jobId, $orderId, "Reorder_Standard" );

	my $mess = "";
	  $check->Run(  );

	dump( $check->GetChanges() );
}

1;

