
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::Guides::Guide;

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;
use Switch;

#local library
use aliased 'Programs::CamGuide::Enums';
use aliased 'Programs::CamGuide::Helper';
use aliased 'Programs::CamGuide::GuideHelper';
use aliased 'Programs::CamGuide::Forms::GuideFrm';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::CamGuide::GuideSelector';
use aliased 'Packages::Events::Event';

#use aliased 'Programs::CamGuide::Actions::MillingActions';
#se Programs::CamGuide::Actions::Milling;
#use Programs::CamGuide::Actions::Pause;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	#incam library
	$self->{'guideId'} = shift;
	my $pcbId = shift;
	$self->{'inCAM'}      = shift;
	$self->{'messMngr'}   = shift;
	$self->{'childPcbId'} = shift;

	unless ( $self->{'childPcbId'} ) {
		$self->{'childPcbId'} = 1;
	}

	my @actionsQueue = ();

	#intitialize queue od actions
	$self->{'actionQueue'} = \@actionsQueue;
	$self->{'actualStep'}  = undef;

	#PROPERTIES=========================

	#dps processing info like number of layer etc
	$self->{"helper"} = GuideHelper->new( $pcbId, $self->{'guideId'}, $self->{'actionQueue'}, $self->{'messMngr'}, $self->{'childPcbId'} );

	my %pcbInfo = ();
	$pcbInfo{"pcbId"}      = $pcbId;
	$pcbInfo{"childPcbId"} = $self->{'childPcbId'};
	$self->{'pcbInfo'}     = \%pcbInfo;

	#managing message windows
	$self->{'pauseMess'} = undef;

	#managing message windows
	$self->{'canContinue'} = 1;

	#array of guide errors
	$self->{'errors'} = ();

	#array of guide warrnings
	$self->{'warnings'} = ();

	#EVENTS=========================

	#event, when some action happen
	$self->{'onAction'} = Event->new();

	#event, when some action happen
	$self->{'onActionErr'} = Event->new();

	#event, when some guide type is changed
	$self->{'onGuideChanged'} = Event->new();

	#set message manager
	if ( $self->{'messMngr'} ) {
		$self->{'messMngr'}->SetPcbIds( $pcbId, $self->{'childPcbId'} );
	}

	#set InCAM library
	$self->__SetInCAM();

	return $self;    # Return the reference to the hash.

}

sub __SetInCAM {
	my $self = shift;

	$self->{'inCAM'}->VOF();                 #off InCAM gui error message
	$self->{'inCAM'}->HandleException(0);    #Library raise InCAMException when some error occrus;

}

sub Run {
	my $self = shift;

	$self->__InitQueue(0);
	$self->__RunQueue();
}

sub RunFromAction {
	my $self       = shift;
	my $fromAction = shift;

	#my $parent = shift;

	my $helper = $self->{"helper"};

	#$helper->Synchronize();

	my $unvisited = $helper->ExistsUnvisited($fromAction);

	#my $visited   = $helper->ExistsVisited($fromAction);

	my $continue = $helper->CanContinue($fromAction);

	if ( !$continue ) {

		$helper->ShowForm( $fromAction, sub { $self->__OnRunAllClick(@_) }, sub { $self->__OnRunSingleClick(@_) } );

		return;
	}

	#if ($visited) {

	$helper->DeleteOldAction($fromAction);

	#}

	$self->__InitQueue($fromAction);
	$self->__RunQueue();

}

sub Show {
	my $self = shift;

	my $fromAction = -1;
	my $helper     = $self->{"helper"};

	#$helper->Synchronize();
	#$fromAction = $helper->GetLastActionId() + 1;

	$self->__InitQueue($fromAction);
	$helper->ShowForm( $fromAction, sub { $self->__OnRunAllClick(@_) }, sub { $self->__OnRunSingleClick(@_) }, sub { $self->__OnGuidChanged(@_) } );

}

