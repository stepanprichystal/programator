
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::Mngr1V;
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
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

sub BuildSections {
	my $self = shift;
	my $sectionMngr = shift;
	
 
	
}


sub BuildBlocks {
	my $self = shift;

	 
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

