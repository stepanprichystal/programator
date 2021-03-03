
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
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"}              = shift;
	$self->{"backgroundTaskMngr"} = shift;

	$self->{"partId"} = undef;

	$self->{"partWrapper"} = undef;    #wrapper, which form is placed in
	$self->{"form"}        = undef;    #form which represent GUI of this group
	                                   #$self->{"eventClass"}   = undef;    # define connection between all groups by group and envents handler

	$self->{"dataMngr"}    = undef;    # manager, which is responsible for create, update group data
	$self->{"cellWidth"}   = 0;        #width of cell/unit form (%), placed in exporter table row
	$self->{"exportOrder"} = 0;        #Order, which unit will be ecported

	# Events
	$self->{"creatorReInitdEvt"}         = Event->new();
	$self->{"creatorChangedEvt"}         = Event->new();
	$self->{"creatorSettingsChangedEvt"} = Event->new();
	$self->{"creatorSettingsChangedEvt"} = Event->new();

	$self->{"modelChangedEvt"}       = Event->new();
	$self->{"showPreviewChangedEvt"} = Event->new();

	# Se handlers

	$self->{"backgroundTaskMngr"}->{"pnlCreatorInitedEvt"}->Add( sub   { $self->__OnCreatorInitedHndl(@_) } );
	$self->{"backgroundTaskMngr"}->{"pnlCreatorProcesedEvt"}->Add( sub { $self->__OnCreatorProcessedHndl(@_) } );

	return $self;
}

sub GetPartId {
	my $self = shift;

	return $self->{"partId"};

}

sub __OnCreatorInitedHndl {
	my $self = shift;
	my $creatorKey = shift;
	my $result = shift;
	my $modelData = shift;

	# Call sub class method if implemented
	if ( $self->can("OnCreatorInitedHndl") ) {
		$self->OnCreatorInitedHndl($creatorKey, $result, $modelData);
	}

}

sub __OnCreatorProcessedHndl {
	my $self = shift;
	my $creatorKey = shift;
	my $result = shift;
	my $errMess = shift;

	# Call sub class method if implemented
	if ( $self->can("OnCreatorProcessedHndl") ) {
		$self->OnCreatorProcessedHndl($creatorKey, $result, $errMess);
	}

}
 
#sub _ProcessCreatorSettings {
#
#	# 1)Convert model to Creator settings
#
#	# 2)Process creator on background^
#	my $creatorType = "test_creator";
#
#	$self->{"newBackgroundTaskEvt"}->Do( $creatorType, )
#
#}
#
#sub __BackgroundWorker {
#	my $taskId            = shift;
#	my $taskParams        = shift;
#	my $inCAM             = shift;
#	my $thrPogressInfoEvt = shift;
#	my $thrMessageInfoEvt = shift;
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
