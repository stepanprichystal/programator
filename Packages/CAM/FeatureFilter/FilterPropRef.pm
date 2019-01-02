#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::FeatureFilter::FilterPropRef;
use base('Packages::CAM::FeatureFilter::FilterPropBase');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::FeatureFilter::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	# Reference filter property

	$self->{"refLayers"} = [];

	$self->{"referenceMode"} = undef;    # touch is default

	return $self;
}

# Reference filter is active, if some reference filter is set
sub IsActive {
	my $self = shift;

	return scalar( @{ $self->{"refLayers"} } ) ? 1 : 0;
}

sub SetRefLayer {
	my $self  = shift;
	my $layer = shift;

	die "Layer is not defined " if ( !defined $layer );

	$self->{"refLayers"} = [$layer];
}

sub SetRefLayers {
	my $self   = shift;
	my $layers = shift;

	die "Layers are not defined " if ( !defined $layers || !@{$layers} );

	$self->{"refLayers"} = $layers;
}

# Tell where use filter in layer
# Mode of reference selection
# - Enums->RefMode_TOUCH - take all features touch reference features
# - Enums->RefMode_DISJOINT - take all features not touching any reference features
# - Enums->RefMode_COVER - take all features fully covered by at least one reference feature
# - Enums->RefMode_INCLUDE - take all features that fully include at least one reference feature
# - Enums->RefMode_SAMECENTER - take all features that fully include at least one reference feature
sub SetReferenceMode {
	my $self = shift;
	my $mode = shift;

	die "Profile mode is not defined " unless ( defined $mode );

	$self->{"referenceMode"} = $mode;
}

sub BuildAll {
	my $self = shift;

	my $build = 1;

	my $inCAM = $self->{"inCAM"};

	# build only if reference layers is set
	unless ( $self->IsActive() ) {
		$build = 0;
		return $build;
	}

	# Build include Attributes
	if ( @{ $self->{"includeAttr"} } ) {

		foreach my $att ( @{ $self->{"includeAttr"} } ) {
			
			my $attName    = $att->[0];
			my $attVal     = $att->[1];
	 
			my %attValInfo = $self->_PrepareAttrValue( $attName, $attVal );

			$inCAM->COM(
						 'set_filter_attributes',
						 "filter_name"        => 'ref_select',
						 "exclude_attributes" => 'no',
						 "condition"          => 'yes',
						 "attribute"          => $attName,
						 "min_int_val"        => $attValInfo{"min_int_val"},
						 "max_int_val"        => $attValInfo{"max_int_val"},
						 "min_float_val"      => $attValInfo{"min_float_val"},
						 "max_float_val"      => $attValInfo{"max_float_val"},
						 "option"             => $attValInfo{"option"},
						 "text"               => $attValInfo{"text"}
			);

		}
	}
	
	# Byukd include attr condition
	if ( defined $self->{"includeAttrCond"} ) {

		$inCAM->COM( "set_filter_and_or_logic", "filter_name" => "ref_select", "criteria" => "inc_attr", "logic" => $self->{"includeAttrCond"} );
	}

	return $build;

}

# Return builded string from ref layers
sub BuildRefLayer {
	my $self = shift;

	 

	return join( "\\;", @{ $self->{"refLayers"} } );
}

# Return builded reference filter mode
sub BuildReferenceMode {
	my $self = shift;

	if ( defined $self->{"referenceMode"} ) {

		return $self->{"referenceMode"};

	}
	else {
		return Enums->RefMode_TOUCH;
	}
}

# Return builded feat trypes in string
sub BuildFeatTypes {
	my $self = shift;

	my $typesStr = "";

	if ( %{ $self->{"featTypes"} } ) {

		foreach my $type ( keys %{ $self->{"featTypes"} } ) {

			$typesStr .= $type . '\;' if ( $self->{"featTypes"}->{$type} );
		}
		
		# remove last backslash
		$typesStr =~ s/\\;$//;
	}
	else {
		$typesStr = 'line\;pad\;surface\;arc\;text';
	}

	return $typesStr;
}

# Return polarity string
sub BuildPolarity {
	my $self = shift;

	if ( defined $self->{"polarity"} ) {

		return $self->{"polarity"} eq "both" ? "positive\;negative" : $self->{"polarity"};
	}
	else {

		return "positive\;negative";
	}

}

# Return include symbol string
sub BuildIncludeSym {
	my $self = shift;

	if ( scalar( @{ $self->{"includeSym"} } ) ) {

		return join( "\\;", @{ $self->{"includeSym"} } );

	}
	else {

		return "";
	}

}

# Return exclude symbol string
sub BuildExcludeSym {
	my $self = shift;

	if ( scalar( @{ $self->{"excludeSym"} } ) ) {

		return join( "\\;", @{ $self->{"excludeSym"} } );

	}
	else {

		return "";
	}
}

sub Reset {
	my $self = shift;

	$self->SUPER::_Reset();

	# Reference layers
	$self->{"refLayers"} = [];

	# Reference filter property
	$self->{"referenceMode"} = undef;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
}

1;

