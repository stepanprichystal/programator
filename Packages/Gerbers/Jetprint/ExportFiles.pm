
#-------------------------------------------------------------------------------------------#
# Description: Export data for Jetprint, gerbers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Jetprint::ExportFiles;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';

use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FilterEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'CamHelpers::CamStep';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::Jetprint::Enums';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::Gerbers::Export::ExportLayers';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	my $specFiduc = shift; # set, only if special fiduc marks

	$self->{"step"} = "panel";

	# Info about  pcb ===========================

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	# Get limits of fr, profile ===============

	my %frLim = $self->__GetFrLimits();
	$self->{"frLim"} = \%frLim;

	my %profLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	$self->{"profLim"} = \%profLim;

	# Other properties ========================

	$self->{"jetprintStep"} = "jetprint_panel";

	# set default fiducials
	if ( defined $specFiduc ) {

		$self->{"fiducials"} = $specFiduc;

	}
	else {
		# neplat or 1vv
		if ( $self->{"layerCnt"} == 1 ) {

			$self->{"fiducials"} = Enums->Fiducials_HOLE3P2;
		}
		else {

			$self->{"fiducials"} = Enums->Fiducials_SUN;
		}
	}

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# delete old jetprint files
	$self->__DeleteOldFiles();

	# Get all layer for export

	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	@layers = grep { $_->{"gROWname"} =~ /^p[cs]$/i } @layers;

	$self->__CreateJetprintStep();
	$self->__ExportLayers( \@layers );
	$self->__DeleteJetprintStep();

	return 1;
}

sub __ExportLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l (@layers) {

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );

		# new result item for lyer
		my $resultItem = $self->_GetNewItem( $l->{"gROWname"} );

		# get limits (define physic dimension) for layer
		my %lim = $self->__GetLayerLimit( $l->{"gROWname"} );

		# 1) Delete useless features
		$self->__DeleteFeatures( $l->{"gROWname"} );

		# 4) compensate "shrink" because paint is little "spilled" after print
		$self->__CompensateLayer( $l->{"gROWname"} );

		# 2) insert frame 100µm width around pcb (fr frame coordinate)
		$self->__PutFrameAorundPcb( $l->{"gROWname"}, \%lim );

		# 5) prepare fiducials
		$self->__PrepareFiducials( $l->{"gROWname"} );

		# 6) move data to zero point
		$self->__MoveToZero( $l->{"gROWname"} );

		# 5) export gerbers
		my $fiducDCode = $self->__ExportGerberLayer( $l->{"gROWname"}, $resultItem );

		#  reise result of export
		$self->_OnItemResult($resultItem);
	}
}

# Delete old gerber + xml files
sub __DeleteOldFiles {
	my $self       = shift;
	my $layerTypes = shift;

	my $jobId = $self->{"jobId"};

	my @ger = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_JETPRINT, $jobId . 'p[cs]_jet\.ger' );
	my @jdl = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_JETPRINT, $jobId . 'p[cs]_jet\.ger.jdl' );

	foreach ( ( @ger, @jdl ) ) {
		unless ( unlink($_) ) {
			die "Can not delete jetprint file $_.\n";
		}
	}
}

# Get limits, by phisic dimension of pcb
sub __GetLayerLimit {
	my $self      = shift;
	my $layerName = shift;

	# 0) Get limits by layer type

	my %lim = ();

	# if top/bot layer, clip around fr frame
	if ( $self->{"layerCnt"} > 2 && ( $layerName =~ /^[(gold)(plg)m]*[cs]$/ ) ) {

		%lim = %{ $self->{"frLim"} };
	}

	#if inner layers, clip around profile
	elsif ( $layerName =~ /^v\d$/ ) {

		%lim = %{ $self->{"profLim"} };

	}
	else {

		%lim = %{ $self->{"profLim"} };
	}

	return %lim;
}

sub __GetFrLimits {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %lim = ();

	if ( CamHelper->LayerExists( $inCAM, $jobId, "fr" ) ) {

		CamHelper->SetStep( $inCAM, $self->{"step"} );

		# compensate layer, because in genesis Fr has righ compensation, but in incam left comp... Thus coordinate of fr are different
		my $lName = CamLayer->RoutCompensation( $inCAM, "fr", "document" );

		my $route = Features->new();
		$route->Parse( $inCAM, $jobId, $self->{"step"}, $lName );
		my @features = $route->GetFeatures();
		%lim = PolygonFeatures->GetLimByRectangle( \@features );

		# fr width is 2mm, reduce limits by 1mm from each side
		$lim{"xMin"} = $lim{"xMin"} + 1;
		$lim{"xMax"} = $lim{"xMax"} - 1;
		$lim{"yMin"} = $lim{"yMin"} + 1;
		$lim{"yMax"} = $lim{"yMax"} - 1;

		$inCAM->COM( 'delete_layer', layer => $lName );
	}

	return %lim;

}

