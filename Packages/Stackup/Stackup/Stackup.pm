
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
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::Stackup::StackupBase::StackupHelper';
use aliased 'Packages::Stackup::Stackup::StackupBuilder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Create new Stackup
# Before initialization new object, chceck cache
sub new {
	my $class = shift;
	my $self  = {};

	my $inCAM = shift;
	my $jobId = shift;    # pcb id

	my $cache = Cache::MemoryCache->new();

	my $key     = "stackup_" . $jobId;
	my $stackup = $cache->get($key);     #check cache

	#if doesnt exist in cache, do normal initialization
	if ( !defined $stackup ) {

		$self = $class->SUPER::new( $jobId, @_ );
		$cache->set( $key, $self, 200 );
	}
	else {
		$self = $stackup;
	}

	bless $self;

	# Properties

	$self->{"inCAM"} = $inCAM;

	# Is stackup progressive lamination
	$self->{"sequentialLam"} = 0;

	# Number of pressing
	$self->{"pressCount"} = 0;

	#info (hash) for each pressing, which layer are pressed (most top/bot layers)
	# type of item is <ProductPress>
	$self->{"productPress"} = {};

	# type of item is <ProductInput>
	$self->{"productInputs"} = [];
	
	# Structure contains IProduct reference to each copper layer
	# which depand on attributes: PLugging, Outer core, etc..
	$self->{"copperMatrix"} = [];

	my $builder = StackupBuilder->new( $inCAM, $jobId, $self );
	$builder->BuildStackupLamination();

	return $self;
}

# Return number of pressing
sub GetPressCount {
	my $self = shift;

	return $self->{"pressCount"};
}

# Return info about each pressing
sub GetPressInfo {
	my $self = shift;

	return %{ $self->{"productPress"} };
}

# Return total thick of this stackup in µm
# Do not consider extra plating (drilled core, progress lamination)
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

sub GetSequentialLam {
	my $self = shift;

	return $self->{"sequentialLam"};
}



sub GetSideByCuLayer {
	my $self = shift;

	die "Not implemented";

}

#Return final thickness (in mm units!!) of multilayer pcb base on Cu layer number
#- This has not be thick of whole pcb, but e.g. thick of one requested core with top/bot cu
#- Or thick of pcb from layer v2 - v5..
sub GetThickByCuLayer {
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
	my $isProgLamin = $self->GetSequentialLam();

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


#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __GetProductByLayer {
	my $self      = shift;
	my $layerName = shift;
	my $outerCore = shift;
	my $plugging  = shift;
	
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::Stackup::Stackup';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d152456";
	my $stackup = Stackup->new( $inCAM, $jobId );

	print $stackup;

	print 1;
}

1;

