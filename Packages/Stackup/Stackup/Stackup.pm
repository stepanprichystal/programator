
#-------------------------------------------------------------------------------------------#
# Description: Contain all information about pcb stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::Stackup;
use base('Packages::Stackup::StackupBase::StackupBase');

#3th party library
use strict;
use warnings;
use Cache::MemoryCache;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::StackupBase::StackupHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Create new Stackup
# Before initialization new object, chceck cache
sub new {
	my $class = shift;
	my $self  = {};

	my $pcbId = shift;    # pcb id

	my $cache = Cache::MemoryCache->new();

	my $key     = "stackup_" . $pcbId;
	my $stackup = $cache->get($key);     #check cache

	#if doesnt exist in cache, do normal initialization
	if ( !defined $stackup ) {

		$self = $class->SUPER::new( $pcbId, @_ );
		$cache->set( $key, $self, 200 );
	}
	else {
		$self = $stackup;
	}

	bless $self;

	return $self;
}

# Return total thick of this stackup in µm
sub GetFinalThick {
	my $self = shift;

	my $thick = 0;

	my %info;
	foreach my $lInfo ( @{ $self->{"layers"} } ) {

		%info = %{$lInfo};
		$thick += $info{thick};
	}

	return $thick;
}

# Return total thick of this stackup
sub GetCuLayerCnt {
	my $self = shift;

	my $lCount = scalar( grep { $_->GetType() eq Enums->MaterialType_COPPER } $self->GetAllLayers() );

	return $lCount;
}



# Return Cu layer by name (c, v2, v3 ...)
sub GetCuLayer {
	my $self      = shift;
	my $layerName = shift;

	my @thickList = @{ $self->{"layers"} };

	#get order number from layer name
	my $lCuNumber = StackupHelper->GetLayerCopperNumber( $layerName, $self->{"layerCnt"} );

	#get index of layer in <@{ $self->{"layers"} }>
	my $idx = $self->_GetIndexOfCuLayer($lCuNumber);

	return $thickList[$idx];
}

# If layer is copper type, return core type layer (if exist), which copper layer touches
sub GetCoreByCopperLayer {
	my $self      = shift;
	my $layerName = shift;

	my @thickList = @{ $self->{"layers"} };
	my $cuLayer   = $self->GetCuLayer($layerName);

	unless ( GeneralHelper->RegexEquals( $cuLayer->GetType(), Enums->MaterialType_COPPER ) ) {
		return 0;
	}

	#get order number from layer name
	my $lCuNumber = StackupHelper->GetLayerCopperNumber( $layerName, $self->{"layerCnt"} );

	my $coreIdx = $self->_GetIndexOfNearestCore($lCuNumber);

	if ( $coreIdx >= 0 ) {

		return $thickList[$coreIdx];
	}

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

	# filter out rigid cores
	if ($noRigid) {
		@cores = grep { $_->GetThick() > 100 } @cores;
	}

	# filter out flex cores
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

# Return type of material, which stackup is composed from
# Assume, all layers are same type, so take type from first core
sub GetStackupType {
	my $self = shift;

	my @cores = $self->GetAllCores();

	return $cores[0]->GetTextType();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::Stackup::Stackup';

	my $stackup = Stackup->new("d113608");

	my $mir = $stackup->GetFinalThick();

	print STDERR $mir;

	#my $stackup = Stackup->new("d99991");

	print 1;
}

1;

