
#-------------------------------------------------------------------------------------------#
# Description: Class, which provides information about NC operation on each press, each cores
# Source of stackup information is Stackup.pm class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNC;
use base('Packages::Stackup::StackupBase::StackupBase');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::Stackup::StackupNC::StackupNCPress';
use aliased 'Packages::Stackup::StackupNC::StackupNCCore';
use aliased 'Packages::Stackup::StackupNC::StackupNCSignal';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new { 
	my $class = shift;
	
	my $jobId = shift;
	my $inCAM = shift;
		
	my $self = $class->SUPER::new($jobId);
	bless $self;
 
 
	# SET PROPERTIES
	
	$self->{"inCAM"} = $inCAM;
	 
	$self->{"NCPress"} = [];

	$self->{"NCCores"} = [];

	my @pltLayers = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @npltLayers = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @NCLayers = ( @pltLayers, @npltLayers );
	
	#get info which layer drilling/millin starts from/ end in
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );
	
	$self->{"ncLayers"} = \@NCLayers;

	# INIT STACKUP

	$self->__InitPress();
	$self->__InitCores();
	
	return $self;
}

sub __InitPress {
	my $self = shift;
 
	my $pressCnt  = $self->SUPER::GetPressCount();
	my %pressInfo = $self->SUPER::GetPressInfo();

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;
		my $press      = $pressInfo{$pressOrder};

		my $topSignal = StackupNCSignal->new( $press->{"top"}, $press->{"topNumber"} );
		my $botSignal = StackupNCSignal->new( $press->{"bot"}, $press->{"botNumber"} );

		my $pressNC = StackupNCPress->new( $self, $topSignal, $botSignal, $pressOrder );

		push( @{ $self->{"NCPress"} }, $pressNC );
	}
}

sub __InitCores {
	my $self = shift;

	my @cores   = $self->SUPER::GetAllCores();

	for ( my $i = 0 ; $i < scalar(@cores) ; $i++ ) {

		my $coreNum = $i + 1;

		my $idx = ( grep { $cores[$_]->GetCoreNumber() eq $coreNum } 0 .. $#cores )[0];

		if ( defined $idx ) {

			my $core = $cores[$idx];

			my $topCopper = $core->GetTopCopperLayer();
			my $botCopper = $core->GetBotCopperLayer();

			my $topSignal = StackupNCSignal->new( $topCopper->GetCopperName(), $topCopper->GetCopperNumber() );
			my $botSignal = StackupNCSignal->new( $botCopper->GetCopperName(), $botCopper->GetCopperNumber() );

			my $coreNC = StackupNCCore->new( $self, $topSignal, $botSignal, $coreNum );

			push( @{ $self->{"NCCores"} }, $coreNC );

		}
	}
}

# Return specific press info object by press order
sub GetPress {
	my $self       = shift;
	my $pressOrder = shift;

	my @press = @{ $self->{"NCPress"} };
	my $idx = ( grep { $press[$_]->GetPressOrder() eq $pressOrder } 0 .. $#press )[0];

	if ( defined $idx ) {

		return $press[$idx];

	}
}

# Return specific core info object by core number
sub GetCore {
	my $self       = shift;
	my $coreNumber = shift;

	my @cores = @{ $self->{"NCCores"} };
	my $idx = ( grep { $cores[$_]->GetCoreNumber() eq $coreNumber } 0 .. $#cores )[0];

	if ( defined $idx ) {

		return $cores[$idx];
	}

}

sub GetPressCnt {
	my $self = shift;
	return scalar( @{ $self->{"NCPress"} } );
}

sub GetCoreCnt {
	my $self = shift;
	return scalar( @{ $self->{"NCCores"} } );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupNC::StackupNC';
	use aliased 'Packages::Stackup::Stackup::Stackup';
	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM  = InCAM->new();

 	my $jobId = "d113609";
	my $stackupNC = StackupNC->new( $jobId, $inCAM);
	
	 
	my $coreStackNC = $stackupNC->GetCore(1);
 
	die;

}

1;

