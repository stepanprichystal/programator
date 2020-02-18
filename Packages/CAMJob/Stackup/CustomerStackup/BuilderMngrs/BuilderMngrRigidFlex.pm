
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustomerStackup::StackupBuilder::V1Builder;
use base('Packages::CAMJob::Stackup::CustomerStackup::StackupBuilder::StackupBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustomerStackup::StackupBuilder::IStackupBuilder');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAMJob::Stackup::CustomerStackup::BlockBuilders::BuilderTitle';
use aliased 'Packages::CAMJob::Stackup::CustomerStackup::BlockBuilders::BuilderBody';
use aliased 'Packages::CAMJob::Stackup::CustomerStackup::BlockBuilders::BuilderThick';
use aliased 'Packages::CAMJob::Stackup::CustomerStackup::BlockBuilders::BuilderDrill';
use aliased 'Packages::CAMJob::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}


sub BuildSections {
	my $self = shift;
	my $sectionMngr = shift;
	

	my $blockBEGIN = $self->{"sectionMngr"}->GetBlock( Enums->Section_BEGIN );
	$blockBegin->SetIsActive(1);

	my $blockA_MAIN = $self->{"sectionMngr"}->GetBlock( Enums->Section_A_MAIN );
	$blockA_MAIN->SetIsActive(1);

	my $blockB_FLEX = $self->{"sectionMngr"}->GetBlock( Enums->Section_B_FLEX );
	$blockB_FLEX->SetIsActive(1);

	my $blockC_RIGIDFLEX = $self->{"sectionMngr"}->GetBlock( Enums->Section_C_RIGIDFLEX );
	C_RIGIDFLEX->SetIsActive(1);

	# if exist stiffener add extra blocks
	#if()
	
	
	$self->_CreateSectionClmns($sectionMngr);
	
}


sub BuildBlocks {
	my $self = shift;

	#my $stackupMngr = shift;
 
	# 3) Build stackup preview blocks

	# Add title of stackup table

	$self->AddBlock( BuilderTitle->new( $self->{"tblDrawing"}, $self->{"sectionMngr"} ) );

	# Add body with stackup

	$self->AddBlock( BuilderBody->new($self->{"tblDrawing"}, $self->{"sectionMngr"}) );

	# Add total thickness of stackup

	$self->AddBlock( BuilderThick->new($self->{"tblDrawing"}, $self->{"sectionMngr"}) );

	# Add total thickness of stackup

	$self->AddBlock( BuilderDrill->new($self->{"tblDrawing"}, $self->{"sectionMngr"}) );
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

