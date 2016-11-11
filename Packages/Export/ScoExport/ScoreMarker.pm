
#-------------------------------------------------------------------------------------------#
# Description: Put control lines to layers, which which osition is score on
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ScoExport::ScoreMarker;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"scoreChecker"} = shift;
	$self->{"frLim"}        = shift;

	$self->{"step"} = "panel";

	#define length of control line

	if ( $self->{"frLim"} ) {

		$self->{"lenV"} = 14;
		$self->{"lenH"} = 14;
	}
	else {

		$self->{"lenV"} = 14;
		$self->{"lenH"} = 14;
	}

	# define limits of panel

	# get information about panel dimension
	my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	$self->{"xMin"} = 0;
	$self->{"xMax"} = abs( $lim{"xmax"} - $lim{"xmin"} );
	$self->{"yMin"} = 0;
	$self->{"yMax"} = abs( $lim{"ymax"} - $lim{"ymin"} );

	if ( $self->{"frLim"} ) {

		$self->{"width"}  = abs( $self->{"frLim"}->{"xMax"} - $self->{"frLim"}->{"xMin"} );
		$self->{"height"} = abs( $self->{"frLim"}->{"yMax"} - $self->{"frLim"}->{"yMin"} );

		$self->{"xMin"} = $self->{"frLim"}->{"xMin"};
		$self->{"xMax"} = $self->{"frLim"}->{"xMax"};
		$self->{"yMin"} = $self->{"frLim"}->{"yMin"};
		$self->{"yMax"} = $self->{"frLim"}->{"yMax"};
	}

	return $self;
}

sub Run {
	my $self = shift;
	
	my $inCAM  = $self->{"inCAM"};

	my @points = $self->__GetPoints();
	$self->__DrawPoints( \@points );
	
	$inCAM->COM("clear_layers");
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );

}

sub __DrawPoints {
	my $self   = shift;
	my @points = @{ shift(@_) };
	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};

	# Create layer for liones, set attribute
	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );
	CamLayer->WorkLayer( $inCAM, $lName );

	foreach my $point (@points) {

		my %startP = %{ $point->{"point"} };
		my %endP;

		if ( $point->{"dir"} eq ScoEnums->Dir_HSCORE ) {

			$endP{"x"} = $startP{"x"} + $self->{"lenH"};
			$endP{"y"} = $startP{"y"};

		}
		elsif ( $point->{"dir"} eq ScoEnums->Dir_VSCORE ) {

			$endP{"x"} = $startP{"x"};
			$endP{"y"} = $startP{"y"} - $self->{"lenV"};
		}

		$inCAM->COM(
					 'add_line',
					 attributes => 'no',
					 xs         => $startP{"x"},
					 ys         => $startP{"y"},
					 xe         => $endP{"x"},
					 ye         => $endP{"y"},
					 "symbol"   => "r200"
		);

	}

	CamAttributes->SetFeatuesAttribute( $inCAM, "control_score_lines", "" );

	#copy to other layer
	# merge layer to final output layer
	my @layers = ( "mc", "c", "s", "ms" );

	foreach my $l (@layers) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {

			#delete all old lines
			CamLayer->WorkLayer( $inCAM, $l );    # select tmp

			# select old frame and delete
			my $count = CamFilter->SelectBySingleAtt( $inCAM, "control_score_lines", "" );

			if ($count) {
				$inCAM->COM("sel_delete");
			}

			$inCAM->COM( "merge_layers", "source_layer" => $lName, "dest_layer" => $l );
		}
	}

	# Delete

	# delete rout temporary layer
	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {

		$inCAM->COM( 'delete_layer', "layer" => $lName );
	}
}

sub __GetPoints {
	my $self = shift;

	my $pcbPlace = $self->{"scoreChecker"}->GetPcbPlace();

	my @points = ();

	# horizontal mark lines
	my @hPos = $pcbPlace->GetScorePos( ScoEnums->Dir_HSCORE );

	foreach my $posInf (@hPos) {

		my %pointVL = ( "x" => $self->{"xMin"}, "y" => $posInf->GetPosition() / 1000 );
		my %pointVR = ( "x" => $self->{"xMax"} - $self->{"lenH"}, "y" => $posInf->GetPosition() / 1000 );

		my %pointL = ( "dir" => ScoEnums->Dir_HSCORE, "point" => \%pointVL );
		my %pointR = ( "dir" => ScoEnums->Dir_HSCORE, "point" => \%pointVR );

		push( @points, \%pointL );
		push( @points, \%pointR );
	}

	# vertical mark lines
	my @VPos = $pcbPlace->GetScorePos( ScoEnums->Dir_VSCORE );

	foreach my $posInf (@VPos) {

		my %pointVT = ( "x" => $posInf->GetPosition() / 1000, "y" => $self->{"yMax"} );
		my %pointVB = ( "x" => $posInf->GetPosition() / 1000, "y" => $self->{"yMin"} + $self->{"lenV"} );

		my %pointT = ( "dir" => ScoEnums->Dir_VSCORE, "point" => \%pointVT );
		my %pointB = ( "dir" => ScoEnums->Dir_VSCORE, "point" => \%pointVB );

		push( @points, \%pointT );
		push( @points, \%pointB );
	}

	return @points;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::PlotExport::PlotMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@layers) {
	#
	#		$l->{"polarity"} = "positive";
	#
	#		if ( $l->{"gROWname"} =~ /pc/ ) {
	#			$l->{"polarity"} = "negative";
	#		}
	#
	#		$l->{"mirror"} = 0;
	#		if ( $l->{"gROWname"} =~ /c/ ) {
	#			$l->{"mirror"} = 1;
	#		}
	#
	#		$l->{"compensation"} = 30;
	#		$l->{"name"}         = $l->{"gROWname"};
	#	}
	#
	#	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;
	#
	#	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	#	$mngr->Run();
}

1;

