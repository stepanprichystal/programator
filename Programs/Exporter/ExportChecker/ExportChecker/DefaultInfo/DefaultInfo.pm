
#-------------------------------------------------------------------------------------------#
# Description: This class load/compute default values which consum ExportChecker.
# Here are placed values, which take long time for computation, thus here will be computed
# only once, when ExporterChecker starts.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums' => 'StackupEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Packages::Routing::PlatedRoutArea';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"} = "panel";

	# Defaul values
	$self->{"layerCnt"} = undef;
	$self->{"stackup"} = undef;
	$self->{"stackupNC"} = undef;
	$self->{"pattern"} = undef;
	$self->{"tenting"} = undef;
	$self->{"baseLayers"} = undef;
	$self->{"scoreChecker"} = undef;
	$self->{"materialKind"} = undef;
	

	$self->__InitDefault();

	return $self;
}


sub GetBoardBaseLayers {
	my $self      = shift;
	
	return  @{$self->{"baseLayers"}};	
}

sub GetPcbClass {
	my $self      = shift;
	
	return $self->{"pcbClass"};	
}

sub GetLayerCnt {
	my $self      = shift;	
	
	return $self->{"layerCnt"};
}


sub GetEtchType {
	my $self      = shift;
	my $layerName = shift;

	my $etchType = EnumsGeneral->Etching_NO;

	if ( $self->{"layerCnt"} == 1 ) {

		$etchType = EnumsGeneral->Etching_TENTING;

	}
	elsif ( $self->{"layerCnt"} == 2 ) {

		if ( $self->{"platedRoutExceed"} || $self->{"rsExist"}) {
			$etchType = EnumsGeneral->Etching_PATTERN;
		}
		else {
			$etchType = EnumsGeneral->Etching_TENTING;
		}
	}
	elsif ( $self->{"layerCnt"} > 2 ) {

		my $pressCnt   = $self->{"stackup"}->GetPressCount();
		my %pressInfo  = $self->{"stackup"}->GetPressInfo();
		my $lamination = $self->{"stackup"}->ProgressLamination();

		my $stackupNCitem = undef;

		# 1) We need to get top and bot layer, which will be pressed, etched etd together
		#my $topCopperName = undef;
		#my $botCopperName = undef;

		my $core  = $self->{"stackup"}->GetCoreByCopperLayer($layerName);
		my $press = undef;

		if ($core) {

			#$topCopperName = $core->GetTopCopperLayer()->GetCopperName();
			#$botCopperName = $core->GetBotCopperLayer()->GetCopperName();

			my $order = $core->GetCoreNumber();

			$stackupNCitem = $self->{"stackupNC"}->GetCore($order);

		}
		else {

			# find, which press was layer pressed in
			foreach my $pNum ( keys %pressInfo ) {

				my $p = $pressInfo{$pNum};

				if ( $p->GetTopCopperLayer() eq $layerName || $p->GetBotCopperLayer() eq $layerName ) {
					$press = $p;

					my $order = $press->GetPressOrder();
					$stackupNCitem = $self->{"stackupNC"}->GetPress($order);

					#$topCopperName = p->GetTopCopperLayer();
					#$botCopperName = $p->GetBotCopperLayer();
					last;
				}

			}
		}

		# 2) Now decide, if there is blind drilling in stackupItem ( = pressInfo/coreInfo)

		if (    $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop )
			 || $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot ) )
		{

			$etchType = EnumsGeneral->Etching_PATTERN;

		}
		else {

			$etchType = EnumsGeneral->Etching_TENTING;
		}

		# 3) Check on plated rout most outer layers

		if ( $layerName eq "c" || $layerName eq "s" ) {

			if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} ) {
				$etchType = EnumsGeneral->Etching_PATTERN;
			}
		}

	}

	return $etchType;

}


sub GetSideByLayer {
	my $self      = shift;
	my $layerName = shift;

	my $side = "";

	my %pressInfo = $self->{"stackup"}->GetPressInfo();
	my $core      = $self->{"stackup"}->GetCoreByCopperLayer($layerName);
	my $press     = undef;

	if ($core) {

		my $topCopperName = $core->GetTopCopperLayer()->GetCopperName();
		my $botCopperName = $core->GetBotCopperLayer()->GetCopperName();

		if ( $layerName eq $topCopperName ) {

			$side = "top";
		}
		elsif ( $layerName eq $botCopperName ) {

			$side = "bot";
		}
	}
	else {

		# find, which press was layer pressed in
		foreach my $pNum ( keys %pressInfo ) {

			my $p = $pressInfo{$pNum};

			if ( $p->GetTopCopperLayer() eq $layerName ) {

				$side = "top";
				last;

			}
			elsif ( $p->GetBotCopperLayer() eq $layerName ) {

				$side = "bot";
				last;
			}
		}
	}

	return $side;
}

sub GetCompByLayer{
	my $self      = shift;
	my $layerName = shift;

	return 0;
	
}

sub GetCustomerJump{
	my $self      = shift;
	
	my $res = 0;
	
	if($self->{"scoreChecker"}){

		$res = $self->{"scoreChecker"}->CustomerJumpScoring();
	}
	
	return $res;
}

sub GetMaterialKind{
	my $self      = shift;
	
	return $self->{"materialKind"};
}

sub __InitDefault {
	my $self = shift;

	my @baseLayers = CamJob->GetBoardBaseLayers($self->{"inCAM"}, $self->{"jobId"} );
	$self->{"baseLayers"} =  \@baseLayers;

	$self->{"pcbClass"} = CamJob->GetJobPcbClass($self->{"inCAM"}, $self->{"jobId"} );   

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"platedRoutExceed"} =  PlatedRoutArea->PlatedAreaExceed( $self->{"inCAM"}, $self->{'jobId'}, "panel" );
	$self->{"rsExist"} =  CamDrilling->NCLayerExists( $self->{"inCAM"}, $self->{'jobId'}, "rs" );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $self->{'jobId'} );
		$self->{"stackupNC"} = StackupNC->new( $self->{"inCAM"}, $self->{"stackup"} );
	}
	
	if(CamHelper->LayerExists(  $self->{"inCAM"}, $self->{"jobId"}, "score" )){
		
		$self->{"scoreChecker"} = ScoreChecker->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, "score", 1 );
		$self->{"scoreChecker"}->Init();
	}
	
	
	$self->{"materialKind"} = HegMethods->GetMaterialKind($self->{"jobId"});
	

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

