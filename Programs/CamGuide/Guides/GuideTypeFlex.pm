
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::Guides::GuideTypeFlex;
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

	my $self   = shift;    # Create an anonymous hash, and #self points to it.
	                       #my $pcbId    = shift;
	                       #my $inCAM    = shift;
	                       #my $messMngr = shift;
	                       #my $childId = shift;
	my $guidId = 3;

	$self = Programs::CamGuide::Guides::Guide->new( $guidId, @_ );

	bless $self;           # Connect the hash to the package Cocoa.

	Helper->LoadAllActionModules();

	$self->__SetGuideActions();

	return $self;          # Return the reference to the hash.
}

sub __SetGuideActions {

	my $self = shift;

	$self->_SetStep( Enums->ActualStep_STEPOPLUS1 );


	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoBendArea,   Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoCoverlayPins,   Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoCoverlayLayers, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoSolderTemplateLayers, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoPrepregLayers, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoRoutTransitionLayers, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoFlexiMaskLayer, Enums->ActionType_DO );
	$self->_AddAction( \&Programs::CamGuide::Actions::Flex::ActionDoPrepareBendAreaOther, Enums->ActionType_DO );


	$self->_SetStep( Enums->ActualStep_STEPPANEL );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

}

1;
