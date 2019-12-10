
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

# Set info about all NC operations like c1, fz1, fr, etc
sub SetNCOperations {
	my $self       = shift;
	my $operations = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"NCOperations"} = $operations;

	$self->_Save();

}

# Set info about chain tool for step and layer (if tool is outline etc)
sub SetToolInfos {
	my $self     = shift;
	my $toolInfo = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"ToolInfo"} = $toolInfo;

	$self->_Save();
}


# Set setting for each layer contain keys:
# - name
# - stretchX
# - stretchY
sub SetNCLayerSett {
	my $self         = shift;
	my $ncLayersSett = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"LayerSett"} = $ncLayersSett;

	$self->_Save();
}

sub GetToolInfo {
	my $self     = shift;
	my $chainNum = shift;
	my $layer    = shift;
	my $step     = shift;

	my $toolInfo = $self->{"tifData"}->{ $self->{"key"} }->{"ToolInfo"};

	return undef if ( !defined $toolInfo->{$step} );

	return undef if ( !defined $toolInfo->{$step}->{$layer} );

	return undef if ( !defined $toolInfo->{$step}->{$layer}->{$chainNum} );

	return $toolInfo->{$step}->{$layer}->{$chainNum};
}

# Add info about exported NC file to specific operation
sub AddToolToOperation {
	my $self          = shift;
	my $layer         = shift;
	my $machine       = shift;    # machine suffix
	my $key           = shift;
	my $drillSize     = shift;
	my $chainNum      = shift;
	my $toolOperation = shift;
	my $step          = shift;
	my $duplRout      = shift;
	my $magazineInfo  = shift;    # if special tool (see Config/MagazineSpec.xml) magazineInfo is set

	my $result = 1;               # tool information was found in tif file

	# search tool info
	my $tInfo = $self->GetToolInfo( $chainNum, $layer, $step );

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

				$toolOpInfo{"step"}          = $step;
				$toolOpInfo{"layer"}         = $layer;
				$toolOpInfo{"isDuplicate"}   = $duplRout;
				$toolOpInfo{"isOutline"}     = $tInfo->{"isOutline"};
				$toolOpInfo{"drillSize"}     = $drillSize;
				$toolOpInfo{"chainNum"}      = $chainNum;
				$toolOpInfo{"toolOperation"} = $toolOperation;

				if ($magazineInfo) {
					$toolOpInfo{"magazineInfo"} = $magazineInfo;
				}

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

sub GetNCLayerSett {
	my $self  = shift;
	my $lName = shift;

	return @{ $self->{"tifData"}->{ $self->{"key"} }->{"LayerSett"} }->{$lName};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

