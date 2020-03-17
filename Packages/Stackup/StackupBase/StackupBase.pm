
#-------------------------------------------------------------------------------------------#
# Description: Base class, responsible for creating stackup from given data (Multicall xml,...)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::StackupBase;

#3th party library
use strict;
use warnings;
use XML::Simple;
use List::Util qw(first);
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Enums::EnumsPaths';

use aliased 'Packages::Stackup::StackupBase::StackupParsers::InStackParser';
use aliased 'Packages::Stackup::StackupBase::StackupParsers::MultiCalParser';
use aliased 'Packages::Stackup::StackupBase::Layer::PrepregLayer';
use aliased 'Packages::Stackup::StackupBase::StackupHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $jobId = shift;

	# CHOOSE STACKUP PARSER

	# InStack coupon has higher priority
	if ( -e EnumsPaths->Jobs_COUPONS . "$jobId.xml" ) {

		$self->{"parser"} = InStackParser->new($jobId);
	}
	else {

		$self->{"parser"} = MultiCalParser->new($jobId);
	}

	# SET PROPERTIES

	#id of pcb stackup
	$self->{"jobId"} = $jobId;

	# Layers type of item is <StackupLayer>
	$self->{"layers"} = [];

	# Cu layer count
	$self->{"layerCnt"} = undef;
	
	# Nominal thickness requested by customer
	$self->{"nominalThick"} = undef;

	$self->__CreateStackup();

	return $self;
}

# Return source type which stackup read from
sub GetStackupSource {
	my $self = shift;

	my $p = $self->{"parser"};

	return Enums->StackupSource_INSTACK if ( ref($p) && $p->isa("Packages::Stackup::StackupBase::StackupParsers::InStackParser") );
	return Enums->StackupSource_ML      if ( ref($p) && $p->isa("Packages::Stackup::StackupBase::StackupParsers::MultiCalParser") );
}

# Return all layers of stackup
sub GetAllLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}

# Get core by core number
sub GetCore {
	my $self    = shift;
	my $coreNum = shift;

	return ( grep { $_->GetCoreNumber() eq $coreNum } $self->GetAllCores() )[0];
}

# Return all layers type of core
sub GetAllCores {
	my $self    = shift;
	my $noRigid = shift;    # filter out rigid cores
	my $noFlex  = shift;    # filter out flex cores

	my @thickList = @{ $self->{"layers"} };
	my @cores     = ();

	foreach my $l (@thickList) {

		if ( GeneralHelper->RegexEquals( $l->GetType(), Enums->MaterialType_CORE ) ) {
			push( @cores, $l );
		}
	}

	# filter out flex cores
	if ($noFlex) {
		@cores = grep { $_->GetThick() > 100 } @cores;
	}

	# filter rigid cores
	if ($noRigid) {
		@cores = grep { $_->GetThick() <= 100 } @cores;
	}

	if ( scalar(@cores) ) {

		return @cores;

	}
	else {

		return 0;
	}

}

# Return total thick of this stackup
sub GetCuLayerCnt {
	my $self = shift;

	my $lCount = scalar( grep { $_->GetType() eq Enums->MaterialType_COPPER } $self->GetAllLayers() );

	return $lCount;
}

# Return Cu layer (CopperLayer object) by name (c, v2, v3 ...)
sub GetCuLayer {
	my $self      = shift;
	my $layerName = shift;

	my $l = first { $_->GetType() eq Enums->MaterialType_COPPER && $_->GetCopperName() eq $layerName } @{ $self->{"layers"} };

	die "Copper layer: $layerName was not found" unless ( defined $l );

	return $l;
}

# If layer is copper type, return core ( Core layer object) which copper layer belongs to
sub GetCoreByCuLayer {
	my $self      = shift;
	my $layerName = shift;

	my @thickList = @{ $self->{"layers"} };
	my $cuLayer   = $self->GetCuLayer($layerName);
	
	die "Copper is not \"core\" copper, but copper foil" if($cuLayer->GetIsFoil());

	my $core = undef;

	foreach my $c ( $self->GetAllCores() ) {

		if ( $c->GetTopCopperLayer()->GetCopperName() eq $layerName || $c->GetBotCopperLayer()->GetCopperName() eq $layerName ) {
			$core = $c;
			last;
		}
	}
 
 
	return $core;
}

