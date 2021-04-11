
#-------------------------------------------------------------------------------------------#
# Description: Base class for part controls
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::PartBase;

#3th party library
use strict;
use warnings;

#local library
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

	$self->{"partId"}             = shift;    # unique part id
	$self->{"inCAM"}              = shift;
	$self->{"jobId"}              = shift;
	$self->{"pnlType"}            = shift;    # customer / production panel
	$self->{"backgroundTaskMngr"} = shift;

	# PROPERTIES

	$self->{"model"}      = undef;            # data model for specific part. Set by subclass
	$self->{"checkClass"} = undef;            # Checking model before panelisation. Set by subclass

	$self->{"form"}        = undef;           # View form for part
	$self->{"partWrapper"} = undef;           # Wrapper form reference where form is incluced in

	# Helper properties
	$self->{"processErrMess"}    = undef;     # Array referencem where text errors during init/process part are stored
	$self->{"frmHandlersOff"}    = 0;         # state indicator if handler shoud be processed
	$self->{"isPartFullyInited"} = 0;         # state indicator if part is fully loaded (assync loading)
	$self->{"creatorInited"}     = {};        # Indicator for each creator if was asynchrounouslz inited

	# EVENTS
	$self->{"creatorSelectionChangedEvt"} = Event->new();
	$self->{"creatorSettingsChangedEvt"}  = Event->new();
	$self->{"previewChangedEvt"}          = Event->new();
	$self->{"asyncCreatorProcessedEvt"}   = Event->new();
	$self->{"asyncCreatorInitedEvt"}      = Event->new();
	$self->{"showPnlWizardFrmEvt"}        = Event->new();

	# Set handlers

	$self->{"backgroundTaskMngr"}->{"pnlCreatorInitedEvt"}->Add( sub   { $self->__OnCreatorInitedHndl(@_) } );
	$self->{"backgroundTaskMngr"}->{"pnlCreatorProcesedEvt"}->Add( sub { $self->__OnCreatorProcessedHndl(@_) } );

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Interface method
#-------------------------------------------------------------------------------------------#

# Return updated model by values from View
sub GetModel {
	my $self = shift;
	my $notUpdate = shift // 0;

	return $self->{"model"} if ($notUpdate);

	# Update model by form values
	$self->{"model"}->SetCreators( $self->{"form"}->GetCreators() );
	$self->{"model"}->SetSelectedCreator( $self->{"form"}->GetSelectedCreator() );
	$self->{"model"}->SetPreview( $self->{"partWrapper"}->GetPreview() );
	return $self->{"model"};

}

# Set values from model to View
sub RefreshGUI {
	my $self = shift;

	$self->{"frmHandlersOff"} = 1;
	$self->{"form"}->SetCreators( $self->{"model"}->GetCreators() );
	$self->{"form"}->SetSelectedCreator( $self->{"model"}->GetSelectedCreator() );
	$self->{"partWrapper"}->SetPreview( $self->{"model"}->GetPreview() );

	$self->{"frmHandlersOff"} = 0;
}

# Asynchronously process selected creator for this part
sub AsyncProcessSelCreatorModel {
	my $self = shift;
	my $callReason = shift // "";    # reason, why method is called (after creator setting changed)

	# Process by selected creator

	my $creatorKey = $self->{"model"}->GetSelectedCreator();
	$self->__AsyncProcessCreatorModel( $creatorKey, $callReason );

}

# Asynchronously initialize selected creator for this part
sub AsyncInitSelCreatorModel {
	my $self = shift;

	my $creatorKey = $self->{"model"}->GetSelectedCreator();

	$self->__AsyncInitCreatorModel($creatorKey);
}

# Set directly preview option
sub SetPreview {
	my $self = shift;
	my $val  = shift;

	unless ($val) {
		$self->ClearErrors();
	}

	$self->{"model"}->SetPreview($val);
	$self->{"partWrapper"}->SetPreview($val);

}

# Get previre option
sub GetPreview {
	my $self = shift;

	return $self->{"model"}->GetPreview();
}

# If all asynchronous init calling are done, return 1
sub IsPartFullyInited {
	my $self = shift;

	$self->{"isPartFullyInited"};
}

#-------------------------------------------------------------------------------------------#
#  Other public  method
#-------------------------------------------------------------------------------------------#

# Return unique parrt Id
sub GetPartId {
	my $self = shift;

	return $self->{"partId"};
}

# Update step if changed in main form
sub UpdateStep {
	my $self = shift;
	my $step = shift;

	$self->{"form"}->UpdateStep($step);

}

# Clear current errros for part
sub ClearErrors {
	my $self = shift;

	$self->{"processErrMess"} = undef;
	$self->{"partWrapper"}->SetErrIndicator(0);
}

# Return class for asynchronous checking
sub GetCheckClass {
	my $self = shift;

	return $self->{"checkClass"};

}

#-------------------------------------------------------------------------------------------#
#  Private/protected helper  method
#-------------------------------------------------------------------------------------------#

