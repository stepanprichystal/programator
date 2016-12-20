#-------------------------------------------------------------------------------------------#
# Description: Helper class, can load technical parameter about prepregs, cores, coppers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupInfo;

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

#use aliased 'Packages::Stackup::Stackup::StackupHelper';
#use aliased 'Packages::Stackup::Stackup::StackupLayerHelper';
#use aliased 'Packages::Stackup::Stackup::StackupLayer';
#use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	#my $multicalPath = shift;

	$self->__LoadInfoFiles();

	return $self;
}



# open all files to avoid repeated opening files
sub __LoadInfoFiles {
	my $self = shift;
	#my $multicalPath    = shift;

	#my $fname2 = FileHelper->ChangeEncoding( EnumsPaths->Client_MULTICALDB, "cp1252", "utf8" );
 
	#my $strfMultical = FileHelper->ReadAsString( EnumsPaths->Client_INCAMTMPOTHER . $fname2 );
	
	my $strfMultical = FileHelper->ReadAsString( EnumsPaths->Client_MULTICALDB );
 


	my $xml = XMLin( $strfMultical, KeyAttr => { quality => 'id' }, );
	$self->{"multicalInfo"} = $xml;
 
}

#Return dictionary with core info by id's
sub GetCoreInfo {
	my $self = shift;
	my $qId  = shift;    #core quality id
	my $id   = shift;    #core id

#	my $xml = XMLin(
#		$fStr,
#
#		#ForceArray => ,
#		KeyAttr => { quality => 'id' },
#	);

	my $xml = $self->{"multicalInfo"};

	my $core    = $xml->{core};
	my $quality = $core->{quality};

	# get core quality number id
	my $coreType = $quality->{$qId};
	my $coreInfo = $coreType->{item};

	my $len = 0;
	for ( my $i = 0 ; $i < scalar(@$coreInfo) ; $i++ ) {

		if ( @$coreInfo[$i]->{id} == $id ) {

			@$coreInfo[$i]->{typetext} = $coreType->{text};

			return @$coreInfo[$i];
		}
	}
}

#Return dictionary with copper info by id's
sub GetCopperInfo {
	my $self = shift;
	my $id   = shift;    #prepreg id

	#my $xml = XMLin( $fStr, KeyAttr => { quality => 'id' }, );

	my $xml = $self->{"multicalInfo"};

	my $coppers     = $xml->{copper};
	my $coppersInfo = $coppers->{item};

	# get copper info by id
	my $len = 0;
	for ( my $i = 0 ; $i < scalar(@$coppersInfo) ; $i++ ) {

		if ( @$coppersInfo[$i]->{id} == $id ) {
			return @$coppersInfo[$i];
		}
	}
}

#Return dictionary with prepreg info by id's
sub GetPrepregInfo {
	my $self       = shift;
	my $qId        = shift;    #prepreg quality id
	my $id         = shift;    #prepreg id
	my $realThicks = shift;

	#my $xml = XMLin(
	#	$fStr,
	#
	#	#ForceArray => ,
	#	KeyAttr => { quality => 'id' },
	#);
	
	my $xml = $self->{"multicalInfo"};

	my $prepreg = $xml->{prepreg};
	my $quality = $prepreg->{quality};

	# get prepreg quality number id
	my $prereType    = $quality->{$qId};
	my $preregesInfo = $prereType->{item};

	my $len = 0;
	for ( my $i = 0 ; $i < scalar(@$preregesInfo) ; $i++ ) {

		if ( @$preregesInfo[$i]->{id} == $id ) {

			my $key = $prereType->{text} . @$preregesInfo[$i]->{text};
			$key = GeneralHelper->Trim_s_W($key);

			@$preregesInfo[$i]->{d}        = $realThicks->{$key};
			@$preregesInfo[$i]->{typetext} = $prereType->{text};

			return @$preregesInfo[$i];
		}
	}
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print 1;

	#my $test = Connectors::HeliosConnector::HegMethods->GetMaterialType("F34140");

	#print $test;

}

1;
