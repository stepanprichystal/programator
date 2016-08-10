                  
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::Guides::GuideTypeOne;
use base ("Programs::CamGuide::Guides::Guide");    # declare superclasses

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;

#local library
use aliased 'Programs::CamGuide::Enums';
use aliased 'Programs::CamGuide::Helper';
#use Programs::CamGuide::Actions::Milling;
#use Programs::CamGuide::Actions::Pause;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self     = shift;                    # Create an anonymous hash, and #self points to it.
	#my $pcbId    = shift;
	#my $inCAM    = shift;
	#my $messMngr = shift;
	#my $childId = shift;
	my $guidId = 0;

	$self = Programs::CamGuide::Guides::Guide->new( $guidId, @_ );

	bless $self;                             # Connect the hash to the package Cocoa.

	Helper->LoadAllActionModules();
	
	$self->__SetGuideActions();

	return $self;                            # Return the reference to the hash.
}

sub __SetGuideActions {

	my $self = shift;

	$self->_SetStep( Enums->ActualStep_STEPO );

	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionCreateOStep,    Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionCreateOStep,    Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionCreateOStep,    Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionCreateOStep,    Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionLoadInputFiles, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Pause::ActionCheckLoadedLayer, Enums->ActionType_PAUSE );

	

	$self->_SetStep( Enums->ActualStep_STEPOPLUS1 );

	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionCreateO_1Step,      Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionCheckIfExistRLayer, Enums->ActionType_CHECK );
	$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionRunChecklist,       Enums->ActionType_DOANDSTOP );

	$self->_SetStep( Enums->ActualStep_STEPPANEL );

	#$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionCreatePanelStep, Enums->ActionType_DO );
	#$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionPcbPanelization, Enums->ActionType_DO );
	#$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionAddBorder,       Enums->ActionType_DO );
	#$self->_AddAction( \&Programs::CamGuide::Actions::Pause::ActionCheckWholePcb,     Enums->ActionType_PAUSE );
	#$self->_AddAction( \&Programs::CamGuide::Actions::Milling::ActionAddBorder,       Enums->ActionType_DO );


}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

}

1;
