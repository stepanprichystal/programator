#-------------------------------------------------------------------------------------------#
# Description:  Object oriented feature filter from InCAM
# Each function can be combined in order filter requested features
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::FeatureFilter::FeatureFilter;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"layerName"} = shift;

	$self->{"includeSym"} = undef;    # Included symbols
	$self->{"excludeSym"} = undef;    # Excluded symbols

	$self->{"includeAttr"} = undef;   # Included attributes name + value
	$self->{"excludeAttr"} = undef;   # Included attributes name + value

	$self->{"featureIndexes"} = undef;    # filter by featuer indexes

	$self->Reset();

	return $self;
}

sub Select {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM('filter_area_strt');
	$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );

	$self->{"inCAM"}->COM('get_select_count');

	return $self->{"inCAM"}->GetReply();

}

sub Reset {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	CamLayer->WorkLayer( $self->{"inCAM"}, $self->{"layerName"} );

	$self->{"inCAM"}->COM( 'filter_reset', filter_name => 'popup' );

	# Clear properties

	my @is = ();
	$self->{"includeSym"} = \@is;
	my @es = ();
	$self->{"excludeSym"} = \@es;

	my @ia = ();
	$self->{"includeAttr"} = \@ia;
	my @ea = ();
	$self->{"excludeAttr"} = \@ea;

	my @fi = ();
	$self->{"featureIndexes"} = \@fi;

}

sub Unselect {
	my $self = shift;

}

sub SetPolarity {
	my $self     = shift;
	my $polarity = shift;    #  both\positive\negative

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM(
				 'filter_set',
				 'filter_name'  => 'popup',
				 'update_popup' => 'no',
				 'polarity'     => ( $polarity eq "both" ? "positive\;negative" : $polarity )
	);

}

sub SetTypes {
	my $self  = shift;
	my @types = @{ shift(@_) };

	my $typeStr = join( "\\;", @types );

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM(
				 'filter_set',
				 'filter_name'  => 'popup',
				 'update_popup' => 'no',
				 'feat_types'   => $typeStr
	);

}

sub SetText {
	my $self = shift;
	my $text = shift;

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM(
				 'set_filter_text',
				 'filter_name' => "",
				 'text'        => $text
	);

}

sub AddIncludeSymbols {
	my $self    = shift;
	my @symbols = @{ shift(@_) };

	push( @{ $self->{"includeSym"} }, @symbols );
	my $symbolStr = join( "\\;", @{ $self->{"includeSym"} } );

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM( "set_filter_symbols", "filter_name" => "", "symbols" => $symbolStr );

}

sub AddExcludeSymbols {
	my $self    = shift;
	my @symbols = @{ shift(@_) };

	push( @{ $self->{"excludeSym"} }, @symbols );
	my $symbolStr = join( "\\;", @{ $self->{"excludeSym"} } );

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM( "set_filter_symbols", "filter_name" => "", "exclude_symbols" => $symbolStr );

}

# include attribute and att value to filter
sub AddIncludeAtt {
	my $self       = shift;
	my $attName    = shift;
	my $attVal     = shift;
	my $refenrence = shift;    # if set, attributes are set for reference filter

	unless ( defined $attName ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# decide, which type is attribute
	my %attrInfo = CamAttributes->GetAttrParamsByName( $inCAM, $jobId, $attName );

	my $min_int_val   = 0;
	my $max_int_val   = 0;
	my $min_float_val = 0;
	my $max_float_val = 0;
	my $option        = "";
	my $text          = "";

	if ( $attrInfo{"gATRtype"} eq "int" ) {

		$min_int_val = $attVal->{"min"};
		$max_int_val = $attVal->{"max"};

	}
	elsif ( $attrInfo{"gATRtype"} eq "float" ) {

		$min_float_val = $attVal->{"min"};
		$max_float_val = $attVal->{"max"};

	}
	elsif ( $attrInfo{"gATRtype"} eq "option" ) {

		$option = $attVal;

	}
	elsif ( $attrInfo{"gATRtype"} eq "text" ) {

		$text = $attVal;
	}

	$inCAM->COM(
				 'set_filter_attributes',
				 filter_name => !$refenrence ? 'popup' : 'ref_select',
				 exclude_attributes => 'no',
				 condition          => 'yes',
				 attribute          => $attName,
				 min_int_val        => $min_int_val,
				 max_int_val        => $max_int_val,
				 min_float_val      => $min_float_val,
				 max_float_val      => $max_float_val,
				 option             => $option,
				 text               => $text
	);

}

# include attribute and att value to filter
sub AddFeatureIndexes {
	my $self           = shift;
	my $featureIndexes = shift;

	push( @{ $self->{"featureIndexes"} }, @{$featureIndexes} );

	my $str = join( "\\;", @{ $self->{"featureIndexes"} } );
	
	my $inCAM = $self->{"inCAM"};

	$inCAM->COM(
		"adv_filter_set",
		"filter_name" => "popup",
		"active"      => "yes",
		"indexes"     => $str,

	);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $f = FeatureFilter->new( $inCAM, $jobId, "fzc" );

	#$f->SetPolarity("positive");

	#my @types = ("surface", "pad");
	#$f->SetTypes(\@types);

	#my @syms = ("r500", "r1");
	#$f->AddIncludeSymbols(  \["r500", "r1"] );

	my %num = ( "min" => 1100 / 1000 / 25.4, "max" => 1100 / 1000 / 25.4 );
	$f->AddIncludeAtt( ".rout_tool", \%num );

	print $f->Select();

	print "fff";

}

1;

