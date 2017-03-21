
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifMngr;
use base('Packages::ItemResult::ItemEventMngr');
 


#3th party library
use strict;
use warnings;
 

#local library

#use aliased 'Packages::Export::NifExport::NifSection';
#use aliased 'Packages::Export::NifExport::NifBuilders::V0Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::V1Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::V2Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::VVBuilder';
#use aliased 'Packages::Export::NifExport::NifBuilders::PoolBuilder';
#use aliased 'Helpers::JobHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	 
	$self->{"stepList"} = StepList->new($self->{"inCAM"}, $self->{"jobId"}, "panel", "f"); 
	 
	
	 
	return $self;
}

 
sub Run {
	my $self = shift;
	
	$self->{"stepList"}->Init();
	
	

 
}

sub Continue{
	my $self = shift;
	
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