# Return type of material, which stackup is composed from
# Assume, all layers are same type, so take type from first core
sub GetStackupType {
	my $self = shift;

	return join( "+", uniq( map( $_->GetTextType(), $self->GetAllCores() ) ) );
}

# Return if stackup is hybrid
# Stackup is hybrid if there are cores with different material type (eg.: IS400 + DUROID)
sub GetStackupIsHybrid {
	my $self = shift;

	my @types = uniq( map( $_->GetTextType(), $self->GetAllCores() ) );

	return scalar(@types) > 1 ? 1 : 0;
}

# Return nominal thickness requested by customer
sub GetNominalThickness{
	my $self = shift;
	
	return $self->{"nominalThick"};
}
#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#

sub __CreateStackup {
	my $self = shift;

	#set info about layers of stackup
	$self->__SetStackupLayers();

 	#set other stackup property
	$self->__SetOtherProperty();

}

# Set info about layers of stackup
sub __SetStackupLayers {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	# 1) Return parsed stackup layers from top 2 bot
	my @parsedLayers = $self->{"parser"}->ParseStackup();

	my $copperCnt = scalar( grep { $_->GetType() eq Enums->MaterialType_COPPER } @parsedLayers );

	my @stackupL = ();

	my $curParentPrpg = undef;

	# 2) Do additional adjustment of layers
	for ( my $i = 0 ; $i < scalar(@parsedLayers) ; $i++ ) {

		my $layerInfo = $parsedLayers[$i];

		if ( $layerInfo->GetType() eq Enums->MaterialType_COPPER ) {

			# COPPER

			if ( $layerInfo->GetCopperNumber() == 1 ) {
				$layerInfo->{"copperName"} = "c";
			}
			elsif ( $layerInfo->GetCopperNumber() == $copperCnt ) {
				$layerInfo->{"copperName"} = "s";
			}
			else {

				$layerInfo->{"copperName"} = "v" . $layerInfo->GetCopperNumber();
			}

			push( @stackupL, $layerInfo );
		}
		elsif ( $layerInfo->GetType() eq Enums->MaterialType_CORE ) {

			# CORE

			my $topCopper = $parsedLayers[ $i - 1 ];

			if ( $topCopper && $topCopper->GetType() eq Enums->MaterialType_COPPER ) {

				$layerInfo->{"topCopperLayer"} = $topCopper;
				$topCopper->{"isFoil"}         = 0;
			}

			my $botCopper = $parsedLayers[ $i + 1 ];

			if ( $botCopper && $botCopper->GetType() eq Enums->MaterialType_COPPER ) {

				$layerInfo->{"botCopperLayer"} = $botCopper;
				$botCopper->{"isFoil"}         = 0;
			}

			push( @stackupL, $layerInfo );

		}
		elsif ( $layerInfo->GetType() eq Enums->MaterialType_PREPREG ) {

			# PREPREGS

			# Merge prepregs with same type, create parent prepreg

			#my $layerPrevInfo = $parsedLayers[ $i - 1 ] if ( $i > 0 );

			# 1) Determine type of noflow prepreg
			# - If is right next flex core it is type P1
			# - flex core has always one NoFlow prepreg from both side
			my $noFlowType = undef;

			if ( $parsedLayers[$i]->GetIsNoFlow() ) {
				$noFlowType = Enums->NoFlowPrepreg_P2;

				# find preview core
				my $corePrevInfo = ( grep { $_->GetType() eq Enums->MaterialType_CORE } @parsedLayers[ ( $i - 2 ) .. ( $i - 1 ) ] )[-1];

				# find next core
				my $coreNextInfo = ( grep { $_->GetType() eq Enums->MaterialType_CORE } @parsedLayers[ ( $i + 1 ) .. ( $i + 2 ) ] )[0];

				if (
					 (
					      defined $corePrevInfo
					   && $corePrevInfo->GetType() eq Enums->MaterialType_CORE
					   && $corePrevInfo->GetCoreRigidType() eq Enums->CoreType_FLEX
					 )
					 || (    defined $coreNextInfo
						  && $coreNextInfo->GetType() eq Enums->MaterialType_CORE
						  && $coreNextInfo->GetCoreRigidType() eq Enums->CoreType_FLEX )
				  )
				{

					$noFlowType = Enums->NoFlowPrepreg_P1;
				}
			}

			# 2) Decide if create new prepreg parent
			my $newParent = 0;

			#			if ( defined $curParentPrpg && $curParentPrpg->GetIsNoFlow() && !defined $noFlowType ) {
			#				die;
			#			}
			$newParent = 1 if ( !defined $curParentPrpg );
			$newParent = 1 if ( defined $curParentPrpg && $curParentPrpg->GetIsNoFlow() != $parsedLayers[$i]->GetIsNoFlow() );
			$newParent = 1
			  if (
				      defined $curParentPrpg
				   && $curParentPrpg->GetIsNoFlow()
				   && $parsedLayers[$i]->GetIsNoFlow()
				   && $curParentPrpg->GetNoFlowType() ne $noFlowType
			  );

			if ($newParent) {

				# store preview parent to final list
				if ( defined $curParentPrpg ) {

					push( @stackupL, $curParentPrpg );

				}

				$curParentPrpg               = PrepregLayer->new();
				$curParentPrpg->{"type"}     = Enums->MaterialType_PREPREG;
				$curParentPrpg->{"thick"}    = 0;
				$curParentPrpg->{"text"}     = "";
				$curParentPrpg->{"typetext"} = $parsedLayers[$i]->GetTextType();
				$curParentPrpg->{"parent"}   = 1;
				$curParentPrpg->{"noFlow"}   = $parsedLayers[$i]->GetIsNoFlow();
				$curParentPrpg->{"noFlowType"} = $noFlowType if ( $parsedLayers[$i]->GetIsNoFlow() );

			}

			# push child prepreg to parent
			my $childPrpgInfo = $parsedLayers[$i];

			$childPrpgInfo->{"noFlowType"} = $noFlowType if ( $childPrpgInfo->GetIsNoFlow() );

			$curParentPrpg->AddChildPrepreg($childPrpgInfo);

			# store last prepreg to list
			my $layerNextInfo = $parsedLayers[ $i + 1 ] if ( $i < scalar(@parsedLayers) );
			if ( defined $curParentPrpg && $layerNextInfo->GetType() ne Enums->MaterialType_PREPREG ) {

				push( @stackupL, $curParentPrpg );
				$curParentPrpg = undef;
			}

		}
	}

	$self->{"layers"} = \@stackupL;
}

# Set other property of stackup
sub __SetOtherProperty {
	my $self = shift;

	my @stackupL = @{ $self->{"layers"} };

	#set cu layers count
	$self->{"layerCnt"} = scalar( grep GeneralHelper->RegexEquals( $_->{type}, Enums->MaterialType_COPPER ), @stackupL );
	
	
	$self->{"nominalThick"} = $self->{"parser"}->GetNominalThick();

}

##computation of prepreg thickness depending on Cu usage in percent
#sub __AdjustPrepregThickness {
#	my $self = shift;
#
#	my @stackupL = @{ $self->{"layers"} };
#
#	for ( my $i = 0 ; $i < scalar(@stackupL) ; $i++ ) {
#
#		if ( $stackupL[$i]->GetType() eq Enums->MaterialType_PREPREG ) {
#
#			# 1) Set final parent prepreg thick by sum all child prepregs thick
#
#			foreach my $p ( $stackupL[$i]->GetAllPrepregs() ) {
#				$stackupL[$i]->{"thick"} += $p->GetThick();
#			}
#		}
#	}
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupBase::StackupBase';

	my $jobId   = "d152456";
	my $stackup = StackupBase->new($jobId);

	die;

}

1;

