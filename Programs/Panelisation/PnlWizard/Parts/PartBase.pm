
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
	$self->{"model"}  = undef;
	
	$self->{"checkClass"}  = undef;
	

	$self->{"form"}        = undef;    #form which represent GUI of this group
	$self->{"partWrapper"} = undef;    #$self->{"eventClass"}   = undef;    # define connection between all groups by group and envents handler

	# Events
	$self->{"creatorReInitdEvt"}          = Event->new();
	$self->{"creatorSelectionChangedEvt"} = Event->new();
	$self->{"creatorSettingsChangedEvt"}  = Event->new();

	$self->{"modelChangedEvt"}   = Event->new();
	$self->{"previewChangedEvt"} = Event->new();

	# Se handlers

	$self->{"backgroundTaskMngr"}->{"pnlCreatorInitedEvt"}->Add( sub   { $self->__OnCreatorInitedHndl(@_) } );
	$self->{"backgroundTaskMngr"}->{"pnlCreatorProcesedEvt"}->Add( sub { $self->__OnCreatorProcessedHndl(@_) } );

	return $self;
}

sub GetPartId {
	my $self = shift;

	return $self->{"partId"};

}

sub GetModel {
	my $self = shift;

	return $self->{"model"};

}
 
 
sub GetCheckClass {
	my $self = shift;

	return $self->{"checkClass"};

} 
 
 

sub _InitForm {
	my $self        = shift;
	my $partWrapper = shift;

	$self->{"partWrapper"} = $partWrapper;

	$partWrapper->{"previewChangedEvt"}->Add( sub { $self->__OnPreviewChanged(@_) } );

	$self->{"form"}->{"creatorSettingsChangedEvt"}->Add( sub { $self->__OnCreatorSettingsChangedHndl() } );

}

sub __OnCreatorInitedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $modelData  = shift;

	# Call sub class method if implemented
	if ( $self->can("OnCreatorInitedHndl") ) {
		$self->OnCreatorInitedHndl( $creatorKey, $result, $modelData );
	}

}

sub __OnCreatorProcessedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	# Call sub class method if implemented
	if ( $self->can("OnCreatorProcessedHndl") ) {
		$self->OnCreatorProcessedHndl( $creatorKey, $result, $errMess );
	}

}

sub __OnPreviewChanged {
	my $self = shift;
	my $val  = shift;

	$self->{"model"}->SetPreview($val);

	$self->{"previewChangedEvt"}->Do( $self->GetPartId(), $val )

}

sub __OnCreatorSettingsChangedHndl {
	my $self = shift;

	# Do async process if previeww set

	$self->AsyncProcessPart() if ( $self->GetPreview() );

	# Reise Events
	$self->{"creatorSettingsChangedEvt"}->Do(@_);

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

sub SetPreview {
	my $self = shift;
	my $val  = shift;

	$self->{"model"}->SetPreview($val);
	$self->{"partWrapper"}->SetPreview($val);

}

sub GetPreview {
	my $self = shift;

	return $self->{"model"}->GetPreview();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
