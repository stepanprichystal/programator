
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputClassResult;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamMatrix';

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"type"}   = shift;
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"layer"} = shift;
	
	$self->{"layers"} = [];
	$self->{"result"} = 0;       # 0 - no layers was added, 1 - at least 1 layer was added

	return $self;
}

sub Result {
	my $self = shift;

	return $self->{"result"};
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}

# some classes has onlz one result layer
sub GetSingleLayer {
	my $self = shift;
	
	if(scalar(@{$self->{"layers"}})> 1){
		
		die "Class result contain multiple layer result"
	}
	
	

	return ${ $self->{"layers"} }[0];
}

sub AddLayer {
	my $self        = shift;
	my $outputLayer = shift;

	$self->{"result"} = 1;

	push( @{ $self->{"layers"} }, $outputLayer );

}

# Merge all layers in each OutputLayer class to one
sub MergeLayers {
	my $self  = shift;
	
	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetNumUID();
	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );

	foreach my $l ( $self->GetLayers() ) {

		$inCAM->COM( "merge_layers", "source_layer" => $l->GetLayerName(), "dest_layer" => $lName );
	}
	
	return $lName;
}

sub Clear{
	my $self  = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l ( $self->GetLayers() ) {
		
		CamMatrix->DeleteLayer( $inCAM, $jobId, $l->GetLayerName() );
 
	}
	
	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