sub _InitForm {
	my $self        = shift;
	my $partWrapper = shift;

	$self->{"partWrapper"} = $partWrapper;

	$partWrapper->{"previewChangedEvt"}->Add( sub { $self->__OnPreviewChangedHndl(@_) } );
	$partWrapper->{"errIndClickEvent"}->Add( sub  { $self->__OnErrIndClickHndl(@_) } );

	$self->{"form"}->{"creatorSettingsChangedEvt"}->Add( sub  { $self->__OnCreatorSettingsChangedHndl(@_) } );
	$self->{"form"}->{"creatorSelectionChangedEvt"}->Add( sub { $self->__OnCreatorSelectionChangedHndl(@_) } );

	#$self->{"form"}->{"creatorInitRequestEvt"}->Add( sub { $self->__AsyncInitCreatorModel(@_) } );

}

# Do init specific creator asynchronously
sub __AsyncInitCreatorModel {
	my $self       = shift;
	my $creatorKey = shift;

	my $creatorInitPatarams = [ $self->{"model"}->GetCreatorModelByKey($creatorKey)->GetStep() ];

	$self->ClearErrors();

	$self->{"isPartFullyInited"} = 0;

	$self->{"partWrapper"}->ShowLoading(1);

	$self->{"backgroundTaskMngr"}->AsyncInitPnlCreator( $self->{"partId"}, $creatorKey, $creatorInitPatarams );

}

# Do process specific creator asynchronously
sub __AsyncProcessCreatorModel {
	my $self       = shift;
	my $creatorKey = shift;
	my $callReason = shift;

	$self->ClearErrors();

	$self->{"partWrapper"}->ShowLoading(1);

	my $creatorModel = $self->{"model"}->GetCreatorModelByKey($creatorKey);

	$self->{"backgroundTaskMngr"}->AsyncProcessPnlCreator( $self->{"partId"}, $creatorKey, $creatorModel->ExportCreatorSettings(), $callReason );

}

#-------------------------------------------------------------------------------------------#
#  Background worker handlers
#-------------------------------------------------------------------------------------------#

# Handler which catch result of asynchronous init calling
sub __OnCreatorInitedHndl {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $JSONSett   = shift;

	return 0 if ( $partId ne $self->{"partId"} );    # Catch only event from for this specific part

	$self->{"creatorInited"}->{$creatorKey} = 1;

	$self->{"isPartFullyInited"} = 0;

	$self->{"partWrapper"}->ShowLoading(0);

	$self->{"model"}->GetCreatorModelByKey($creatorKey)->ImportCreatorSettings($JSONSett);

	$self->{"frmHandlersOff"} = 1;
	$self->{"form"}->SetCreators( $self->{"model"}->GetCreators() );
	$self->{"frmHandlersOff"} = 0;

	$self->{"isPartFullyInited"} = 1;

	$self->{"asyncCreatorInitedEvt"}->Do( $creatorKey, $result );
	$self->{"creatorSettingsChangedEvt"}->Do( $partId, $creatorKey, $self->{"model"}->GetCreatorModelByKey($creatorKey) );

	# Process part after async init if preview
	if ( $self->GetPreview() ) {

		$self->AsyncProcessSelCreatorModel("settingsChanged");
	}

}

# Handler which catch result of asynchronous process calling
sub __OnCreatorProcessedHndl {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;
	my $callReason = shift;

	return 0 if ( $partId ne $self->{"partId"} );    # Catch only event from for this specific part

	$self->{"partWrapper"}->ShowLoading(0);

	$self->{"processErrMess"} = undef;

	unless ($result) {

		$self->{"processErrMess"} = $errMess;
	}

	# add error to wraper
	$self->{"partWrapper"}->SetErrIndicator( ( defined $self->{"processErrMess"} ? 1 : 0 ) );
	$self->{"asyncCreatorProcessedEvt"}->Do( $creatorKey, $result, $errMess );

	if ( defined $callReason && $callReason eq "settingsChanged" ) {
		my $creatorModel = $self->{"model"}->GetCreatorModelByKey($creatorKey);
		$self->{"creatorSettingsChangedEvt"}->Do( $partId, $creatorKey, $creatorModel );
	}

}

#-------------------------------------------------------------------------------------------#
#  View handlers
#-------------------------------------------------------------------------------------------#

sub __OnPreviewChangedHndl {
	my $self = shift;
	my $val  = shift;

	unless ($val) {

		$self->ClearErrors();
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
	my $self       = shift;
	my $creatorKey = shift;

	return 0 if ( $self->{"frmHandlersOff"} );

	my $creatorModel = $self->{"form"}->GetCreators($creatorKey)->[0];

	# Do async process if previeww set

	if ( $self->GetPreview() ) {
		$self->AsyncProcessSelCreatorModel("settingsChanged");

		# creatorSettingsChangedEvt will be raised after AsyncProcessSelCreatorModel

	}
	else {
		# Reise Events
		$self->{"creatorSettingsChangedEvt"}->Do( $self->GetPartId(), $creatorKey, $creatorModel );
	}

}

sub __OnCreatorSelectionChangedHndl {
	my $self       = shift;
	my $creatorKey = shift;

	return 0 if ( $self->{"frmHandlersOff"} );

	# Change model
	$self->{"model"}->SetSelectedCreator($creatorKey);

	# Init creator
	if ( $self->{"creatorInited"}->{$creatorKey} ) {

		# Process part after async init if preview
		if ( $self->GetPreview() ) {

			$self->AsyncProcessSelCreatorModel();
		}

	}
	else {
		$self->__AsyncInitCreatorModel($creatorKey);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
