
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for NC operations
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifNCOperations;
use base ('Packages::TifFile::TifFile::TifFile');

#3th party library
use strict;
use warnings;

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

sub SetToolInfo {
	my $self     = shift;
	my $toolInfo = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"ToolInfo"} = $toolInfo;

	$self->_Save();

}

sub AddToolToOperation {
	my $self     = shift;
	my $layer    = shift;
	my $machine  = shift;    # machine suffix
	my $key      = shift;
	my $chainNum = shift;
	my $step     = shift;
	my $duplRout = shift;

	my $result = 1;          # tool information was found in tif file

	print STDERR "Tool info\n\n";
	print STDERR "layer = $layer\n";
	print STDERR "machine = $machine\n";
	print STDERR "key = $key\n";
	print STDERR "chainNum = $chainNum\n";
	print STDERR "step = $step\n";
	print STDERR "duplRout = $duplRout\n";

	# search tool info

	my $tInfo = $self->{"tifData"}->{ $self->{"key"} }->{"ToolInfo"}->{$step}->{$layer}->{$chainNum};

	if ( defined $tInfo ) {

		# search all nc operation where participate this tool
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

				$toolOpInfo{"chainNum"} = $chainNum;
				$toolOpInfo{"step"}      = $step;
				$toolOpInfo{"layer"}     = $layer;
				$toolOpInfo{"duplRout"}  = $duplRout;
				$toolOpInfo{"isOutline"} = $tInfo->{"isOutline"};

				$item->{"machines"}->{$machine}->{$key} = \%toolOpInfo;

			}

			$self->_Save();
			
		}else {
			$result = 0;
		}

	}
	else {

		print STDERR "Tool info was not found for tool chain: $chainNum, step: $step, layer: $layer";
		$result = 0;
	}

	return $result;

}

sub GetNCOperations{
	my $self     = shift;
	
	return @{$self->{"tifData"}->{ $self->{"key"} }->{"NCOperations"}};
	
	
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

