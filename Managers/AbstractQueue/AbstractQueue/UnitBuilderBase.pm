
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::UnitBuilderBase;
 

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
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"jobStrData"} = shift;

	return $self;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

