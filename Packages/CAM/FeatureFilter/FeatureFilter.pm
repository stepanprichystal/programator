
#-------------------------------------------------------------------------------------------#
# Description:  Object oriented feature filter from InCAM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::FeatureFilter::FeatureFilter;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"layerName"} = shift;
	
	 
	$self->{"includeSym"} = undef;# Included symbols
	$self->{"excludeSym"} = undef; # Excluded symbols
	
	$self->{"includeAttr"} = undef;# Included attributes name + value
	$self->{"excludeAttr"} = undef; # Included attributes name + value
	

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
	my $self  = shift;
	my $text = shift;
 
	my $inCAM = $self->{"inCAM"};

	$inCAM->COM(
				 'set_filter_text',
				 'filter_name'  => "",
				 'text' => $text
	);

}

sub AddIncludeSymbols {
	my $self     = shift;
 	my @symbols = @{shift(@_)};
 	
 	push(@{$self->{"includeSym"}}, @symbols);	
	my $symbolStr = join("\\;", @{$self->{"includeSym"}});
	
 	my $inCAM = $self->{"inCAM"};

	$inCAM->COM( "set_filter_symbols", "filter_name" => "",  "symbols" => $symbolStr );

}

sub AddExcludeSymbols {
	my $self     = shift;
 	my @symbols = @{shift(@_)};
 	
 	push(@{$self->{"excludeSym"}}, @symbols);	
	my $symbolStr = join("\\;", @{$self->{"excludeSym"}});
	
 	my $inCAM = $self->{"inCAM"};
	
	$inCAM->COM( "set_filter_symbols", "filter_name" => "", "exclude_symbols" => $symbolStr );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	
	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";
	
	my $f = FeatureFilter->new($inCAM, "m");
	
	$f->SetPolarity("positive");
	
	my @types = ("surface", "pad");
	$f->SetTypes(\@types);
	
	my @syms = ("r500", "r1");
	$f->AddIncludeSymbols(  \["r500", "r1"] );
	
	print $f->Select();
	
	print "fff";
	
	
}

1;

