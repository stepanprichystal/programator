#-------------------------------------------------------------------------------------------#
# Description: Contains trigger methods, which work with MDI files
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::TriggerFunction::MDIFiles;

#3th party library
use strict;
use warnings;
use Path::Tiny qw(path);

#loading of locale modules
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';

#my $genesis = new Genesis;

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Function add value of tag <parts_total>, <parts_remaining> in each mdi-xml file of requested job
sub AddPartsNumber {
	my $self  = shift;
	my $jobId = shift;
	
	my $reg = $jobId.".*_mdi.xml";
	
	my @xmlFiles  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI,  $reg );
	
	unless(scalar(@xmlFiles)){
		return 1;
	} 
	
	my $info = HegMethods->GetInfoAfterStartProduce($jobId);
	
	if( !defined $info->{'pocet_prirezu'} ||   !defined $info->{'prirezu_navic'}){
		return 0;
	}
	  
 	my $parts = $info->{'pocet_prirezu'} + $info->{'prirezu_navic'};
 
	 
	foreach my $filename (@xmlFiles) {

		my $file = path($filename);

		my $data = $file->slurp_utf8;
		$data =~ s/(<parts_remaining>)(\d*)(<\/parts_remaining>)/$1$parts$3/i;
		$data =~ s/(<parts_total>)(\d*)(<\/parts_total>)/$1$parts$3/i;
		$file->spew_utf8($data);

	}
	
	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::TriggerFunction::MDIFiles';

	my $test = MDIFiles->AddPartsNumber("f13608");

	print $test;
 

}

1;

