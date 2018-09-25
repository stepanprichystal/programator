
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for NC operations
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifNCOperations;
use base ('Packages::TifFile::TifFile::TifFile');

#3th party library
use strict;
use warnings;
use Data::Dumper;

#local library
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"key"} = "NC";

	return $self;
}

#sub AddMachines {
#	my $self     = shift;
#	my @machines = @{ shift(@_) };
#
#	foreach my $m (@machines) {
#
#		$self->{"tifData"}->{ $self->{"key"} }->{$m} = {};
#	}
#
#}

sub SetNCOperations {
	my $self       = shift;
	my $operations = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"NCOperations"} = $operations;

	$self->_Save();

}

sub SetToolInfos {
	my $self     = shift;
	my $toolInfo = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"ToolInfo"} = $toolInfo;

	$self->_Save();
}

sub GetToolInfo {
	my $self     = shift;
	my $chainNum = shift;
	my $layer = shift;
	my $step = shift;

	my $toolInfo = $self->{"tifData"}->{ $self->{"key"} }->{"ToolInfo"};
	
	return undef if(!defined $toolInfo->{$step});
	
	return undef if(!defined $toolInfo->{$step}->{$layer});
	
	return undef if(!defined $toolInfo->{$step}->{$layer}->{$chainNum});
	
	return $toolInfo->{$step}->{$layer}->{$chainNum};
}

sub AddToolToOperation {
	my $self     = shift;
	my $layer    = shift;
	my $machine  = shift;    # machine suffix
	my $key      = shift;
	my $drillSize      = shift;
	my $chainNum = shift;
	my $step     = shift;
	my $duplRout = shift;

	my $result = 1;          # tool information was found in tif file
 

	# search tool info
	my $tInfo =	$self->GetToolInfo($chainNum, $layer, $step);
	 
	if ( defined $tInfo ) {

		# search all machines where participate this tool
		my @opItems = ();
		foreach my $opItem ( @{ $self->{"tifData"}->{ $self->{"key"} }->{"NCOperations"} } ) {

			if ( scalar( grep { $_ eq $layer } @{ $opItem->{"layers"} } ) && scalar( grep { $_ eq $machine } keys %{ $opItem->{"machines"} } ) ) {

				push( @opItems, $opItem );
			}
		}

		if ( scalar(@opItems) ) {

			foreach my $item (@opItems) {

				my %toolOpInfo = ();

				#$toolOpInfo{"key"} = $key;

				$toolOpInfo{"chainNum"}  = $chainNum;
				$toolOpInfo{"step"}      = $step;
				$toolOpInfo{"layer"}     = $layer;
				$toolOpInfo{"isDuplicate"}  = $duplRout;
				$toolOpInfo{"isOutline"} = $tInfo->{"isOutline"};
				$toolOpInfo{"drillSize"}  = $drillSize;

				$item->{"machines"}->{$machine}->{$key} = \%toolOpInfo;
			
			}

			$self->_Save();

		}
		else {
			$result = 0;
		}

	}
	else {

		print STDERR "Tool info was not found for tool chain: $chainNum, step: $step, layer: $layer";
		$result = 0;
	}

	return $result;

}

sub GetNCOperations {
	my $self = shift;

	return @{ $self->{"tifData"}->{ $self->{"key"} }->{"NCOperations"} };

}

#sub SetSignalLayers {
#	my $self   = shift;
#	my $layers = shift;
#
#	$self->{"tifData"}->{ $self->{"key"} } = $layers;
#
#	$self->_Save();
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

