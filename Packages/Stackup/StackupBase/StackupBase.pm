
#-------------------------------------------------------------------------------------------#
# Description: Base class, responsible for creating stackup from given data (Multicall xml,...)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::StackupBase;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::StackupBase::Press::StackupPress';
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
	my @layers = ();
	$self->{"layers"} = \@layers;

	# Is stackup progressive lamination
	$self->{"lamination"} = 0;

	# Number of pressing
	$self->{"pressCount"} = 0;

	#info (hash) for each pressing, which layer are pressed (most top/bot layers)
	# type of item is <StackupPress>
	$self->{"press"} = undef;

	# Cu layer count
	$self->{"layerCnt"} = undef;

	$self->__CreateStackup();

	return $self;
}

# Return all layers of stackup
sub GetAllLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}

# Return number of pressing
sub GetPressCount {
	my $self = shift;

	return $self->{"pressCount"};
}

# Return info about each pressing
sub GetPressInfo {
	my $self = shift;

	return %{ $self->{"press"} };
}

sub ProgressLamination {
	my $self = shift;

	return $self->{"lamination"};
}

# Return all stackup cores
sub GetAllCores {
	my $self = shift;

	my @thickList = @{ $self->{"layers"} };
	my @cores     = ();

	foreach my $l (@thickList) {

		if ( GeneralHelper->RegexEquals( $l->GetType(), Enums->MaterialType_CORE ) ) {
			push( @cores, $l );
		}
	}

	return @cores;
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

# Return source type which stackup read from
sub GetStackupSource {
	my $self = shift;
	
	my $p    = $self->{"parser"};

	return Enums->StackupSource_INSTACK if ( ref($p) && $p->isa("Packages::Stackup::StackupBase::StackupParsers::InStackParser") );
	return Enums->StackupSource_ML if ( ref($p) && $p->isa("Packages::Stackup::StackupBase::StackupParsers::MultiCalParser") )
}

sub __CreateStackup {
	my $self = shift;

	#set info about layers of stackup
	$self->__SetStackupLayers();

	#set other stackup property
	$self->__SetOtherProperty();

	#set info about pressing and type of stackup
	$self->__SetStackupPressInfo();

}

#set info about layers of stackup
sub __SetStackupLayers {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	# Return parsed stackup layers from top 2 bot
	my @stackupList = $self->{"parser"}->ParseStackup();

	my @thickList = ();

	# Merge prepregs, create parent prepreg
	for ( my $i = 0 ; $i < scalar(@stackupList) ; $i++ ) {

		my $layerInfo = $stackupList[$i];
		my $layerPrevInfo;

		if ( $i > 0 ) {
			$layerPrevInfo = $stackupList[ $i - 1 ];
		}

		if ( $layerInfo->GetType() eq Enums->MaterialType_PREPREG ) {

			# if first prepreg after cu, create parent prepreg
			if ( $layerPrevInfo && $layerPrevInfo->GetType() eq Enums->MaterialType_COPPER ) {

				$layerInfo = PrepregLayer->new();

				$layerInfo->{"type"}     = Enums->MaterialType_PREPREG;
				$layerInfo->{"thick"}    = 0;
				$layerInfo->{"text"}     = "";
				$layerInfo->{"typetext"} = $layerInfo->GetTextType();
				$layerInfo->{"parent"}   = 1;

				# push all child prepregs to parent prepreg

				my $layerInfo2 = $stackupList[$i];

				while ( $layerInfo2->GetType() eq Enums->MaterialType_PREPREG ) {

					$layerInfo->AddChildPrepreg($layerInfo2);

					$i++;
					$layerInfo2 = $stackupList[$i];

				}
				$i--;

				#set thick by sum all child prepregs thick
				my @all = $layerInfo->GetAllPrepregs();
				foreach my $p (@all) {
					$layerInfo->{"thick"} += $p->GetThick();
				}
			}
		}

		push( @thickList, $layerInfo );
	}

	$self->__ComputePrepregsByCu( \@thickList );

	$self->{"layers"} = \@thickList;

}

#set info about pressing and type of stackup
sub __SetStackupPressInfo {
	my $self = shift;

	my $jobId = $self->{"jobId"};    #pcb id

	my @thickList = @{ $self->{"layers"} };

	#number of signal layers
	my $lCuCount = $self->{"layerCnt"};

	my @lNames = ();

	for ( my $i = 1 ; $i <= scalar($lCuCount) ; $i++ ) {

		if ( $i == 1 ) {
			push( @lNames, "c" );
		}
		elsif ( $i == scalar($lCuCount) ) {
			push( @lNames, "s" );
		}
		else {
			push( @lNames, "v" . $i );
		}
	}

	my %pressInfo = ();

	for ( my $i = int( $lCuCount / 2 ) ; $i >= 0 ; $i-- ) {

		#for inner layers only
		my $nearestCoreIdx = $self->_GetIndexOfNearestCore( $i + 1 );

		#if TOP

		#if core was found OR if wasn't but there is no pressing already ( two pressed cores together)
		if ( $nearestCoreIdx == -1 || $i == 0 && $nearestCoreIdx && $self->{"pressCount"} == 0 ) {

			my $order = $self->{"pressCount"};
			$order++;

			my $stackupPress = StackupPress->new();

			# Cores was not found, it is mean, first/last copper without core
			# Or inner copper without core => lamination
			if ( $nearestCoreIdx == -1 ) {

				$stackupPress->{"top"}       = $lNames[$i];
				$stackupPress->{"topNumber"} = $i + 1;
				$stackupPress->{"bot"}       = $lNames[ $lCuCount - $i - 1 ];
				$stackupPress->{"botNumber"} = $lCuCount - $i;

				#if it is not TOP layer, its mean progressive lamination
				if ( $i + 1 != 1 ) {

					$self->{"lamination"} = 1;
				}

			}

			# Two pressed cores together, cores are entirely on top + bot
			elsif ( $i == 0 && $nearestCoreIdx > -1 && $self->{"pressCount"} == 0 ) {

				$stackupPress->{"top"}       = $lNames[$i];
				$stackupPress->{"topNumber"} = 1;
				$stackupPress->{"bot"}       = $lNames[ $lCuCount - 1 ];
				$stackupPress->{"botNumber"} = $lCuCount;
			}

			$stackupPress->{"order"} = $order;
			$self->{"press"}{$order} = $stackupPress;

			$self->{"pressCount"} = $order;
		}
	}

	return %pressInfo;
}

# Set other property of stackup
sub __SetOtherProperty {
	my $self = shift;

	my @thickList = @{ $self->{"layers"} };

	#set cu layers count
	$self->{"layerCnt"} = scalar( grep GeneralHelper->RegexEquals( $_->{type}, Enums->MaterialType_COPPER ), @thickList );

}

#computation of prepreg thickness depending on Cu usage in percent
sub __ComputePrepregsByCu {
	my $self      = shift;
	my @thickList = @{ shift(@_) };

	for ( my $i = 0 ; $i < scalar(@thickList) ; $i++ ) {

		my $l = $thickList[$i];

		if ( Enums->MaterialType_PREPREG =~ /$l->{type}/i ) {

			#sub TOP and BOT cu thinkness from prepreg thinkness
			#Theoretical calculation for one prepreg and two Cu is:
			# Thick = height(prepreg) - (height(topCu* (1-UsageInPer(topCu))  +   height(botCu* (1-UsageInPer(topCu)))

			$thickList[$i]->{thick} -=
			  $thickList[ $i - 1 ]->{thick} * ( 1 - $thickList[ $i - 1 ]->{usage} ) +
			  $thickList[ $i + 1 ]->{thick} * ( 1 - $thickList[ $i + 1 ]->{usage} );
		}
	}
}

#Get index of core, which is connected with given inner Cu layer <$lCuNumber>
sub _GetIndexOfNearestCore {
	my $self      = shift;
	my $lCuNumber = shift;

	my %info;

	my $lCuCount = $self->{"layerCnt"};

	my @thickList = @{ $self->{"layers"} };

	my $coreIdx = -1;

	#if layer is TOP or BOT
	#if ( $lCuNumber == 1 || $lCuNumber == $lCuCount ) {
	#	return $coreIdx;
	#}

	#find connected core and return thick of that + cu layer
	my $lCuIndex = $self->_GetIndexOfCuLayer($lCuNumber);

	#try find CORE above Cu..
	if ( $thickList[ $lCuIndex - 1 ] ) {

		%info = %{ $thickList[ $lCuIndex - 1 ] };
		if ( GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_CORE ) ) {

			$coreIdx = $lCuIndex - 1;
		}
	}

	#try find CORE under Cu..
	if ( $thickList[ $lCuIndex + 1 ] ) {

		%info = %{ $thickList[ $lCuIndex + 1 ] };
		if ( GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_CORE ) ) {

			$coreIdx = $lCuIndex + 1;
		}
	}

	return $coreIdx;
}

#return index of given Cu layer in thicklist
sub _GetIndexOfCuLayer {
	my $self      = shift;
	my $lCuNumber = shift;

	my $lCuCount  = $self->{"layerCnt"};
	my @thickList = @{ $self->{"layers"} };

	#find index in <@thicklist> of layer number <$lCuNumber>

	#if layer is TOP
	if ( $lCuNumber == 1 ) {
		return 0;
	}
	elsif ( $lCuNumber eq EnumsGeneral->Layers_BOT ) {
		return $lCuCount - 1;
	}

	my $cuLayerCnt = 0;
	for ( my $i = 0 ; $i < scalar(@thickList) ; $i++ ) {

		my %info = %{ $thickList[$i] };

		if ( GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_COPPER ) ) {
			$cuLayerCnt++;
		}

		if ( $cuLayerCnt == $lCuNumber ) {
			return $i;
		}
	}
	return -1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

