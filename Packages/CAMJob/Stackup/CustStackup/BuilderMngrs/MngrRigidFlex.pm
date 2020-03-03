
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::MngrRigidFlex;
use base('Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::BuilderMngrBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::IBuilderMngr');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderTitle';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderBody';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderThick';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderDrill';
use aliased 'Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrVV';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $tblDrawing = shift;

	my $self = $class->SUPER::new( $inCAM, $jobId, $tblDrawing );
	bless $self;

	$self->{"stackupMngr"} = StackupMngrVV->new( $inCAM, $jobId );

	return $self;
}

sub BuildSections {
	my $self        = shift;
	my $sectionMngr = shift;

	my $stackupMngr = $self->{"stackupMngr"};

	my $blockBEGIN = $sectionMngr->GetSection( Enums->Section_BEGIN );
	$blockBEGIN->SetIsActive(1);

	my $blockA_MAIN = $sectionMngr->GetSection( Enums->Section_A_MAIN );
	$blockA_MAIN->SetIsActive(1);

	my $blockB_FLEX = $sectionMngr->GetSection( Enums->Section_B_FLEX );
	$blockB_FLEX->SetIsActive(1);

	my $blockC_RIGIDFLEX = $sectionMngr->GetSection( Enums->Section_C_RIGIDFLEX );
	$blockC_RIGIDFLEX->SetIsActive(1);

	$self->_CreateSectionClmns($sectionMngr);

}

sub BuildBlocks {
	my $self        = shift;
	my $sectionMngr = shift;

	my $stackupMngr = $self->{"stackupMngr"};

	# 3) Build stackup preview blocks

	# Add title of stackup table

	$self->_AddBlock( BuilderTitle->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblMain"}, $stackupMngr, $sectionMngr ) );

	# Add body with stackup

	$self->_AddBlock( BuilderBody->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblMain"}, $stackupMngr, $sectionMngr ) );

	# Add total thickness of stackup

	$self->_AddBlock( BuilderThick->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblMain"}, $stackupMngr, $sectionMngr ) );

	# Add total thickness of stackup

	$self->_AddBlock( BuilderDrill->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblMain"}, $stackupMngr, $sectionMngr ) );


	 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

