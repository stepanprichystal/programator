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
use aliased 'Packages::CAM::FeatureFilter::FilterPropStd';
use aliased 'Packages::CAM::FeatureFilter::FilterPropRef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	# Property of standard filter

	my $layer  = shift;
	my $layers = shift;    # array of layer names, in case of more layers we want to filter

	$self->{"layers"} = [];

	push( @{ $self->{"layers"} }, $layer )     if ( defined $layer );
	push( @{ $self->{"layers"} }, @{$layers} ) if ( defined $layers );

	die "No layer defined" unless ( @{ $self->{"layers"} } );

	$self->{"stdFilter"} = FilterPropStd->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"layers"} );
	$self->{"refFilter"} = FilterPropRef->new( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"inCAM"}->COM('adv_filter_reset');
	$self->{"inCAM"}->COM( 'filter_reset', filter_name => 'popup' );

	if ( scalar( @{ $self->{"layers"} } ) == 1 ) {
		CamLayer->WorkLayer( $self->{"inCAM"}, $self->{"layers"}->[0] );
	}
	else {
		CamLayer->AffectLayers( $self->{"inCAM"}, $self->{"layers"} );
	}

	return $self;
}

sub Select {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	# Build standard filter property
	my $buildStd = $self->{"stdFilter"}->BuildAll();
	my $buildRef = $self->{"refFilter"}->BuildAll();

	# if filter indexes are set, do select in loop (max 20 index in one loop)
	# Reason: cmd adv_filter_set, is posiible process only 200chars in parameter "indexes"
	if ( $self->{"stdFilter"}->GetFeatureIndexes() ) {

		my @ids = $self->{"stdFilter"}->GetFeatureIndexes();

		my $loopCnt = 20;

		while ( scalar(@ids) ) {

			# each loop select max 20 features
			my @idsPart = splice @ids, 0, ( scalar(@ids) < $loopCnt ? scalar(@ids) : $loopCnt );

			my $str = join( "\\;", @idsPart );
			$inCAM->COM(
						 "adv_filter_set",
						 "filter_name" => "popup",
						 "active"      => "yes",
						 "indexes"     => $str,
			);

			$self->__Select( $buildStd, $buildRef );
		}
	}
	else {

		$self->__Select( $buildStd, $buildRef );

	}

	$self->{"inCAM"}->COM('get_select_count');

	return $self->{"inCAM"}->GetReply();

}

sub Reset {
	my $self = shift;

	if ( scalar( @{ $self->{"layers"} } ) == 1 ) {
		CamLayer->WorkLayer( $self->{"inCAM"}, $self->{"layers"}->[0] );
	}
	else {
		CamLayer->AffectLayers( $self->{"inCAM"}, $self->{"layers"} );
	}

	# reset stored filter property
	$self->{"stdFilter"}->Reset();
	$self->{"refFilter"}->Reset();

	# reset InCAM feature filter
	$self->{"inCAM"}->COM('adv_filter_reset');
	$self->{"inCAM"}->COM( 'filter_reset', filter_name => 'popup' );

}

sub Unselect {
	my $self = shift;

	die "Not implemented";
}

sub __Select {
	my $self     = shift;
	my $buildStd = shift;
	my $buildRef = shift;

	my $inCAM = $self->{"inCAM"};

	# Select features with standard filter
	if ( $buildStd && !$buildRef ) {

		$inCAM->COM('filter_area_strt');
		$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
	}

	# Select features with reference filter
	elsif ( $buildStd && $buildRef ) {

		# Prepare refereance filter properties

		$inCAM->COM(
					 'sel_ref_feat',
					 'layers'       => $self->{"refFilter"}->BuildRefLayer(),
					 'use'          => 'filter',
					 'mode'         => $self->{"refFilter"}->BuildReferenceMode(),
					 'pads_as'      => 'shape',
					 'f_types'      => $self->{"refFilter"}->BuildFeatTypes(),
					 'polarity'     => $self->{"refFilter"}->BuildPolarity(),
					 "include_syms" => $self->{"refFilter"}->BuildIncludeSym(),
					 "exclude_syms" => $self->{"refFilter"}->BuildExcludeSym()
		);
	}
	else {

		die "Filter properties was not built";
	}

}

# ---------------------------------------------------------------------------------------
# Set properties for STANDARD filter
# ---------------------------------------------------------------------------------------

