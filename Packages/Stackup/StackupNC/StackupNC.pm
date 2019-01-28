
#-------------------------------------------------------------------------------------------#
# Description: Class, which provides information about NC operation on each press, each cores
# Source of stackup information is Stackup.pm class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNC;

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
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;

	# stackup
	$self->{"stackup"} = shift;

	# stackup
	$self->{"jobId"} = $self->{"stackup"}->{"pcbId"};

	# Signal layers
	my @press = ();
	$self->{"press"} = \@press;

	my @cores = ();
	$self->{"cores"} = \@cores;

	my @pltLayers = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @npltLayers = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @NCLayers = ( @pltLayers, @npltLayers );

	#get info which layer drilling/millin starts from/ end in
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );

	$self->{"ncLayers"} = \@NCLayers;

	$self->__InitPress();
	$self->__InitCores();
	return $self;
}

sub __InitPress {
	my $self = shift;

	my $stackup = $self->{"stackup"};

	my $pressCnt  = $stackup->GetPressCount();
	my %pressInfo = $stackup->GetPressInfo();

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;
		my $press      = $pressInfo{$pressOrder};

		my $topSignal = StackupNCSignal->new( $press->{"top"}, $press->{"topNumber"} );
		my $botSignal = StackupNCSignal->new( $press->{"bot"}, $press->{"botNumber"} );

		my $pressNC = StackupNCPress->new( $self, $topSignal, $botSignal, $pressOrder );

		push( @{ $self->{"press"} }, $pressNC );
	}
}

sub __InitCores {
	my $self = shift;

	my $stackup = $self->{"stackup"};
	my @cores   = $stackup->GetAllCores();

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

			push( @{ $self->{"cores"} }, $coreNC );

		}
	}
}

# Return specific press info object by press order
sub GetPress {
	my $self       = shift;
	my $pressOrder = shift;

	my @press = @{ $self->{"press"} };
	my $idx = ( grep { $press[$_]->GetPressOrder() eq $pressOrder } 0 .. $#press )[0];

	if ( defined $idx ) {

		return $press[$idx];

	}
}

# Return specific core info object by core number
sub GetCore {
	my $self       = shift;
	my $coreNumber = shift;

	my @cores = @{ $self->{"cores"} };
	my $idx = ( grep { $cores[$_]->GetCoreNumber() eq $coreNumber } 0 .. $#cores )[0];

	if ( defined $idx ) {

		return $cores[$idx];
	}

}

sub GetPressCnt {
	my $self = shift;
	return scalar( @{ $self->{"press"} } );
}

sub GetCoreCnt {
	my $self = shift;
	return scalar( @{ $self->{"cores"} } );
}

# Return if press order is last pressing
sub GetIsLastPress {
	my $self       = shift;
	my $pressOrder = shift;

	my @press = @{ $self->{"press"} };

	if ( $pressOrder == scalar(@press) ) {
		return 1;
	}
	else {
		return 0;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupNC::StackupNC';
	use aliased 'Packages::Stackup::Stackup::Stackup';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $stackup = Stackup->new("d152456");
	my $stackupNC = StackupNC->new( $inCAM, $stackup );

	my $coreStack   = $stackup->GetCore(2);
	my $coreStackNC = $stackupNC->GetCore(1);

	print $coreStack->GetPlatingExists();

	die;

}

1;