sub __ExportGerberLayer {
	my $self          = shift;
	my $layerName     = shift;
	my $resultItemGer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tmpFileId = GeneralHelper->GetGUID();

	# function, which build output layer name
	my $suffixFunc = sub {

		my $layerName = shift;
		return $tmpFileId;
	};

	#my $resultItemGer = ItemResult->new("Output layers");

	# init layer
	my %l = ( "name" => $layerName, "mirror" => $layerName eq "ps" ? 1 : 0 );
	my @layers = ( \%l );

	# 1 ) Export gerber to temp directory

	ExportLayers->ExportLayers( $resultItemGer, $inCAM, $self->{"jetprintStep"},
								\@layers, EnumsPaths->Client_INCAMTMPOTHER,
								"", $suffixFunc, undef, undef );
	my $tmpFullPath = EnumsPaths->Client_INCAMTMPOTHER . $layerName . $tmpFileId;

	# 3) Copy file to jetprint folder
	my $finalName = EnumsPaths->Jobs_JETPRINT . $jobId . $layerName . "_jet.ger";
	copy( $tmpFullPath, $finalName ) or die "Unable to copy jetprint gerber file from: $tmpFullPath.\n";

	unlink($tmpFullPath);

}

sub __DeleteFeatures {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $f = FeatureFilter->new( $inCAM, $jobId, $layerName );

	$f->AddIncludeAtt( ".pnl_place", "PCBF_*" );
	$f->AddIncludeAtt( ".pnl_place", "M-IN*" );
	$f->AddIncludeAtt( ".pnl_place", "T-User*" );
	$f->AddIncludeAtt( ".pnl_place", "T-Time*" );
	$f->AddIncludeAtt( ".pnl_place", "T-Date*" );
	$f->AddIncludeAtt( ".pnl_place", "T-Day*" );
	$f->SetIncludeAttrCond( FilterEnums->Logic_OR );

	# delete standard fiducials
	if ( $self->{"fiducials"} ne Enums->Fiducials_SUN ) {

		$f->AddIncludeAtt( ".pnl_place", "SF-*" );
	}

	if ( $f->Select() ) {
		$inCAM->COM("sel_delete");
	}
	else {
		die "No useless feastures to delete in silkscreen. Perhaps old schema in panel step\n";
	}

}

# Compensate layer by compensation
sub __CompensateLayer {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $class = $self->{"pcbClass"};

	my $comp = -60;    # shring by 60µm

	if ( $comp != 0 ) {
		CamLayer->CompensateLayerData( $inCAM, $layerName, $comp );
	}

}

# Frame define border of data for pcb layer
# border must be size like physic pcb
sub __PutFrameAorundPcb {
	my $self      = shift;
	my $layerName = shift;
	my %lim       = %{ shift(@_) };

	my @coord = ();

	my %p1 = ( "x" => $lim{"xMin"}, "y" => $lim{"yMin"} );
	my %p2 = ( "x" => $lim{"xMin"}, "y" => $lim{"yMax"} );
	my %p3 = ( "x" => $lim{"xMax"}, "y" => $lim{"yMax"} );
	my %p4 = ( "x" => $lim{"xMax"}, "y" => $lim{"yMin"} );
	push( @coord, \%p1 );
	push( @coord, \%p2 );
	push( @coord, \%p3 );
	push( @coord, \%p4 );

	# frame 100µm width around pcb (fr frame coordinate)
	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r100", "positive" );
}

# if non standard "sun" fiducailas, prepare them
sub __PrepareFiducials {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# hole 3.2 mm
	if ( $self->{"fiducials"} eq Enums->Fiducials_HOLE3P2 ) {

		# put 100µm symbols on 3.2mm hole position in "m" layer
		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $self->{"step"}, "m" );
		my @holes3p2 = grep { $_->{"type"} eq "P" && $_->{"att"}->{".pnl_place"} =~ /^M-IN-(.*)-c$/ } $f->GetFeatures();

		# add point
		CamLayer->WorkLayer( $inCAM, $layerName );

		foreach my $hole (@holes3p2) {

			my %pos = ( "x" => $hole->{"x1"}, "y" => $hole->{"y1"} );

			CamSymbol->AddPad( $inCAM, "r100", \%pos );
		}
	}

}

# if layer is multilayer, move data to zero point
sub __MoveToZero {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};

	if ( $self->{"layerCnt"} > 2 ) {

		$inCAM->COM( "sel_move", "dx" => -$self->{"frLim"}->{"xMin"}, "dy" => -$self->{"frLim"}->{"yMin"} );
	}
}

# Create special step, which IPC will be exported from
sub __CreateJetprintStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"jetprintStep"} );

	CamHelper->SetStep( $inCAM, $self->{"jetprintStep"} );
}

# delete pdf step
sub __DeleteJetprintStep {
	my $self = shift;
	my $step = $self->{"jetprintStep"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $step ) ) {

		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $step, "type" => "step" );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::Jetprint::ExportFiles';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "f52457";
	my $stepName = "panel";

	my $export = ExportFiles->new( $inCAM, $jobId );

	$export->Run();

}

1;

