
#-------------------------------------------------------------------------------------------#
# Description: Base class, responsible for creating stackup from given data (Multicall xml,...)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupBase;

#3th party library
use strict;
use warnings;
use XML::Simple;


#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Stackup::StackupHelper';
use aliased 'Packages::Stackup::Stackup::Press::StackupPress';
use aliased 'Packages::Stackup::Stackup::StackupInfo';
use aliased 'Packages::Stackup::Stackup::Layer::PrepregLayer';
use aliased 'Packages::Stackup::Stackup::Layer::CoreLayer';
use aliased 'Packages::Stackup::Stackup::Layer::CopperLayer';
use aliased 'Packages::Stackup::Stackup::Layer::StackupLayer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
 
	#id of pcb stackup
	$self->{"pcbId"} = shift;

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

	my $pcbId = $self->{"pcbId"};

	my @stackupList = $self->__GetStackupLayerInfo($pcbId);
	my @thickList   = ();

	for ( my $i = 0 ; $i < scalar(@stackupList) ; $i++ ) {

		my $layerInfo = $stackupList[$i];

		if ( GeneralHelper->RegexEquals( Enums->MaterialType_PREPREG, $layerInfo->{"type"} ) ) {

			$layerInfo->{"text"}     = "";
			$layerInfo->{"typetext"} = "";

			my $prevType = $thickList[ ( scalar @thickList ) - 1 ]->{"type"};
			my $th;

			#if previous layer was prereg, sum actual prepregs's
			#thick with previous prepreg thicks
			if ( GeneralHelper->RegexEquals( Enums->MaterialType_PREPREG, $prevType ) ) {

				$th = $thickList[ ( scalar @thickList ) - 1 ]->{"thick"};
				if ($th) {
					$layerInfo->{"thick"} += $thickList[ ( scalar @thickList ) - 1 ]->{"thick"};
				}

				$thickList[ ( scalar @thickList ) - 1 ] = $layerInfo;

			}
			else {
				push( @thickList, $layerInfo );
			}
		}
		else {

			push( @thickList, $layerInfo );
		}
	}

	$self->__ComputePrepregsByCu( \@thickList );

	$self->{"layers"} = \@thickList;

}