# Filter by feature types. Options:
# - "lines"    => 0/1,
# - "pads"     => 0/1,
# - "surfaces" => 0/1,
# - "arcs"     => 0/1,
# - "text"     => 0/1,
sub SetFeatureTypes {
	my $self    = shift;
	my @options = @_;      # pairs: key + value

	$self->{"stdFilter"}->SetFeatureTypes(@options);
}

# Filter by polarity
# - Polarity_POSITIVE  - postivice
# - Polarity_NEGATIVE - negative
# - Polarity_BOTH positive and negative
sub SetPolarity {
	my $self     = shift;
	my $polarity = shift;

	$self->{"stdFilter"}->SetPolarity($polarity);
}

# Filter by feature symbols
sub AddIncludeSymbols {
	my $self    = shift;
	my $symbols = shift;    # array ref of symbols

	$self->{"stdFilter"}->AddIncludeSymbols($symbols);
}

# Exclude symbols from filter
sub AddExcludeSymbols {
	my $self    = shift;
	my $symbols = shift;    # array ref of symbols

	$self->{"stdFilter"}->AddExcludeSymbols($symbols);
}

# Include attribute and att value to filter
sub AddIncludeAtt {
	my $self     = shift;
	my $attName  = shift;    # attribute name
	my $attValue = shift;    # attribut value. Type according InCAM attribute type, undef is allowed

	$self->{"stdFilter"}->AddIncludeAtt( $attName, $attValue );
}

# Exclude attribute and att value to filter
sub AddExcludeAtt {
	my $self     = shift;
	my $attName  = shift;    # attribute name
	my $attValue = shift;    # attribut value. Type according InCAM attribute type, undef is allowed

	$self->{"stdFilter"}->AddExcludeAtt( $attName, $attValue );
}

# Set logic between include attributes
# - Enums->Logic_AND
# - Enums->Logic_OR
sub SetIncludeAttrCond {
	my $self = shift;
	my $cond = shift;

	$self->{"stdFilter"}->SetIncludeAttrCond($cond);
}

# Set logic between include attributes
# - Enums->Logic_AND
# - Enums->Logic_OR
sub SetExcludeAttrCond {
	my $self = shift;
	my $cond = shift;

	$self->{"stdFilter"}->SetExcludeAttrCond($cond);
}

# Filter according profile
# Mode:
# - Enums->ProfileMode_IGNORE (0)
# - Enums->ProfileMode_INSIDE (1)
# - Enums->ProfileMode_OUTSIDE (2)
sub SetProfile {
	my $self = shift;
	my $mode = shift;

	$self->{"stdFilter"}->SetProfile($mode);
}

# Filter by specific text or expression
sub SetText {
	my $self = shift;
	my $text = shift;

	$self->{"stdFilter"}->SetText($text);
}

# Filter lline length
sub SetLineLength {
	my $self      = shift;
	my $minLength = shift;    # in mm
	my $maxLength = shift;    # in mm

	$self->{"stdFilter"}->SetLineLength( $minLength, $maxLength );
}

# Filter by feature indexes
sub AddFeatureIndexes {
	my $self    = shift;
	my $indexes = shift;      # array ref of indexes

	$self->{"stdFilter"}->AddFeatureIndexes($indexes);
}

# ---------------------------------------------------------------------------------------
# Set properties for REFERENCE filter
# ---------------------------------------------------------------------------------------

# Activate reference filter by set one reference layer
sub SetRefLayer {
	my $self  = shift;
	my $layer = shift;    # reference layer

	$self->{"refFilter"}->SetRefLayer($layer);
}

# Activate reference filter by set more reference layers
sub SetRefLayers {
	my $self   = shift;
	my $layers = shift;    # array of reference layers

	$self->{"refFilter"}->SetRefLayers($layers);
}

# Reference filter
# Filter by feature types. Options:
# - "lines"    => 0/1,
# - "pads"     => 0/1,
# - "surfaces" => 0/1,
# - "arcs"     => 0/1,
# - "text"     => 0/1,
sub SetFeatureTypesRef {
	my $self    = shift;
	my @options = @_;      # pairs: key + value

	die "Reference filter is not active. First set reference layer" unless ( $self->{"refFilter"}->IsActive() );

	$self->{"refFilter"}->SetFeatureTypes(@options);
}

