#-------------------------------------------------------------------------------------------#
# Description: Base class, keep ob task data for one job, 
# which fill be processed by "Exporter utility"
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::ExportData;
use base("Managers::AbstractQueue::Task::TaskData::TaskData");

#3th party library
use strict;
use warnings;
use File::Copy;
use Wx;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_);

	bless($self);
 

	# EXPORT PROPERTIES
	 
	$self->{"settings"}->{"toProduce"}    = undef;    # sent to produce 0/1
	$self->{"settings"}->{"formPosX"}     = undef;    # position of export cheker form
	$self->{"settings"}->{"formPosY"}     = undef;    # position of export cheker form

	return $self;                                     # Return the reference to the hash.
}

sub GetToProduce {
	my $self = shift;

	return $self->{"settings"}->{"toProduce"};
}

sub GetFormPosition {
	my $self = shift;

	my $pos = Wx::Point->new( $self->{"settings"}->{"formPosX"}, $self->{"settings"}->{"formPosY"} );
	return $pos;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