#Return array with stackup info
#Every item array is Hash, which contain information about layer, like thick, usage, name etc.
sub __GetStackupLayerInfo {
	my $self = shift;

	my $pcbId = $self->{"pcbId"};

	my $stcFile = FileHelper->GetFileNameByPattern( EnumsPaths->Jobs_STACKUPS, $pcbId );
	my $fStackupXml = undef;

	#check validation of pcb's stackup xml file
	#if ( FileHelper->IsXMLValid($stcFile) ) {
	#	my $fStackupXml = FileHelper->Open($stcFile);
	#}
	#else {
	#
	my $fname = FileHelper->ChangeEncoding( $stcFile, "cp1252", "utf8" );
	$fStackupXml = FileHelper->Open( EnumsPaths->Client_INCAMTMPOTHER . $fname );

	#}

	#open($fStackupXml,'<:encoding(UTF-8)', $stcFile) or die "Error opening $file: $!";

	my @thickList = ();

	my $xml = XMLin(
					 $fStackupXml,
					 ForceArray => undef,
					 KeyAttr    => undef,
	);

	my @elements = @{ $xml->{element} };

	my $elType     = undef;
	my $copperInfo = undef;

	my $fMultical = undef;

	#my $strfMultical = undef;

	#check validation of Multicall db xml file (ml.xml)

	#if ( FileHelper->IsXMLValid( EnumsPaths->Client_MULTICALDB ) ) {

	#	$strfMultical = FileHelper->ReadAsString( EnumsPaths->Client_MULTICALDB );
	#}
	#else {

	#}

	#open(FILE,'<:encoding(UTF-8)', EnumsPaths->Client_MULTICALDB) or die "Error opening $file: $!";
	#$strfMultical = join( "", <FILE> );

	#temporary solution, reading real thickness of prepreg from special file
	my $realPrepregThicks = StackupHelper->__ReadPrepregThick();

	#helper class with technical info for stackup material
	my $stackuInfoData = StackupInfo->new();

	my $element   = undef;       #actual investigate element
	my $len       = @elements;
	my $coreCnt   = 0;           #tell how many cores stackup contains
	my $copperCnt = 0;           #tell how many cores stackup contains

	for ( my $i = 0 ; $i < $len ; $i++ ) {

		$element = $elements[$i];
		$elType  = $element->{type};

		my $layerInfo = StackupLayer->new();

		#$layerInfo->{"type"} = $elType;

		if ( GeneralHelper->RegexEquals( Enums->MaterialType_COPPER, $elType ) ) {

			my $layerInfo = CopperLayer->new();

			$copperCnt++;

			my $info = $stackuInfoData->GetCopperInfo( $element->{id} );
			$layerInfo->{"type"}         = Enums->MaterialType_COPPER;
			$layerInfo->{"thick"}        = $info->{d};
			$layerInfo->{"usage"}        = $element->{p} / 100.0;        #percentage usage of cu
			$layerInfo->{"text"}         = $info->{text};
			$layerInfo->{"typetext"}     = $info->{typetext};
			$layerInfo->{"copperNumber"} = $copperCnt;

			push( @thickList, $layerInfo );

		}
		elsif ( GeneralHelper->RegexEquals( Enums->MaterialType_PREPREG, $elType ) ) {
			my $info = $stackuInfoData->GetPrepregInfo( $element->{qId}, $element->{id}, $realPrepregThicks );

			my $layerInfo = PrepregLayer->new();

			$layerInfo->{"type"}     = Enums->MaterialType_PREPREG;
			$layerInfo->{"thick"}    = $info->{d};
			$layerInfo->{"text"}     = $info->{text};
			$layerInfo->{"typetext"} = $info->{typetext};

			push( @thickList, $layerInfo );

		}
		elsif ( Enums->MaterialType_CORE =~ /$elType/i ) {

			my $layerInfo = CoreLayer->new();

			$coreCnt++;

			my $info = $stackuInfoData->GetCoreInfo( $element->{qId}, $element->{id} );

			$layerInfo->{"type"}       = Enums->MaterialType_CORE;
			$layerInfo->{"thick"}      = $info->{d};
			$layerInfo->{"text"}       = $info->{text};
			$layerInfo->{"typetext"}   = $info->{typetext};
			$layerInfo->{"coreNumber"} = $coreCnt;
			push( @thickList, $layerInfo );
		}

	}

	#Set copper name c, v2....., s
	foreach my $l (@thickList) {

		if ( $l->{"type"} eq Enums->MaterialType_COPPER ) {
			if ( $l->{"copperNumber"} == 1 ) {

				$l->{"copperName"} = "c";

			}
			elsif ( $l->{"copperNumber"} == scalar(@thickList) ) {
				$l->{"copperName"} = "s";
			}
			else {

				$l->{"copperName"} = "v" . $l->{"copperNumber"};
			}
		}
	}

	#Set core top/bot copper layers
	for ( my $i = 0 ; $i < scalar(@thickList) ; $i++ ) {

		my $l = $thickList[$i];

		if ( $l->{"type"} eq Enums->MaterialType_CORE ) {

			my $topCopper = $thickList[ $i - 1 ];

			if ( $topCopper && $topCopper->{"type"} eq Enums->MaterialType_COPPER ) {

				$l->{"topCopperLayer"} = $topCopper;
			}

			my $botCopper = $thickList[ $i + 1 ];

			if ( $botCopper && $botCopper->{"type"} eq Enums->MaterialType_COPPER ) {

				$l->{"botCopperLayer"} = $botCopper;
			}
		}
	}


	return @thickList;
}

#set info about pressing and type of stackup
sub __SetStackupPressInfo {
	my $self = shift;

	my $pcbId = $self->{"pcbId"};    #pcb id

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

	for ( my $i = scalar( $lCuCount / 2 ) ; $i >= 0 ; $i-- ) {

		#for inner layers only
		my $nearestCoreIdx = $self->_GetIndexOfNearestCore( $i + 1 );

		#if TOP
		if ( $nearestCoreIdx == -1 || $i + 1 == 1 ) {

			$self->{"pressCount"}++;

			my $order = $self->{"pressCount"};

			my $stackupPress = StackupPress->new();

			$stackupPress->{"order"}     = $order;
			$stackupPress->{"top"}       = $lNames[$i];
			$stackupPress->{"topNumber"} = $i + 1;
			$stackupPress->{"bot"}       = $lNames[ $lCuCount - $i - 1 ];
			$stackupPress->{"botNumber"} = $lCuCount - $i;

			$self->{"press"}{$order} = $stackupPress;

			#if it is not TOP layer, its mean progressive lamination
			if ( $i + 1 != 1 ) {

				$self->{"lamination"} = 1;
			}
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
	if ( $lCuNumber == 1 || $lCuNumber == $lCuCount ) {
		return $coreIdx;
	}

	#find connected core and return thick of that + cu layer
	my $lCuIndex = $self->_GetIndexOfCuLayer($lCuNumber);

	#try find CORE above Cu..
	%info = %{ $thickList[ $lCuIndex - 1 ] };
	if ( GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_CORE ) ) {

		$coreIdx = $lCuIndex - 1;
	}

	#try find CORE under Cu..
	%info = %{ $thickList[ $lCuIndex + 1 ] };
	if ( GeneralHelper->RegexEquals( $info{type}, Enums->MaterialType_CORE ) ) {

		$coreIdx = $lCuIndex + 1;
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

