
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::BackgroundTaskMngr;

# Abstract class #

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library
#use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"backgroundWorker"} = shift;

	# PROPERTIES

	# Define all creators for converting Creator settings <=> Creator model data
	$self->{"creators"}                                              = {};
	$self->{"creators"}->{ PnlCreEnums->SizePnlCreator_USERDEFINED } = UserDefinedSize->new();
	$self->{"creators"}->{ PnlCreEnums->SizePnlCreator_HEGORDER }    = HEGOrderSize->new();

	# EVENTS

	$self->{"pnlCreatorInitedEvt"}   = Event->new();
	$self->{"pnlCreatorProcesedEvt"} = Event->new();

	return $self;
}

# Raise "pnlCreatorInitedEvt" event, which will contain Creator Model data
sub InitPnlCreator {
	my $self       = shift;
	my $creatorKey = shift;
	my $initParams = shift;    # array ref

	my $taskId     = $creatorKey . "_init";
	my @taskParams = ();
	push( @taskParams, $creatorKey );
	push( @taskParams, $initParams );

	$self->{"backgroundWorker"}->AddNewtask( $taskId, \@taskParams );

}

# Raise "pnlCreatorProcesedEvt" event, which will contain result succes/failed
sub ProcessPnlCreator {
	my $self             = shift;
	my $creatorKey       = shift;
	my $creatorModelData = shift;

	my $JSONSett = $self->__ModelData2CreatorSettings($creatorModelData);

	my $taskId     = $creatorKey . "_process";
	my @taskParams = ();
	push( @taskParams, $creatorKey );
	push( @taskParams, $JSONSett );

	$self->{"backgroundWorker"}->AddNewtask( $taskId, \@taskParams );

}

#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#

sub __TaskBackgroundFunc{
	my $taskId            = shift;
	my $taskParams        = shift;
	my $inCAM             = shift;
	my $thrPogressInfoEvt = shift;
	my $thrMessageInfoEvt = shift;
	
	 
	
}


sub __ModelData2CreatorSettings {
	my $self      = shift;
	my $modelData = shift;

	my $creatorKey = $modelData->GetModelKey();

	die "Creator was not defined  for key: $creatorKey" unless ( defined $self->{"creators"}->{$creatorKey} );

	# Get creator object
	my $creator = dclone( $self->{"creators"}->{$creatorKey} );

	# CHeck if model data and creatod settings has same "keys"

	$creator->{"settings"} = $modelData->{"data"};

	my $JSONSett = $creator->ExportSett();

	return $JSONSett;
}

sub __CreatorSettings2ModelData {
	my $self      = shift;
	my $modelData = shift;
	my $JSONSett  = shift;

	my $creatorKey = $modelData->GetModelKey();

	die "Creator was not defined  for key: $creatorKey" unless ( defined $self->{"creators"}->{$creatorKey} );

	# Get creator object
	my $creator = dclone( $self->{"creators"}->{$creatorKey} );

	# CHeck if model data and creatod settings has same "keys"

	$creator->ImportSett($JSONSett);

	$modelData->{"data"} = $creator->{"settings"};

	return $modelData;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
