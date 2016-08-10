
#-------------------------------------------------------------------------------------------#
# Description: Base section builder. Section builder are responsible for content of section
# Allow add new rows to section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderBase;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
	
	#require rows in nif section
	$self->{"require"} = shift;
	
	return $self;
}

sub Init{
	my $self = shift;
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift; 
	$self->{"nifData"} = shift; 
	$self->{"layerCnt"} = shift;
	
}

# Test if given row is requested
# NIF Builder must decide, if wants or not particular row in section 
sub _IsRequire{
	my $self = shift;
	my $rowName = shift;
	
	if ( scalar(grep {$_ eq $rowName} @{$self->{"require"}}) > 0){
		
		return 1;
	}else{
		return 0;
	}
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

