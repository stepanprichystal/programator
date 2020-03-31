
#-------------------------------------------------------------------------------------------#
# Description: Parse Multical xml stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::StackupParsers::MultiCalParser;

use Class::Interface;
&implements('Packages::Stackup::StackupBase::StackupParsers::IStackupParser');

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Enums';
use aliased 'Packages::Stackup::StackupBase::StackupHelper';
use aliased 'Packages::Stackup::StackupBase::StackupInfo';
use aliased 'Packages::Stackup::StackupBase::Layer::PrepregLayer';
use aliased 'Packages::Stackup::StackupBase::Layer::CoreLayer';
use aliased 'Packages::Stackup::StackupBase::Layer::CopperLayer';
use aliased 'Packages::Stackup::StackupBase::Layer::StackupLayerBase';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	return $self;
}

#Return array with stackup info
#Every item array is Hash, which contain information about layer, like thick, usage, name etc.
sub ParseStackup {
	my $self = shift;

	my $jobId = $self->{"jobId"};
	print STDERR " SLOZENIpcbid = $jobId\n";

	my $stcFile = FileHelper->GetFileNameByPattern( EnumsPaths->Jobs_STACKUPS, $jobId );
	print STDERR " SLOZENI Filter = $stcFile\n";

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

	close($fStackupXml);
	unlink(EnumsPaths->Client_INCAMTMPOTHER . $fname);
	
	if(defined $xml->{"soll"} && $xml->{"soll"} ne ""){
		
		my $nom = $xml->{"soll"};
		$nom =~ s/,/\./;
		$nom *=1000;
		$self->{"nominalThick"} = $nom;
	}

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
			$layerInfo->{"id"}           = $element->{id};

			push( @thickList, $layerInfo );

		}
		elsif ( GeneralHelper->RegexEquals( Enums->MaterialType_PREPREG, $elType ) ) {
			my $info = $stackuInfoData->GetPrepregInfo( $element->{qId}, $element->{id}, $realPrepregThicks );

			my $layerInfo = PrepregLayer->new();

			$layerInfo->{"type"}     = Enums->MaterialType_PREPREG;
			$layerInfo->{"thick"}    = $info->{d};
			$layerInfo->{"text"}     = $info->{text};
			$layerInfo->{"typetext"} = $info->{typetext};
			$layerInfo->{"id"}       = $element->{id};
			$layerInfo->{"qId"}      = $element->{qId};

			# prepreg is noflow if contains text "no flow"
			$layerInfo->{"noFlow"} = $layerInfo->{"typetext"} =~ /((no)|(low)).*flow/i ? 1 : 0;

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
			$layerInfo->{"id"}         = $element->{id};
			$layerInfo->{"qId"}        = $element->{qId};

			push( @thickList, $layerInfo );
		}

	}

	return @thickList;
}

sub GetNominalThick {
	my $self = shift;


	return $self->{"nominalThick"};
}



  #-------------------------------------------------------------------------------------------#
  #  Place for testing..
  #-------------------------------------------------------------------------------------------#
  my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