sub __OnRunAllClick {
	my $self       = shift;
	my $guideFrm   = shift;
	my $itemType   = shift;
	my $itemId     = shift;
	my $guidFrmObj = shift;
	my $helper     = $self->{"helper"};

	$guideFrm->Hide();
	$guideFrm->Destroy();

	#$guidFrmObj->ExitMainLoop();
	#print "ExitMainloop";

	#$guideFrm->

	my $runFrom = -1;

	if ( $itemType eq Enums->GUIDEITEM_ACTION ) {

		$runFrom = $itemId;

	}
	elsif ( $itemType eq Enums->GUIDEITEM_STEP ) {
		{

			$runFrom = $helper->GetActionIdByStepId($itemId);
		}
	}

	$self->RunFromAction($runFrom);

	print "__OnRunAllClick ItemType:" . $itemType . " - ItemId: " . $runFrom . "\n";

}

sub __OnRunSingleClick {
	my $self     = shift;
	my $guideFrm = shift;
	my $itemId   = shift;

	$guideFrm->Hide();
	#$guideFrm->Destroy();

	$self->__RunSingle($itemId);

	print "__OnRunSingleClick ItemId: " . $itemId . "\n";
	$guideFrm->Show();
}

sub __OnGuidChanged {
	my $self     = shift;
	my $guideFrm = shift;
	my $guidId   = shift;

	$guideFrm->Hide();
	$guideFrm->Close();

	my $onGuideChanged = $self->{'onGuideChanged'};

	if ( defined $onGuideChanged ) {
		$onGuideChanged->Do($guidId);
	}

	#my $guideSelector = GuideSelector->new();

	#my $guid = $guideSelector->Get($guidId,$self->{'guideId'}, $self->{'inCAM'},$self->{'messMngr'});

}

#nastavi VISITED, UNVISITED podle poyadavku pripravare
	my $self       = shift;
sub __InitQueue {
	my $self = shift;
	my $fromAction = shift;

	my @actionsQueue = @{ $self->{actionQueue} };
	my $actionRef    = undef;

	for ( my $i = 0 ; $i < scalar(@actionsQueue) ; $i++ ) {

		$actionRef = $actionsQueue[$i];

		if ( $i >= $fromAction ) {
			$actionRef->{"status"} = Enums->ActStatus_UNVISITED;

		}
		else {

			$actionRef->{"status"} = Enums->ActStatus_VISITED;
		}
	}
}

sub __RunQueue {
	my $self = shift;

	my $actQueue = $self->{'actionQueue'};
	my $runSame  = 0;

	for ( my $i = 0 ; $i < scalar( @{$actQueue} ) ; $i++ ) {

		$runSame = 0;
		my $refAction = @{$actQueue}[$i];

		if ( $refAction->{"status"} ne Enums->ActStatus_UNVISITED ) {
			next;
		}

		$self->__ProcessAction( $refAction, \$runSame );

		#test if run same action again
		if ($runSame) {
			$i--;
		}

		sleep(1);

	}
}

sub __RunSingle {
	my $self     = shift;
	my $actionId = shift;

	my $actQueue  = $self->{'actionQueue'};
	my $refAction = @{$actQueue}[$actionId];

	$self->__ProcessAction($refAction);
}

