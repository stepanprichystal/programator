
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::Mngr2V;
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
use aliased 'Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngr2V';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $step       = shift;
	my $tblDrawing = shift;

	my $self = $class->SUPER::new( $inCAM, $jobId, $step, $tblDrawing );
	bless $self;

	$self->{"stackupMngr"} = StackupMngr2V->new( $inCAM, $jobId, $step);

	return $self;
}

sub BuildSections {
	my $self        = shift;
	my $sectionMngr = shift;

	my $stackupMngr = $self->{"stackupMngr"};

	Helper->DefaultSectionsLayout( $sectionMngr, $stackupMngr );

	# 1) Set section visibility

	my $sec_BEGIN = $sectionMngr->GetSection( Enums->Sec_BEGIN );
	$sec_BEGIN->SetIsActive(1);

	my $sec_A_MAIN = $sectionMngr->GetSection( Enums->Sec_A_MAIN );
	$sec_A_MAIN->SetIsActive(1);

	my $sec_B_FLEX = $sectionMngr->GetSection( Enums->Sec_B_FLEX );
	$sec_B_FLEX->SetIsActive(0);

	my $sec_C_RIGIDFLEX = $sectionMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	$sec_C_RIGIDFLEX->SetIsActive(0);

	my $sec_D_FLEXTAIL = $sectionMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	$sec_D_FLEXTAIL->SetIsActive(0);

	my $sec_E_STIFFENER = $sectionMngr->GetSection( Enums->Sec_E_STIFFENER );
	$sec_E_STIFFENER->SetIsActive(1);

	my $sec_END = $sectionMngr->GetSection( Enums->Sec_END );
	$sec_END->SetIsActive(1);

	# 2) Add extra columns

	# 3) Create columns

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

