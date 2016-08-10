

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::GuideHelper;

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;

#local library
use aliased 'Programs::CamGuide::Enums';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::CamGuide::Forms::GuideFrm';
use aliased 'Connectors::LogConnector::LogMethods';



#use aliased 'Programs::CamGuide::Actions::MillingActions';
#use Programs::CamGuide::Actions::MillingActions;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	#intitialize queue od actions
	$self->{'pcbId'}       = shift;
	$self->{'guideId'} 	= shift;
	$self->{'actionQueue'} = shift;
	$self->{'messMngr'}    = shift;
	$self->{'childPcbId'}  = shift;
	#$self->{"form"}        = GuideForm->new( $self->{'actionQueue'} );

	return $self;        # Return the reference to the hash.
}

#sznchronize queue with log db
sub Synchronize {
	my $self         = shift;
	my @actionsQueue = @{ $self->{actionQueue} };
	my @rows         = LogMethods->GetLatestActionsByPcbId( $self->{'pcbId'}, $self->{'childPcbId'} );
	
	unless(scalar(@rows)){
		return 0;
	}

	my $actionRef = undef;

	for ( my $i = 0 ; $i < scalar(@actionsQueue) ; $i++ ) {

		$actionRef = $actionsQueue[$i];

		my @res = grep {
			     $_->{"ActionStep"} eq $actionRef->{"actionStep"}
			  && $_->{"ActionCode"} eq $actionRef->{"actionCode"}
			  && $_->{"ActionOrder"} eq $actionRef->{"actionOrder"}
		} @rows;

		if ( scalar(@res) > 0 ) {

			$actionRef->{"inserted"} = $res[0]->{"Inserted"};
			$actionRef->{"user"}     = $res[0]->{"User"};
		}
		#else{
		#	#if exist action which doesn't have date, exit synchroniyation
		#	last;
		#}
	}
}



sub CanContinue {
	
	my $self       = shift;
	my $fromAction = shift;
	my $parent = shift;
	
	
	my @btns = ( "Ne, zvolim jinou akci", "Ano, pokracovat" );
	my @mess = ("Všechny předchozí akce ještě nebyly spuštěny.","Přejes si i presto pokracovat?");

	$self->{'messMngr'}->ShowModal( $parent, EnumsGeneral->MessageType_WARNING, \@mess, \@btns );

	if ( $self->{'messMngr'}->Result() == 0 ) {
		return 0;
	}
	else {
		return 1;
	}	
}

#check unvisited action before start point and show form
sub ExistsUnvisited {
	my $self       = shift;
	my $fromAction = shift;

	my @actionsQueue = @{ $self->{actionQueue} };

	my $lastId = $self->GetLastActionId();

	#show warning and  form with unvisited action
	if ( $lastId < $fromAction - 1 ) {

		return 1
	}
	else {

		return 0;

	}
}

sub ExistsVisited {
	my $self       = shift;
	my $fromAction = shift;

	my @actionsQueue = @{ $self->{actionQueue} };

	my $lastId = $self->GetLastActionId();

	#show warning and  form with unvisited action
	if ( $lastId > $fromAction - 1 ) {

		return 1
	}
	else {

		return 0;

	}
 
}

sub DeleteOldAction{
	my $self       = shift;
	my $fromAction = shift;

	my @actionsQueue = @{ $self->{actionQueue} };
	
	my $lastAction = $self->GetLastActionId();
	my $a = undef;	
	
	for ( my $i = $fromAction ; $i < scalar(@actionsQueue) ; $i++ ) {
	
		$a = $actionsQueue[$i];
		LogMethods->DeleteAction( $self->{'pcbId'},
								$self->{'childPcbId'},
								$a->{'actionStep'},
								$a->{'actionCode'},
								$a->{'actionOrder'} );
	}

 
}

sub GetLastActionId {
	my $self = shift;

	my @actionsQueue = @{ $self->{actionQueue} };

	my $lastId    = 0;
	my $actionRef = undef;

	for ( my $i = 0 ; $i < scalar(@actionsQueue) ; $i++ ) {

		$actionRef = $actionsQueue[$i];
		$lastId = $i;
		
		if ( defined $actionRef->{"inserted"} && $actionRef->{"inserted"} eq "" ) {
			$lastId = $lastId - 1;

			last;
		}

	}

	return $lastId;
}


sub GetActionIdByStepId {
	my $self = shift;
	my $stepId = shift;

	my @actionsQueue = @{ $self->{actionQueue} };

	my $actualStep = -1;
	my $actualStepTmp = "";
	my $actionRef = undef;
	
	 
	for ( my $i = 0 ; $i < scalar(@actionsQueue) ; $i++ ) {

		$actionRef = $actionsQueue[$i];

		if($actualStepTmp ne $actionRef->{"actionStep"}){
			$actualStep++;
			
			if($actualStep == $stepId){			
				return $i;
			}
		}
		
		$actualStepTmp = $actionRef->{"actionStep"};
	}

}

sub ShowForm {
	my $self         = shift;
	my $fromAction	 = shift;
	my $runAllRef    = shift;
	my $runSingleRef = shift;
	my $guideChangedRef = shift;

	my @actionsQueue = @{ $self->{actionQueue} };

	my $form = GuideFrm->new( -1, $self->{'pcbId'}, $self->{'guideId'}, $self->{'childPcbId'}, \@actionsQueue, $self->{'messMngr'} );
	$form->SetActualItem($fromAction);
	

	$form->{'onRunAll'}    = $runAllRef; 
	$form->{'onRunSingle'} = $runSingleRef;
	$form->{'onGuideChanged'} = $guideChangedRef;

	unless($form->IsMainLoopRunning()){
		
		$form->MainLoop();
	}
	
}

 

sub __SetChildId {
	my $self         = shift;
	
	return "1";
	
}

sub __SetGuidId {
	my $self         = shift;
	
	return "1";
	
}

1;
