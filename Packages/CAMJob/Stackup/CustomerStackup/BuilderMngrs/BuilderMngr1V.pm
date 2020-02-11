
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

sub Build {
	my $self = shift;

	#my $stackupMngr = shift;

	# 1) Define section used in stackup preview
	my @sections = $self->__DefineSections();

	# 2) Create columns by defined segments

	# 3) Build stackup preview blocks

	# Add title of stackup table

	$self->_AddBlock( BuilderTitle->new( $self->{"tblDrawing"}, \@section ) );

	# Add body with stackup

	$self->_AddBlock( BuilderBody->new() );

	# Add total thickness of stackup

	$self->_AddBlock( BuilderThick->new() );

	# Add total thickness of stackup

	$self->_AddBlock( BuilderDrill->new() );
}

sub __DefineSections {
	my $self = shift;
	
	my @sections = ();
	
	# Add Begin section always
	
	my 
	
	

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

