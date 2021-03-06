
#-------------------------------------------------------------------------------------------#
# Description: Check stencil paremeters before export
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilCreator::Helpers::OutputCheck;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Stencil::StencilCreator::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper';
use aliased 'Packages::Other::CustomerNote';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"dataMngr"}    = shift;
	$self->{"stencilMngr"} = shift;
	$self->{"stencilSrc"}  = shift;
	$self->{"jobIdSrc"}    = shift;

	my $custInfo = HegMethods->GetCustomerInfo( $self->{"jobId"} );
	$self->{"customerNote"} = CustomerNote->new( $custInfo->{"reference_subjektu"} );

	$self->{"isPool"} = 0;    # indicate if source is job if job is pool
	if ( $self->{"stencilSrc"} eq Enums->StencilSource_JOB && HegMethods->GetPcbIsPool( $self->{"jobIdSrc"} ) ) {
		$self->{"isPool"} = 1;
	}

	return $self;
}

sub Check {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my %stencilInfo = Helper->GetStencilInfo($jobId);

	# Check according customer notes

	# Check center by data
	if ( $self->{"customerNote"}->CenterByData() && $self->{"dataMngr"}->GetCenterType() ne Enums->Center_BYDATA ) {

		$self->__AddError("Z??kazn??k si p??eje vycentrovat data na st??ed podle skute??n??ch dat a ne podle profilu.");

	}

	# Check distance paste-holes in standard frame
	if ( defined $self->{"customerNote"}->MinHoleDataDist() ) {

		my $minDist = $self->{"customerNote"}->MinHoleDataDist();
		my $sType   = $self->{"dataMngr"}->GetStencilType();

		my $distOk    = 1;
		my $wrongDist = "";

		my %area = $self->{"stencilMngr"}->GetStencilActiveArea();

		my $areaBot = ( $self->{"stencilMngr"}->GetHeight() - $area{"h"} ) / 2;
		my $areaTop = $areaBot + $area{"h"};

		if ( $sType eq Enums->StencilType_TOP || $sType eq Enums->StencilType_TOPBOT ) {

			my $tp          = $self->{"stencilMngr"}->GetTopProfile();
			my $topPasteLim = $self->{"stencilMngr"}->GetTopDataPos()->{"y"} + $tp->GetPasteData()->GetHeight();

			if ( abs( $topPasteLim - $areaTop ) < $minDist ) {
				$distOk = 0;
				$wrongDist .= "- Vzd??lenost data/horn???? otvory = " . abs( $topPasteLim - $areaTop ) . "mm\n";
			}
		}

		if ( $sType eq Enums->StencilType_BOT || $sType eq Enums->StencilType_TOPBOT ) {

			my $botPasteLim = $self->{"stencilMngr"}->GetBotDataPos()->{"y"};

			if ( abs( $botPasteLim - $areaBot ) < $minDist ) {
				$distOk = 0;
				$wrongDist .= "- Vzd??lensot data/doln?? otvory = " . abs( $botPasteLim - $areaBot ) . "mm\n";
			}
		}

		unless ($distOk) {

			$self->__AddError(
				 "Z??kazn??k si p??eje aby minim??ln?? vzd??lenost plo??ky na ??ablon?? od op??nac??ch otvor?? byla " . $minDist . "mm\n$wrongDist" );
		}
	}

	# Y hole distance
	my $holeDistY = $self->{"customerNote"}->HoleDistY();
	if ( defined $holeDistY && $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my @holesY = map { $_->{"y"} } $self->{"stencilMngr"}->GetSchema()->GetHolePositions();

		if ( abs( min(@holesY) - max(@holesY) ) != $holeDistY ) {

			$self->__AddError(   "Z??kazn??k si p??eje, aby vertik??ln?? vzd??lensot mezi up??nac??mi otvory byla "
							   . $holeDistY
							   . "mm (aktu??ln?? je "
							   . abs( min(@holesY) - max(@holesY) )
							   . "mm)" );
		}

	}

	# X hole distance
	my $holeDistX = $self->{"customerNote"}->HoleDistX();
	if ( defined $holeDistX && $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my @holesX = sort { $a <=> $b } uniq( map { $_->{"x"} } $self->{"stencilMngr"}->GetSchema()->GetHolePositions() );

		# take fist two holes, if sitance is as costomer request

		if ( abs( $holesX[0] - $holesX[1] ) != $holeDistX ) {
			$self->__AddError(   "Z??kazn??k si p??eje, aby horizont??ln?? vzd??lensot mezi up??nac??mi otvory byla "
							   . $holeDistX
							   . "mm (aktu??ln?? je "
							   . abs( $holesX[0] - $holesX[1] )
							   . "mm)" );
		}

	}

	# check if there are no halfholes
	my $halfHoles = $self->{"customerNote"}->HalfHoles();
	if ( defined $halfHoles && $halfHoles == 0 && $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my @holesX = sort { $a <=> $b } uniq( map { $_->{"x"} } $self->{"stencilMngr"}->GetSchema()->GetHolePositions() );

		# Check if some hole lay on "stencil edge"
		my $r = $self->{"dataMngr"}->GetHoleSize() / 2;

		my $lEdge = 0;
		my $rEdge = $self->{"dataMngr"}->GetStencilSizeX();
		my @holes = grep { ( $_ - $r < $lEdge && $_ + $r > $lEdge ) || ( $_ - $r < $rEdge && $_ + $r > $rEdge ) } @holesX;

		if (@holes) {

			@holes = map { sprintf( "%.2fmm", $_ ) } @holes;

			$self->__AddError(
						  "Z??kazn??k si nep??eje m??t up??nac?? otvory na hran??ch desky " . "(otvory na pozic??ch: " . join( ", ", @holes ) . ")" );

		}
	}
	
	# check if there are halfholes
	if ( defined $halfHoles && $halfHoles == 1 && $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my @holesX = sort { $a <=> $b } uniq( map { $_->{"x"} } $self->{"stencilMngr"}->GetSchema()->GetHolePositions() );

		# Check if some hole lay on "stencil edge"
		my $r = $self->{"dataMngr"}->GetHoleSize() / 2;

		my $lEdge = 0;
		my $rEdge = $self->{"dataMngr"}->GetStencilSizeX();
		my @holes = grep { ( $_ - $r < $lEdge && $_ + $r > $lEdge ) || ( $_ - $r < $rEdge && $_ + $r > $rEdge ) } @holesX;

		unless (@holes) {
 
			$self->__AddError(
						  "Z??kazn??k si P??EJE m??t up??nac?? otvory na hran??ch desky - halfholes");
		}
	}

	# Other checks

	# Check properly inserted pcb number into stencil

	if (
		$self->{"dataMngr"}->GetAddPcbNumber() && (    $stencilInfo{"tech"} eq Enums->Technology_DRILL
													|| $self->{"stencilSrc"} eq Enums->StencilSource_CUSTDATA
													|| ( $self->{"stencilSrc"} eq Enums->StencilSource_JOB && $self->{"isPool"} ) )
	  )
	{

		$self->__AddError(   "????slo pcb by nem??lo b??t na ??ablon?? vlo??en??, pokud:\n"
						   . "- ??ablona je vrtan??\n"
						   . "- ??ablona je vytvo??en?? ze z??kaznick??ch dat (ne z jobu)\n"
						   . "- se jedn?? o ??ablonu typu POOL\n" );

	}

	# Check if schema is not inserted
	if (
		 $self->{"dataMngr"}->GetSchemaType() ne Enums->Schema_INCLUDED
		 && ( $self->{"stencilSrc"} eq Enums->StencilSource_CUSTDATA
			  || ( $self->{"stencilSrc"} eq Enums->StencilSource_JOB && $self->{"isPool"} ) )
	  )
	{

		$self->__AddError(   "Do ??ablony by se nem??lo vkl??dat okol??, pokud:\n"
						   . "- je vytvo??en?? ze z??kaznick??ch dat, kter?? ji?? okol?? obsahuj??\n"
						   . "- se jedn?? o ??ablonu typu POOL\n" );

	}

	# Check if schema is inserted
	if (    $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_INCLUDED
		 && $self->{"stencilSrc"} eq Enums->StencilSource_JOB
		 && !$self->{"isPool"} )
	{

		$self->__AddError("V ??ablon?? chyb?? okol??\n");

	}

	# Check vlepeni do ramu
	if ( $stencilInfo{"schema"} eq Enums->Schema_FRAME && $self->{"dataMngr"}->GetSchemaType() ne Enums->Schema_FRAME ) {

		$self->__AddError("V IS je po??adavek na vlepen?? ??ablony do r??mu. Okol?? ale nen?? typ \"vlepen?? do r??mu\"\n");

	}

	# Check dimenison in IS and currently set
	if (    $stencilInfo{"width"} != $self->{"dataMngr"}->GetStencilSizeX()
		 || $stencilInfo{"height"} != $self->{"dataMngr"}->GetStencilSizeY() )
	{

		$self->__AddError(   "Nesouhlas?? po??adovan?? rozm??ry v IS ("
						   . $stencilInfo{"width"} . "x"
						   . $stencilInfo{"height"}
						   . "mm) s nastaven??mi rozm??ry ("
						   . $self->{"dataMngr"}->GetStencilSizeX() . "x"
						   . $self->{"dataMngr"}->GetStencilSizeY()
						   . "mm)\n" );

	}

	# Check type of stencil
	if ( $stencilInfo{"type"} ne $self->{"dataMngr"}->GetStencilType() ) {

		$self->__AddError(
			  "Nesouhlas?? typ ??ablony v IS (" . $stencilInfo{"type"} . ") s nastaven??mi typem (" . $self->{"dataMngr"}->GetStencilType() . ")\n" );

	}

	# Check if pcb are not to close (< 50 mm)
	if ( $self->{"dataMngr"}->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		my $dist = $self->{"stencilMngr"}->GetCurrentSpacing("data");

		if ( $dist < 50 ) {

			$self->__AddError("??ablony TOP a BOT jsou u sebe p????li?? bl??zko ($dist mm). Je to v po????dku?\n");
		}

	}
	
	# Check standard schema dont touch with pcb drilled number
	if ( $self->{"dataMngr"}->GetAddPcbNumber() && $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		 my %area = $self->{"stencilMngr"}->GetStencilActiveArea();

		my $areaBot = ( $self->{"stencilMngr"}->GetHeight() - $area{"h"} ) / 2;
		$areaBot -= $self->{"dataMngr"}->GetHoleSize()/2;

		# if there is less space then 8mm for pcb number (from stencil bot edge to schema holes)
		if ($areaBot < 8 ) {

			$self->__AddError("Pozor up??nac?? otvory zasahuj?? do \"????sla ??ablony\". Zmen???? nebo posu?? toto ????slo ve vrstv?? ds/flc.\n");
		}

	}	

	return $result;
}

sub __AddError {
	my $self = shift;
	my $mess = shift;

	my $checkRes = $self->_GetNewItem("-");

	$checkRes->AddError($mess);

	$self->_OnItemResult($checkRes);
}

sub __AddWarning {
	my $self = shift;
	my $mess = shift;

	my $checkRes = $self->_GetNewItem("-");

	$checkRes->AddWarning($mess);

	$self->_OnItemResult($checkRes);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