sub __ProcessAction {

	my $self        = shift;
	my $refAction   = shift;
	my $runSame     = shift;
	my %pcbInfo     = %{ $self->{'pcbInfo'} };
	my $pcbId       = $pcbInfo{"pcbId"};
	my $childPcbId  = $pcbInfo{"childPcbId"};
	my $onActionErr = undef;
	my $onAction    = undef;

	try {

		#set default values
		$self->{'pauseMess'}   = undef;
		$self->{'canContinue'} = undef;

		#Run action
		$refAction->{"action"}->($self);

		#Behavour after action was run
		if ( $refAction->{"actionType"} eq Enums->ActionType_DO ) {

			unless ( defined $self->{'canContinue'} ) {
				$self->{'canContinue'} = 1;
			}

			if ( $self->{'canContinue'} ) {
				$refAction->{"status"} = Enums->ActStatus_VISITED;
			}
			else {
				$refAction->{"status"} = Enums->ActStatus_VISITED;

				$self->__CheckPauseMess( $refAction->{"actionCode"} );
				$self->InCAMPause();
			}
		}
		elsif ( $refAction->{"actionType"} eq Enums->ActionType_CHECK ) {

			$self->__CheckCanContinue( $refAction->{"actionCode"} );

			if ( $self->{'canContinue'} ) {
				$refAction->{"status"} = Enums->ActStatus_VISITED;
			}
			else {
				$$runSame = 1;                                         #next in for cycle, run again this action
				$refAction->{"status"} = Enums->ActStatus_UNVISITED;

				$self->__CheckPauseMess( $refAction->{"actionCode"} );
				$self->InCAMPause();
			}
		}
		elsif ( $refAction->{"actionType"} eq Enums->ActionType_DOANDSTOP ) {

			$refAction->{"status"} = Enums->ActStatus_VISITED;

			unless ( defined $self->{'pauseMess'} ) {
				$self->{'pauseMess'} = "Guide script pause..";
			}
			$self->InCAMPause();

		}
		elsif ( $refAction->{"actionType"} eq Enums->ActionType_PAUSE ) {

			$refAction->{"status"} = Enums->ActStatus_VISITED;

			$self->__CheckPauseMess( $refAction->{"actionCode"} );
			$self->InCAMPause();
		}

	}
	catch {
		my $e = $_;
		my $mess;

		$onActionErr = $self->{'onActionErr'};
		if ( defined $onActionErr ) {

			my $errorType = undef;

			if ( ref($e) && $e->isa("Packages::Exceptions::InCamException") ) {
				$errorType = "InCAM";
			}
			elsif ( ref($e) && $e->isa("Packages::Exceptions::HeliosException") ) {
				$errorType = "Helios";
			}
			else {
				$errorType = "Scripting";
			}

			$onActionErr->Do( $self->{'messMngr'}, $pcbId, $refAction->{"actionStep"}, $refAction->{"actionName"}, $e, $errorType );

		}
		else {
			die "Handler \"onActionErr\" in Guide.pm is not set.\nError: ".$e;
		}

	};

	$onAction = $self->{'onAction'};
	if ( defined $onAction ) {

		$onAction->Do( $pcbId, $childPcbId, $refAction->{"actionStep"}, $refAction->{"actionCode"}, $refAction->{"actionOrder"} );
	}

}

sub __CheckCanContinue {
	my $self   = shift;
	my $action = shift;

	unless ( defined $self->{'canContinue'} ) {
		die printf STDERR ( Enums->ERR_SETCANCONTINUE, $action );
	}
}

sub __CheckPauseMess {
	my $self   = shift;
	my $action = shift;

	unless ( defined $self->{'pauseMess'} ) {
		die printf STDERR ( Enums->ERR_SETPAUSEMESS, $action );
	}
}

sub InCAMPause {
	my $self  = shift;
	my $inCAM = $self->{'inCAM'};

	unless ( defined $inCAM ) {

		my $mngr = $self->{'messMngr'};

		my @mess1 = ( "THIS IS PAUSE WINDWO FROM INCOME: " . $self->{'pauseMess'} );

		$mngr->Show( -1, EnumsGeneral->MessageType_INFORMATION, \@mess1 );

	}
	else {

		exit unless ( CamHelper->Pause( $inCAM, $self->{'pauseMess'} ) );

	}

}

#GET Guide properties

sub GetCAM {
	my $self = shift;
	return $self->{'inCAM'};
}

sub GetMessMngr {
	my $self = shift;
	return $self->{'messMngr'};
}

