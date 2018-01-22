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
use aliased 'Packages::CAM::FeatureFilter::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"layerName"}  = shift;
	$self->{"layerNames"} = shift;    # array of layer names, in case of more layers we want to filter

	$self->{"includeSym"} = undef;    # Included symbols
	$self->{"excludeSym"} = undef;    # Excluded symbols

	$self->{"includeAttr"} = undef;   # Included attributes name + value
	$self->{"excludeAttr"} = undef;   # Included attributes name + value

	$self->{"featureIndexes"} = undef;    # filter by featuer indexes

	$self->Reset();

	return $self;
}

sub SetFilterType {
	my $self = shift;
	my %args = (
		"lines"    => 0,
		"pads"     => 0,
		"surfaces" => 0,
		"arcs"     => 0,
		"text"     => 0,
		@_,    # argument pair list goes here
	);

	my $inCAM = $self->{"inCAM"};

	my $lines    = $args{"lines"}    ? "yes" : "no";
	my $pads     = $args{"pads"}     ? "yes" : "no";
	my $surfaces = $args{"surfaces"} ? "yes" : "no";
	my $arcs     = $args{"arcs"}     ? "yes" : "no";
	my $text     = $args{"text"}     ? "yes" : "no";

	$inCAM->COM(
				 "set_filter_type",
				 "filter_name" => "",
				 "lines"       => $lines,
				 "pads"        => $pads,
				 "surfaces"    => $surfaces,
				 "arcs"        => $arcs,
				 "text"        => $text
	);

}

sub Select {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
 
	# if filter indexes are set, do select in loop (max 20 index in one loop)
	# Reason: cmd adv_filter_set, is posiible process only 200chars in parameter "indexes"
	if ( scalar( @{ $self->{"featureIndexes"} } ) ) {
		my @ids = @{ $self->{"featureIndexes"} };
		my @idsPart = ();

		# each loop select 20 features
		for ( my $i = 0 ; $i < scalar(@ids) ; $i++ ) {

			push( @idsPart, $ids[$i] );

			if ( scalar(@idsPart) == 20 ) {

				my $str = join( "\\;", @idsPart );
				$inCAM->COM(
							 "adv_filter_set",
							 "filter_name" => "popup",
							 "active"      => "yes",
							 "indexes"     => $str,
				);

				$inCAM->COM('filter_area_strt');
				$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
 
				@idsPart = ();
			}
		}
		
		# select rest of features
	if ( scalar(@idsPart) ) {
		my $str = join( "\\;", @idsPart );
		$inCAM->COM(
					 "adv_filter_set",
					 "filter_name" => "popup",
					 "active"      => "yes",
					 "indexes"     => $str,
		);

		$inCAM->COM('filter_area_strt');
		$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
		$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	}
	}
	else {

		$inCAM->COM('filter_area_strt');
		$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );

	}

	$self->{"inCAM"}->COM('get_select_count');

	return $self->{"inCAM"}->GetReply();

}

sub Reset {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	if ( defined $self->{"layerNames"} ) {

		CamLayer->AffectLayers( $self->{"inCAM"}, $self->{"layerNames"} );
	}
	elsif ( defined $self->{"layerName"} ) {

		CamLayer->WorkLayer( $self->{"inCAM"}, $self->{"layerName"} );
	}
	else {

		die "no layer defined";
	}
	$self->{"inCAM"}->COM('adv_filter_reset');

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

# Tell where use filter in layer
# Mode:
#0 - ignore the profile
#1 - inside the profile
#2 - outside the profile
sub SetProfile {
	my $self = shift;
	my $mode = shift;    #  both\positive\negative

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM( 'set_filter_profile', 'mode' => $mode );
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

	#	my $str = join( "\\;", @{ $self->{"featureIndexes"} } );
	#
	#	my $inCAM = $self->{"inCAM"};
	#
	#	$inCAM->COM(
	#		"adv_filter_set",
	#		"filter_name" => "popup",
	#		"active"      => "yes",
	#		"indexes"     => $str,
	#
	#	);

}

# Set logic between include attributes
sub SetIncludeAttrCond {
	my $self = shift;
	my $cond = shift; #FilterEnums->Logic_OR, FilterEnums->Logic_AND

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM( "set_filter_and_or_logic", "filter_name" => "popup", "criteria" => "inc_attr", "logic" => $cond );
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

