#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::FeatureFilter::FilterPropStd;
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

	# Standard filter property

	$self->{"profileMode"} = undef;

	$self->{"text"} = undef;

	# Standard filter, advanced property

	$self->{"minLineLength"} = undef;

	$self->{"maxLineLength"} = undef;

	$self->{"featureIndexes"} = [];

	return $self;
}

# Filter according profile
# Mode:
# - Enums->ProfileMode_IGNORE (0)
# - Enums->ProfileMode_INSIDE (1)
# - Enums->ProfileMode_OUTSIDE (2)
sub SetProfile {
	my $self = shift;
	my $mode = shift;

	die "Profile mode is not defined " unless ( defined $mode );

	$self->{"profileMode"} = $mode;
}

# Filter by specific text or expression
sub SetText {
	my $self = shift;
	my $text = shift;

	die "Text is not defined " unless ( defined $text );

	$self->{"text"} = $text;

}

# Filter lline length
sub SetLineLength {
	my $self      = shift;
	my $minLength = shift;    # in mm
	my $maxLength = shift;    # in mm

	die "Min length is not defined " unless ( defined $minLength );
	die "Max length is not defined " unless ( defined $maxLength );

	$self->{"minLineLength"} = $minLength;
	$self->{"maxLineLength"} = $maxLength;

}

# Filter by feature indexes
sub AddFeatureIndexes {
	my $self    = shift;
	my $indexes = shift;    # array ref of indexes

	die "Feature indexes are not defined " if ( !defined $indexes || !@{$indexes} );

	push( @{ $self->{"featureIndexes"} }, @{$indexes} );

}

# return feature indexes
sub GetFeatureIndexes {
	my $self = shift;

	return @{ $self->{"featureIndexes"} };
}

sub BuildAll {
	my $self = shift;

	my $build = 1;

	my $inCAM = $self->{"inCAM"};

	# Build feature types
	if ( %{ $self->{"featTypes"} } ) {
		$inCAM->COM(
					 "set_filter_type",
					 "filter_name" => "",
					 "lines"       => $self->{"featTypes"}->{"line"} ? "yes" : "no",
					 "pads"        => $self->{"featTypes"}->{"pad"} ? "yes" : "no",
					 "surfaces"    => $self->{"featTypes"}->{"surface"} ? "yes" : "no",
					 "arcs"        => $self->{"featTypes"}->{"arc"} ? "yes" : "no",
					 "text"        => $self->{"featTypes"}->{"text"} ? "yes" : "no"
		);
	}

	# Build polarity
	if ( defined $self->{"polarity"} ) {

		$inCAM->COM(
					 'filter_set',
					 'filter_name'  => 'popup',
					 'update_popup' => 'no',
					 'polarity'     => ( $self->{"polarity"} eq "both" ? "positive\;negative" : $self->{"polarity"} )
		);
	}

	# Build include symbols
	if ( scalar( @{ $self->{"includeSym"} } ) ) {

		$inCAM->COM(
					 "set_filter_symbols",
					 "filter_name" => "",
					 "symbols"     => join( "\\;", @{ $self->{"includeSym"} } )
		);
	}

	# Build exclude symbols
	if ( scalar( @{ $self->{"excludeSym"} } ) ) {

		$inCAM->COM(
					 "set_filter_symbols",
					 "filter_name"     => "",
					 "exclude_symbols" => "yes",
					 "symbols"         => join( "\\;", @{ $self->{"excludeSym"} } )
		);
	}

	# Build include Attributes
	if ( @{ $self->{"includeAttr"} } ) {

		foreach my $att ( @{ $self->{"includeAttr"} } ) {

			my $attName    = $att->[0];
			my $attVal     = $att->[1];
			my $cond       = $att->[2];
			my %attValInfo = $self->_PrepareAttrValue( $attName, $attVal, $cond );

			$inCAM->COM(
						 'set_filter_attributes',
						 "filter_name"        => 'popup',
						 "exclude_attributes" => 'no',
						 "condition"          => $cond ? "yes" : "no",
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

	# Build exclude Attributes
	if ( @{ $self->{"excludeAttr"} } ) {

		foreach my $att ( @{ $self->{"excludeAttr"} } ) {

			my $attName    = $att->[0];
			my $attVal     = $att->[1];
			my $cond       = $att->[2];
			my %attValInfo = $self->_PrepareAttrValue( $attName, $attVal, $cond );

			$inCAM->COM(
						 'set_filter_attributes',
						 "filter_name"        => 'popup',
						 "exclude_attributes" => 'yes',
						 "condition"          => $cond ? "yes" : "no",
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

	# Build include Attribute condition
	if ( defined $self->{"includeAttrCond"} ) {

		$inCAM->COM( "set_filter_and_or_logic", "filter_name" => "popup", "criteria" => "inc_attr", "logic" => $self->{"includeAttrCond"} );
	}

	# Build exclude Attribute condition
	if ( defined $self->{"excludeAttrCond"} ) {

		$inCAM->COM( "set_filter_and_or_logic", "filter_name" => "popup", "criteria" => "exc_attr", "logic" => $self->{"excludeAttrCond"} );
	}

	# Build profile mode
	if ( defined $self->{"profileMode"} ) {

		$inCAM->COM( 'set_filter_profile', 'mode' => $self->{"profileMode"} );
	}

	# Build text
	if ( defined $self->{"text"} ) {

		$inCAM->COM(
					 'set_filter_text',
					 'filter_name' => "",
					 'text'        => $self->{"text"}
		);
	}

	# Build line length
	if ( defined $self->{"minLineLength"} && defined $self->{"maxLineLength"} ) {
		$inCAM->COM(
					 'set_filter_length',
					 'slot'       => "lines",
					 'min_length' => $self->{"minLineLength"},
					 'max_length' => $self->{"maxLineLength"}
		);
	}

	return $build;

}

sub Reset {
	my $self = shift;

	$self->SUPER::_Reset();

	# Standard filter property

	$self->{"profileMode"} = undef;

	$self->{"text"} = undef;

	# Standard filter, advanced property

	$self->{"minLineLength"} = undef;

	$self->{"maxLineLength"} = undef;

	$self->{"featureIndexes"} = [];

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

