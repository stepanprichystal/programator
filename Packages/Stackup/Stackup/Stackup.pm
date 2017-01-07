
#-------------------------------------------------------------------------------------------#
# Description: Contain all information about pcb stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::Stackup;
use base('Packages::Stackup::Stackup::StackupBase');

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
use aliased 'Packages::Stackup::Stackup::StackupHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Create new Stackup
# Before initialization new object, chceck cache
sub new {
	my $class = shift;
	my $self  = {};
	
	my $pcbId = shift; # pcb id

	my $cache = Cache::MemoryCache->new();

	my $key     = "stackup_" . $pcbId;
	my $stackup = $cache->get($key); #check cache

	#if doesnt exist in cache, do normal initialization
	if ( !defined $stackup ) {
		
		
		
		
		$self = $class->SUPER::new( $pcbId, @_ );
		$cache->set( $key, $self, 200);
	}
	else {
		$self = $stackup;
	}

	bless $self;

	return $self;
}


# Return total thick of this stackup
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

	my $lCount      = scalar(grep { $_->GetType() eq Enums->MaterialType_COPPER  } $self->GetAllLayers());
	
	return $lCount;
}

#Return final thickness (in mm units!!) of multilayer pcb base on Cu layer number
#- This has not be thick of whole pcb, but e.g. thick of one requested core with top/bot cu
#- Or thick of pcb from layer v2 - v5..
sub GetThickByLayerName {
	my $self = shift;

	my $lCuNumber = shift;    #layer of number. Simple c,1,2,s or v1, v2 use ENUMS::Layers

	my $pcbId = $self->{"pcbId"};
	my $thick = 0;                  #total thick
	my %info;                       #help variable for layer info
	my @thickList = @{ $self->{"layers"} };

	#number of Cu layers
	my $lCuCount = scalar( grep GeneralHelper->RegexEquals( $_->{type}, Enums->MaterialType_COPPER ), @thickList );

	#get order number from layer name
	$lCuNumber = StackupHelper->GetLayerCopperNumber( $lCuNumber, $lCuCount );

	#get index of Cu layer in <@thickList>.
	my $lCuIdx         = $self->_GetIndexOfCuLayer($lCuNumber);
	my $nearestCoreIdx = $self->_GetIndexOfNearestCore($lCuNumber);

	#test if given Cu layer <$lCuNumber> is outer, thus TOP or BOTTOM
	my $lCuIsOuter = $lCuNumber == 1 || $lCuNumber == $lCuCount ? 1 : 0;

	#when given Cu layer <$lCuNumber> is surounded by prepregs, thus it means progressive lamination
	my $isProgLamin = $self->ProgressLamination();

	#Calculation thickness base on stackup properties
	if ($lCuIsOuter) {    #we want total thick of pcb

		foreach my $lInfo (@thickList) {
			%info = %{$lInfo};
			$thick += $info{thick};
		}
	}
	elsif ($isProgLamin) {    #progressive lamination

		#fin out if it's Cu layer is put lower then middle of pcb
		my $isTop = $lCuNumber <= $lCuCount / 2 ? 1 : 0;

		#index, which we will start to read thickness off each layer from
		my $startIdx = $lCuIdx;
		if ( !$isTop ) {

			$startIdx = ( scalar(@thickList) - 1 ) - $lCuIdx;
		}

		#get value, how many Cu layer we have to go through
		my $lCountToRead = scalar(@thickList) - ( 2 * ($startIdx) );

		#begin to read thickness with <$startIdx> index
		my $cuLayerCnt = 0;
		for ( my $i = $startIdx ; $i < scalar(@thickList) ; $i++ ) {

			%info = %{ $thickList[$i] };

			#start to read thicks of all material layers
			if ( $lCountToRead > 0 ) {

				$thick += $info{thick};
				$lCountToRead--;
			}
		}
	}
	else {    #standart stackup plus three layer pcb..

		#get nearest core thick + top Cu core thick + bot Cu core thick
		%info = %{ $thickList[ $nearestCoreIdx - 1 ] };    #top Cu thick
		$thick += GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_COPPER ) ? $info{thick} : 0;
		%info = %{ $thickList[$nearestCoreIdx] };          #core thick
		$thick += GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_CORE ) ? $info{thick} : 0;
		%info = %{ $thickList[ $nearestCoreIdx + 1 ] };    #bot Cu thick
		$thick += GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_COPPER ) ? $info{thick} : 0;
	}

	#convert to milimeter
	$thick = $thick / 1000.0;

	return $thick;

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

# Return all layers type of core
sub GetAllCores {
	my $self = shift;

	my @thickList = @{ $self->{"layers"} };
	my @cores     = ();

	foreach my $l (@thickList) {

		if ( GeneralHelper->RegexEquals( $l->GetType(), Enums->MaterialType_CORE ) ) {
			push( @cores, $l );
		}
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

	my @cores =  $self->GetAllCores();
	
	return $cores[0]->GetTextType();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::Stackup::Stackup';

	my $stackup = Stackup->new("f52457");
	#my $stackup = Stackup->new("d99991");
 

	print 1;
}

1;

