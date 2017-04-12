
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::RoutGroup::RoutMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";
use aliased 'Programs::PoolMerge::Enums'     => "EnumsPool";
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

	for ( my $i = 0 ; $i < 5 ; $i++ ) {

		sleep(1);

		 

		if ( $i == 2 ) {

			my $str = FileHelper->ReadAsString('c:\Perl\site\lib\TpvScripts\Scripts\test');

			 if (substr($str, 1, 1)) {

				my $res = $self->_GetNewItem("recyklus $i");
				$res->AddError("chyba rout");
				$self->_OnItemResult($res);

				my $resSpec = $self->_GetNewItem( EnumsAbstrQ->EventItemType_STOP );
				$self->_OnStatusResult($resSpec);
				return 0;
			}
		}

		my $res = $self->_GetNewItem("recyklus rout $i");
		$self->_OnItemResult($res);

	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 5;    # getting sucesfully AOI manager

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

