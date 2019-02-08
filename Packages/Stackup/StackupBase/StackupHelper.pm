#-------------------------------------------------------------------------------------------#
# Description: Helper class, which is used by Stackup.pm class for various helper purposes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::StackupHelper;

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
#use aliased 'Packages::Stackup::StackupBase::StackupHelper';
#use aliased 'Packages::Stackup::Stackup::StackupLayerHelper';
#use aliased 'Packages::Stackup::Stackup::StackupLayer';
#use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return number of layer (means cu layers), by layer name
# c = 1, v2 = 2, v3 = 3, ...
sub GetLayerCopperNumber{
	my $self      = shift;
	my $layerName = shift;
	my $layerCount = shift;
	

	# get number from layer name;
	if ( $layerName =~ /\d/ ) {
		$layerName =~ s/\D//g;
	}
	elsif ( $layerName eq "c" ) {
		$layerName = 1;
	}
	elsif ( $layerName eq "s" ) {
		$layerName = $layerCount;
	}
	
	return $layerName;
}



#Read prepreg's theoretical thickness from special file.
#Temp solution due incapability calculate it.
sub __ReadPrepregThick {
	my $self = shift;
	
	my $f    = FileHelper->Open( GeneralHelper->Root() . '/Resources/PrepregThicknes.txt' )   or die "Can't open file. $_";

	my %hash;
	while ( my $line = <$f> ) {

		$line =~ s/\s//g;

		unless ( $line eq "" ) {
			( my $key, my $thick ) = split /=/, $line;
			$key = GeneralHelper->Trim_s_W($key);
			$hash{$key} = $thick;

		}
	}

	FileHelper->Close($f);

	return \%hash;
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
