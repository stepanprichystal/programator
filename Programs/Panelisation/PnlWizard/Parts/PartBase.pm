
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
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';

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

	$self->{"checkClass"} = undef;

	$self->{"form"}        = undef;    #form which represent GUI of this group
	$self->{"partWrapper"} = undef;    #$self->{"eventClass"}   = undef;    # define connection between all groups by group and envents handler

	$self->{"processErrMess"} = undef;

	# Events
	$self->{"creatorReInitdEvt"}          = Event->new();
	$self->{"creatorSelectionChangedEvt"} = Event->new();
	$self->{"creatorSettingsChangedEvt"}  = Event->new();

	$self->{"modelChangedEvt"}     = Event->new();
	$self->{"previewChangedEvt"}   = Event->new();
	$self->{"asyncCreatorProcessedEvt"} = Event->new();
	$self->{"asyncCreatorInitedEvt"} = Event->new();

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

	$partWrapper->{"previewChangedEvt"}->Add( sub { $self->__OnPreviewChangedHndl(@_) } );
	$partWrapper->{"errIndClickEvent"}->Add( sub  { $self->__OnErrIndClickHndl(@_) } );

	$self->{"form"}->{"creatorSettingsChangedEvt"}->Add( sub { $self->__OnCreatorSettingsChangedHndl() } );

}

sub __OnCreatorInitedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $modelData  = shift;

	$self->{"partWrapper"}->ShowLoading(0);

	# Call sub class method if implemented
	if ( $self->can("OnCreatorInitedHndl") ) {
		$self->OnCreatorInitedHndl( $creatorKey, $result, $modelData );
	}
	
	$self->{"asyncCreatorInitedEvt"}->Do( $creatorKey, $result );

}

sub __OnCreatorProcessedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	$self->{"partWrapper"}->ShowLoading(0);

	$self->{"processErrMess"} = undef;

	unless ($result) {

		$self->{"processErrMess"} = $errMess;
	}

	# add error to wraper
	$self->{"partWrapper"}->SetErrIndicator( ( defined $self->{"processErrMess"} ? 1 : 0 ) );

	# Call sub class method if implemented
	if ( $self->can("OnCreatorProcessedHndl") ) {
		$self->OnCreatorProcessedHndl( $creatorKey, $result, $errMess );
	}

	$self->{"asyncCreatorProcessedEvt"}->Do( $creatorKey, $result, $errMess );

}

sub __OnPreviewChangedHndl {
	my $self = shift;
	my $val  = shift;

	unless ($val) {

		$self->__ClearErrors();
	}

	$self->{"model"}->SetPreview($val);

	$self->{"previewChangedEvt"}->Do( $self->GetPartId(), $val )

}

sub __OnErrIndClickHndl {
	my $self = shift;

	if ( defined $self->{"processErrMess"} ) {

		my $messMngr = $self->{"partWrapper"}->GetMessMngr();
		my @mess     = ();
		push( @mess, "==========================================" );
		push( @mess, " <b>Part: " . EnumsStyle->GetPartTitle( $self->GetPartId() ) . " - error during processing</b>" );
		push( @mess, "==========================================\n" );
		push( @mess, $self->{"processErrMess"} );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
	}

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

sub AsyncProcessPart {
	my $self = shift;

	#my $ignorePreview = shift // 0;

	#if ( $self->GetPreview() || $ignorePreview ) {

	$self->__ClearErrors();

	$self->{"partWrapper"}->ShowLoading(1);

	$self->{"model"}->SetCreators( $self->{"form"}->GetCreators() );
	$self->{"model"}->SetSelectedCreator( $self->{"form"}->GetSelectedCreator() );

	# Process by selected creator

	my $creatorKey   = $self->{"model"}->GetSelectedCreator();
	my $creatorModel = $self->{"model"}->GetCreatorByKey($creatorKey);

	$self->{"backgroundTaskMngr"}->AsyncProcessPnlCreator( $creatorKey, $creatorModel->ExportCreatorSettings() );

	#}

}

sub AsyncInitPart {
	my $self                = shift;
	my $creatorKey          = shift;
	my $creatorInitPatarams = shift // [];

	$self->__ClearErrors();

	$self->{"isPartFullyInited"} = 0;

	$self->{"partWrapper"}->ShowLoading(1);

	$self->{"backgroundTaskMngr"}->AsyncInitPnlCreator( $creatorKey, $creatorInitPatarams );

}

sub RefreshGUI {
	my $self = shift;

	$self->{"frmHandlersOff"} = 1;

	#my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetCreators( $self->{"model"}->GetCreators() );
	$self->{"form"}->SetSelectedCreator( $self->{"model"}->GetSelectedCreator() );

	$self->{"frmHandlersOff"} = 0;

}

sub IsPartFullyInited {
	my $self = shift;

	$self->{"isPartFullyInited"};
}

#
## Update groupd data with values from GUI
#sub UpdateGroupData {
#	my $self = shift;
#
#	my $frm = $self->{"form"};
#
#	#if form is init/showed to user, return group data edited by form
#	#else return default group data, not processed by form
#
#	if ($frm) {
#		my $groupData = $self->{"dataMngr"}->GetGroupData();
#
#		$groupData->SetExportMeasurePdf( $frm->GetExportMeasurePdf() );
#		$groupData->SetBuildMLStackup( $frm->GetBuildMLStackup() );
#
#	}
#
#}

#sub __RefreshGUICreator {
#	my $self = shift;
#	my $creatorKey = shift;
#
#
#
#
#}

#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#

sub OnCreatorInitedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $JSONSett   = shift;

	# Update Model data

	$self->{"model"}->GetCreatorByKey($creatorKey)->ImportCreatorSettings($JSONSett);

	# Refresh gui
	print STDERR "\n\nRefreshGUI\n\n";

	$self->{"frmHandlersOff"} = 1;

	$self->{"form"}->SetCreators( [ $self->{"model"}->GetCreatorByKey($creatorKey) ] );
	$self->{"frmHandlersOff"} = 0;

	$self->{"isPartFullyInited"} = 1;

	return 1;

}

sub OnCreatorProcessedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	return 1;

}

sub __OnCreatorSelectionChangedHndl {
	my $self       = shift;
	my $creatorKey = shift;

	return 0 if ( $self->{"frmHandlersOff"} );

	# Init creator
	$self->AsyncInitPart($creatorKey);

	# Reise evevents for other parts
	$self->{"creatorSelectionChangedEvt"}->Do($creatorKey);

}

sub SetPreview {
	my $self = shift;
	my $val  = shift;

	unless ($val) {
		$self->__ClearErrors();
	}

	$self->{"model"}->SetPreview($val);
	$self->{"partWrapper"}->SetPreview($val);

}

sub GetPreview {
	my $self = shift;

	return $self->{"model"}->GetPreview();
}

sub __ClearErrors {
	my $self = shift;

	$self->{"processErrMess"} = undef;
	$self->{"partWrapper"}->SetErrIndicator(0);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
