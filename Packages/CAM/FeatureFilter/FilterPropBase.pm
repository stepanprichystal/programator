#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::FeatureFilter::FilterPropBase;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::FeatureFilter::Enums';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	# Base filter property

	$self->{"featTypes"} = {};

	$self->{"polarity"} = undef;

	$self->{"includeSym"} = [];    # Included symbols
	$self->{"excludeSym"} = [];    # Excluded symbols

	$self->{"includeAttr"} = [];   # Included attributes name + value
	$self->{"excludeAttr"} = [];   # Included attributes name + value

	$self->{"includeAttrCond"} = undef;
	$self->{"excludeAttrCond"} = undef;

	return $self;
}

# Filter by feature types. Options:
# - "lines"    => 0/1,
# - "pads"     => 0/1,
# - "surfaces" => 0/1,
# - "arcs"     => 0/1,
# - "text"     => 0/1,
sub SetFeatureTypes {
	my $self = shift;
	my %args = (
		"line"    => 0,
		"pad"     => 0,
		"surface" => 0,
		"arc"     => 0,
		"text"    => 0,
		@_,    # argument pair list goes here
	);

	die "Feat types are not defined " unless (%args);

	foreach my $key ( keys %args ) {

		unless ( grep { $_ eq $key } ( "line", "pad", "surface", "arc", "text" ) ) {

			die "Paramter: \"$key\" is not allowed. Allowed parameters: line, pad, surface, arc, text";
		}
	}

	%{ $self->{"featTypes"} } = %args;
}

# Filter by polarity
# - Polarity_POSITIVE  - postivice
# - Polarity_NEGATIVE - negative
# - Polarity_BOTH positive and negative
sub SetPolarity {
	my $self     = shift;
	my $polarity = shift;    # Enums->Polarity_XXXXX both\positive\negative

	die "Polarity is not defined " unless ( defined $polarity );

	if (    $polarity ne Enums->Polarity_POSITIVE
		 && $polarity ne Enums->Polarity_NEGATIVE
		 && $polarity ne Enums->Polarity_BOTH )
	{
		die "Polarity value: \"$polarity\" is not allowed. Allowed values are: positive, negative, both";
	}

	$self->{"polarity"} = $polarity;

}

# Filter by feature symbols
sub AddIncludeSymbols {
	my $self    = shift;
	my $symbols = shift;    # array ref of symbols

	die "Symbols is not defined " if ( !defined $symbols || !@{$symbols} );

	push( @{ $self->{"includeSym"} }, @{$symbols} );

}

# Exclude symbols from filter
sub AddExcludeSymbols {
	my $self    = shift;
	my $symbols = shift;    # array ref of symbols

	die "Symbols is not defined " if ( !defined $symbols || !@{$symbols} );

	push( @{ $self->{"excludeSym"} }, @{$symbols} );
}

# Include attribute and att value to filter
sub AddIncludeAtt {
	my $self     = shift;
	my $attName  = shift;    # attribute name
	my $attValue = shift;    # attribut value. Type according InCAM attribute type, undef is allowed

	die "Att name is not defined " unless ( defined $attName );

	push( @{$self->{"includeAttr"}},  [$attName, $attValue] );

}

# Exclude attribute and att value to filter
sub AddExcludeAtt {
	my $self     = shift;
	my $attName  = shift;    # attribute name
	my $attValue = shift;    # attribut value. Type according InCAM attribute type, undef is allowed

	die "Att name is not defined " unless ( defined $attName );

	push( @{$self->{"excludeAttr"}},  [$attName, $attValue] );

}

# Set logic between include attributes
# - Enums->Logic_AND
# - Enums->Logic_OR
sub SetIncludeAttrCond {
	my $self = shift;
	my $cond = shift;

	die "Condition is not defined " unless ( defined $cond );

	if (    $cond ne Enums->Logic_AND
		 && $cond ne Enums->Logic_OR )
	{
		die "Condition value: \"$cond\" is not allowed. Allowed values are:" . join( "; ", Enums->Logic_AND, Enums->Logic_OR );
	}

	$self->{"includeAttrCond"} = $cond;
}

# Set logic between include attributes
# - Enums->Logic_AND
# - Enums->Logic_OR
sub SetExcludeAttrCond {
	my $self = shift;
	my $cond = shift;

	die "Condition is not defined " unless ( defined $cond );
	
	if (    $cond ne Enums->Logic_AND
		 && $cond ne Enums->Logic_OR )
	{
		die "Condition value: \"$cond\" is not allowed. Allowed values are:" . join( "; ", Enums->Logic_AND, Enums->Logic_OR );
	}

	$self->{"excludeAttrCond"} = $cond;
}

sub _Reset {
	my $self = shift;

	$self->{"featTypes"} = {};

	$self->{"polarity"} = undef;

	$self->{"includeSym"} = [];
	$self->{"excludeSym"} = [];

	$self->{"includeAttr"} = [];
	$self->{"excludeAttr"} = [];

	$self->{"includeAttrCond"} = undef;
	$self->{"excludeAttrCond"} = undef;

}

sub _PrepareAttrValue {
	my $self    = shift;
	my $attName = shift;
	my $attVal  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %attrInfo = CamAttributes->GetAttrParamsByName( $inCAM, $jobId, $attName );

	my %attValInf = ();
	$attValInf{"min_int_val"}   = 0;
	$attValInf{"max_int_val"}   = 0;
	$attValInf{"min_float_val"} = 0;
	$attValInf{"max_float_val"} = 0;
	$attValInf{"option"}        = 0;
	$attValInf{"text"}          = 0;

	if ( $attrInfo{"gATRtype"} eq "int" ) {

		$attValInf{"min_int_val"} = $attVal->{"min"};
		$attValInf{"max_int_val"} = $attVal->{"max"};

	}
	elsif ( $attrInfo{"gATRtype"} eq "float" ) {

		$attValInf{"min_float_val"} = $attVal->{"min"};
		$attValInf{"max_float_val"} = $attVal->{"max"};

	}
	elsif ( $attrInfo{"gATRtype"} eq "option" ) {

		$attValInf{"option"} = $attVal;

	}
	elsif ( $attrInfo{"gATRtype"} eq "text" ) {

		$attValInf{"text"} = $attVal;
	}

	return %attValInf;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

