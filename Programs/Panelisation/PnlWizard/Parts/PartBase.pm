
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::PartBase;

# Abstract class #

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Enums';
#use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;
	$self->{"partId"} = undef;

	$self->{"partWrapper"} = undef;    #wrapper, which form is placed in
	$self->{"form"}         = undef;    #form which represent GUI of this group
	#$self->{"eventClass"}   = undef;    # define connection between all groups by group and envents handler

	$self->{"dataMngr"}    = undef;     # manager, which is responsible for create, update group data
	$self->{"cellWidth"}   = 0;         #width of cell/unit form (%), placed in exporter table row
	$self->{"exportOrder"} = 0;         #Order, which unit will be ecported

	# Events

#	$self->{"onChangeState"} = Event->new();
#	$self->{"switchAppEvt"}  = Event->new();

	return $self;
}


sub GetPartId{
	my $self       = shift;
	
	return $self->{"partId"};
	
	
}

sub _ProcessCreatorSettings{
	
	# 1)Convert model to Creator settings
	
	# 2)Process creator on background^
	my $creatorType = "test_creator";
	
	
	$self->{"newBackgroundTaskEvt"}->Do($creatorType, )
	
}

sub __BackgroundWorker {
	my $taskId            = shift;
	my $taskParams        = shift;
	my $inCAM             = shift;
	my $thrPogressInfoEvt = shift;
	my $thrMessageInfoEvt = shift;

}
  

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