sub GetPcbInfo {
	my $self = shift;
	return %{ $self->{'pcbInfo'} };
}

sub GetStepO {
	my $self = shift;

	my $stepO = Enums->ActualStep_STEPO;

	if ( $self->{'childPcbId'} > 1 ) {

		$stepO .= "_pcb" . $self->{'childPcbId'};
	}

	return $stepO;
}

sub GetStepO1 {
	my $self = shift;

	my $stepO1 = Enums->ActualStep_STEPOPLUS1;

	if ( $self->{'childPcbId'} > 1 ) {

		$stepO1 .= "_pcb" . $self->{'childPcbId'};
	}

	return $stepO1;
}

sub SetPauseMess {
	my $self      = shift;
	my $pauseMess = shift;

	$self->{'pauseMess'} = $pauseMess;
}

sub SetCanContinue {
	my $self   = shift;
	my $status = shift;

	$self->{'canContinue'} = $status;
}

sub AddError {
	my $self  = shift;
	my $error = shift;

	push( $self->{'errors'}, $error );
}

sub AddWarning {
	my $self    = shift;
	my $warning = shift;

	push( $self->{'warnings'}, $warning );
}

sub AddOnAction {
	my $self     = shift;
	my $onAction = shift;

	if ( defined $onAction ) {

		$self->{'onAction'}->Add($onAction);
	}
}

sub AddOnActionErr {
	my $self        = shift;
	my $onActionErr = shift;

	if ( defined $onActionErr ) {

		$self->{'onActionErr'}->Add($onActionErr);

		#$self->{'onActionErr'} = $onActionErr;
	}
}

sub AddOnGuideChanged {
	my $self           = shift;
	my $onGuideChanged = shift;

	if ( defined $onGuideChanged ) {

		$self->{'onGuideChanged'}->Add($onGuideChanged);
	}
}

sub __CheckAtt {
	my $self       = shift;
	my $action     = shift;
	my $actionCode = shift;

	my $ns         = Helper->NameOfActionPackage($action);
	my $actionName = $actionCode;
	$actionName =~ s/(\S)*\:\://;

	my $actName = eval '$' . $ns . "n{" . $actionName . "}";
	my $actDesc = eval '$' . $ns . "d{" . $actionName . "}";

	unless ( defined $actName ) {
		die printf STDERR ( Enums->ERR_ACTIONNAME, $actionName );
	}

	unless ( defined $actDesc ) {
		die printf STDERR ( Enums->ERR_ACTIONDESC, $actionName );
	}
}

sub _AddAction {
	my $self       = shift;
	my $action     = shift;
	my $actionType = shift;
	my $actionCode = Helper->CodeNameOfAction($action);
	my %info;

	$self->__CheckAtt( $action, $actionCode );

	my $ns         = Helper->NameOfActionPackage($action);
	my $actionName = $actionCode;
	$actionName =~ s/(\S)*\:\://;

	$info{"actionName"}  = eval '$' . $ns . "n{" . $actionName . "}";
	$info{"actionDesc"}  = eval '$' . $ns . "d{" . $actionName . "}";
	$info{"action"}      = $action;
	$info{"actionType"}  = $actionType;
	$info{"actionCode"}  = $actionCode;
	$info{"actionStep"}  = $self->{'actualStep'};
	$info{"actionOrder"} = scalar( @{ $self->{'actionQueue'} } );
	$info{"status"}      = Enums->ActStatus_UNVISITED;
	$info{"inserted"}    = "";
	$info{"user"}        = "";

	#insert action to queue
	push( @{ $self->{'actionQueue'} }, \%info );
}

sub _SetStep {
	my $self       = shift;
	my $actualStep = shift;

	unless ( defined $actualStep ) {
		return 0;
	}

	$self->{'actualStep'} = $actualStep;

}

# my $cv = svref_2object ( $sub_ref );
#my $gv = $cv->GV;

#return $gv->NAME;

1;