# Reference filter
# Filter by polarity
# - Polarity_POSITIVE  - postivice
# - Polarity_NEGATIVE - negative
# - Polarity_BOTH positive and negative
sub SetPolarityRef {
	my $self     = shift;
	my $polarity = shift;

	die "Reference filter is not active. First set reference layer" unless ( $self->{"refFilter"}->IsActive() );

	$self->{"refFilter"}->SetPolarity($polarity);
}

# Reference filter
# Filter by feature symbols
sub AddIncludeSymbolsRef {
	my $self    = shift;
	my $symbols = shift;    # array ref of symbols

	die "Reference filter is not active. First set reference layer" unless ( $self->{"refFilter"}->IsActive() );

	$self->{"refFilter"}->AddIncludeSymbols($symbols);
}

# Reference filter
# Exclude symbols from filter
sub AddExcludeSymbolsRef {
	my $self    = shift;
	my $symbols = shift;    # array ref of symbols

	die "Reference filter is not active. First set reference layer" unless ( $self->{"refFilter"}->IsActive() );

	$self->{"refFilter"}->AddExcludeSymbols($symbols);
}

# Reference filter
# include attribute and att value to filter
sub AddIncludeAttRef {
	my $self     = shift;
	my $attName  = shift;    # attribute name
	my $attValue = shift;    # attribut value

	die "Reference filter is not active. First set reference layer" unless ( $self->{"refFilter"}->IsActive() );

	$self->{"refFilter"}->AddIncludeAtt( $attName, $attValue );
}

# Reference filter
# Set logic between include attributes
# - Enums->Logic_AND
# - Enums->Logic_OR
sub SetIncludeAttrCondRef {
	my $self = shift;
	my $cond = shift;

	die "Reference filter is not active. First set reference layer" unless ( $self->{"refFilter"}->IsActive() );

	$self->{"refFilter"}->SetIncludeAttrCond($cond);
}

# Reference filter
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

	die "Reference filter is not active. First set reference layer" unless ( $self->{"refFilter"}->IsActive() );

	$self->{"refFilter"}->SetReferenceMode($mode);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113608";

	my $f = FeatureFilter->new( $inCAM, $jobId, "c" );

	#my %num = ( "min" => 1100 / 1000 / 25.4, "max" => 1100 / 1000 / 25.4 );
	#$f->AddIncludeAtt( ".rout_tool", \%num );

	#$f->AddFeatureIndexes( [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 ] );
	# - "lines"    => 0/1,
	# - "pads"     => 0/1,
	# - "surfaces" => 0/1,
	# - "arcs"     => 0/1,
	# - "text"     => 0/1,
	$f->SetFeatureTypes( "line" => 1 );

	$f->SetPolarity( Enums->Polarity_BOTH );

	#$f->AddIncludeSymbols( ["r254", "r500"]);
	#$f->AddExcludeSymbols( ["r254", "r500"]);

	#my %num = ( "min" => 1100 / 1000 / 25.4, "max" => 3000 / 1000 / 25.4 );
	#$f->AddExcludeAtt(".smd");
	#$f->AddExcludeAtt(".gold_plating");
	#$f->SetExcludeAttrCond(Enums->Logic_OR);

	#$f->SetFeatTypes( "text" => 1 );
	#$f->SetText("*Drill*");

	##d$f->SetLineLength(2,10);
	#$f->AddFeatureIndexes( [ 440, 441 ] );

	$f->SetRefLayer("pom2");
	#$f->SetFeatureTypesRef( "line" => 1, "surface" => 1 );
	#$f->SetPolarityRef( Enums->Polarity_POSITIVE );
	#$f->AddIncludeSymbolsRef( ["r254", "r500"]);
	#$f->AddIncludeAttRef(".nomenclature");
	#$f->AddIncludeAttRef(".smd");
	$f->SetIncludeAttrCondRef(Enums->Logic_AND);
	$f->SetReferenceMode(Enums->RefMode_DISJOINT);
	
	
	
	print $f->Select();

	print "fff";
	
#	sel_ref_feat,layers=pom2,use=filter,mode=touch,pads_as=shape,f_types=surface,pol
#arity=positive\;negative,include_syms=,exclude_syms= (0)

}

1;

