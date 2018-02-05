
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputResult;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"sourceLayer"} = shift;
	$self->{"result"}      = shift;
	$self->{"clasResults"} = shift;

	return $self;
}

sub GetResult {
	my $self = shift;

	return $self->{"result"};
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetClassResult {
	my $self       = shift;
	my $classType  = shift;
	my $succedOnly = shift;

	my @res = grep { $_->GetType() eq $classType && $_ } @{ $self->{"clasResults"} };

	if ($succedOnly) {

		@res = grep { $_->Result() } @res;
	}

	return $res[0];
}

sub GetClassResults {
	my $self       = shift;
	my $succedOnly = shift;

	my @res = @{ $self->{"clasResults"} };

	if ($succedOnly) {

		@res = grep { $_->Result() } @res;
	}

	return @res;
}

sub GetSourceLayer {
	my $self = shift;

	return $self->{"sourceLayer"};

}

# Merge all layers in each class result
sub MergeLayers {
	my $self  = shift;
	
	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetNumUID();
	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );

	foreach my $classResult ( $self->GetClassResults() ) {

		foreach my $l ( $classResult->GetLayers() ) {

			$inCAM->COM( "merge_layers", "source_layer" => $l->GetLayerName(), "dest_layer" => $lName );
		}
	}

	return $lName;
}


sub Clear{
	my $self  = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetNumUID();
	 
	foreach my $classResult ( $self->GetClassResults() ) {
		
		$classResult->Clear();
 
	}
	
	return $lName;
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
