
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
use List::MoreUtils qw(uniq);
use List::Util qw(first);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
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
use aliased 'Packages::ItemResult::Enums' => 'ItemResEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';
use aliased 'Packages::Gerbers::Jetprint::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;
	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"fiducials"} = shift;    # set, only if special fiduc marks
	$self->{"rotation"}  = shift;    # rotation data 90°°if panel is too height

	$self->{"step"} = "panel";

	# Info about  pcb ===========================

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	# Get limits of fr, profile ===============

	my %frLim = $self->__GetFrLimits();
	$self->{"frLim"} = \%frLim;

	my %profLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	$self->{"profLim"} = \%profLim;

	# silkscreen layers for export

	my @l = grep { $_->{"gROWname"} =~ /^p[cs]2?$/i } CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"layers"} = \@l;

	# Other properties ========================

	$self->{"jetprintStep"} = "jetprint_panel";

	# Default fiducials

	if ( !defined $self->{"fiducials"} ) {

		$self->{"fiducials"} = Helper->GetDefaultFiduc( $self->{"inCAM"}, $self->{"jobId"} );
	}

	# Default rotation
	if ( !defined $self->{"rotation"} ) {
		
		$self->{"rotation"} = Helper->GetDefaultRotation( $self->{"inCAM"}, $self->{"jobId"} );
	}

	# Prinitng frame. If PCB is flexible 1-2v, we use special printing frame
	# This frame is wider and longer than Flex panel. 10mm in all sides
	my $pcbType = JobHelper->GetPcbType( $self->{"jobId"} );

	$self->{"printFrm"} = 0;

	if (    $pcbType eq EnumsGeneral->PcbType_1VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_2VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_MULTIFLEX )
	{

		$self->{"printFrm"} = 10;
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

	$self->__CreateJetprintStep();
	$self->__ExportLayers();
	$self->__DeleteJetprintStep();

	return 1;
}

sub __ExportLayers {
	my $self = shift;

	my @layers = @{ $self->{"layers"} };

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
		$self->__CompensateLayer( $l->{"gROWname"}, $resultItem );

		# 2) insert frame 100µm width around pcb (fr frame coordinate)
		$self->__PutFrameAorundPcb( $l->{"gROWname"}, \%lim );

		# 5) prepare fiducials
		$self->__PrepareFiducials( $l->{"gROWname"} );

		# 6) move data to zero point
		$self->__MoveToZero( $l->{"gROWname"} );

		# 7) rotate layer
		$self->__RotateLayer( $l->{"gROWname"}, \%lim );

		# 8) mirror layer in y axis if ps
		$self->__MirrorLayer( $l->{"gROWname"}, \%lim );

		# 9) export gerbers
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

	my @ger = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_JETPRINT, $jobId . 'p[cs]2?_jet\.ger' );
	my @jdl = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_JETPRINT, $jobId . 'p[cs]2?_jet\.ger.jdl' );

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

	if ( $self->{"layerCnt"} > 2 ) {

		%lim = %{ $self->{"frLim"} };
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

	# Export only if no errors
	if ( $resultItemGer->Result() eq ItemResEnums->ItemResult_Fail ) {
		return 0;
	}

	my $tmpFileId = GeneralHelper->GetGUID();

	# function, which build output layer name
	my $suffixFunc = sub {

		my $layerName = shift;
		return $tmpFileId;
	};

	#my $resultItemGer = ItemResult->new("Output layers");

	# init layer
	my %l = ( "name" => $layerName, "mirror" => 0 );
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
	$f->AddIncludeAtt( ".pnl_place", "M-*" );
	$f->AddIncludeAtt( ".pnl_place", "T-User*" );
	$f->AddIncludeAtt( ".pnl_place", "T-Time*" );
	$f->AddIncludeAtt( ".pnl_place", "T-Date*" );
	$f->AddIncludeAtt( ".pnl_place", "T-Day*" );
	$f->SetIncludeAttrCond( FilterEnums->Logic_OR );

	# delete standard fiducials
	if ( $self->{"fiducials"} ne Enums->Fiducials_SUN5 ) {

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
	my $self          = shift;
	my $layerName     = shift;
	my $resultItemGer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1 ) check if thera are features thinner than 120µm (necessary because after compensation -60µm result print on pcb should be wrong)
	my @wrongFeat = ();
	unless ( SilkScreenCheck->FeatsWidthOk( $inCAM, $jobId, $self->{"step"}, $layerName, \@wrongFeat ) ) {

		my $str = join( ", ", @wrongFeat );

		die "Too thin features ($str) in silkscreen layer \"$layerName\". Min thickness of feature is 130µm";
	}

	# 2) Compensate all features
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

	my %p1 = ( "x" => $lim{"xMin"} - $self->{"printFrm"}, "y" => $lim{"yMin"} - $self->{"printFrm"} );
	my %p2 = ( "x" => $lim{"xMin"} - $self->{"printFrm"}, "y" => $lim{"yMax"} + $self->{"printFrm"} );
	my %p3 = ( "x" => $lim{"xMax"} + $self->{"printFrm"}, "y" => $lim{"yMax"} + $self->{"printFrm"} );
	my %p4 = ( "x" => $lim{"xMax"} + $self->{"printFrm"}, "y" => $lim{"yMin"} - $self->{"printFrm"} );
	push( @coord, \%p1 );
	push( @coord, \%p2 );
	push( @coord, \%p3 );
	push( @coord, \%p4 );

	# frame 100µm width around pcb (fr frame coordinate)
	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r100", "positive", 1 );
}

# if non standard "sun" fiducailas, prepare them
sub __PrepareFiducials {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# hole 3.2 mm
	if ( $self->{"fiducials"} eq Enums->Fiducials_HOLE3 ) {

		# put 100µm symbols on 3.2mm hole position in "m" layer
		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $self->{"step"}, "v" );
		my @holes3p2 = grep { $_->{"type"} eq "P" && $_->{"att"}->{".geometry"} =~ /^OLEC_otvor/i } $f->GetFeatures();

		# select only 3 fiduc (2x bot and lright top)
		my @fiduc = ();
		my $LB = first {$_->{"att"}->{".pnl_place"} =~ /left.?bot/i} @holes3p2;
		my $RB = first {$_->{"att"}->{".pnl_place"} =~ /right.?bot/i} @holes3p2;
		my $RT = first {$_->{"att"}->{".pnl_place"} =~ /right.?top/i} @holes3p2;
		push(@fiduc, $LB) if($LB);
		push(@fiduc, $RB) if($RB);
		push(@fiduc, $RT) if($RT);
		
		die "No OLEC fiducial holes 3mm was found in layer \"v\"" unless ( scalar(@fiduc) );

		
		# add point
		CamLayer->WorkLayer( $inCAM, $layerName );

		foreach my $hole (@fiduc) {

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

		$inCAM->COM(
					 "sel_move",
					 "dx" => -$self->{"frLim"}->{"xMin"} + $self->{"printFrm"},
					 "dy" => -$self->{"frLim"}->{"yMin"} + $self->{"printFrm"}
		);
	}
	else {
		$inCAM->COM(
					 "sel_move",
					 "dx" => $self->{"printFrm"},
					 "dy" => $self->{"printFrm"}
		);

	}

}

# Rotate layer 90 degree cw and move to zero
sub __RotateLayer {
	my $self      = shift;
	my $layerName = shift;
	my $lim       = shift;

	my $inCAM = $self->{"inCAM"};

	if ( $self->{"rotation"} ) {

		CamLayer->RotateLayerData( $inCAM, $layerName, 90, 0 );
		$inCAM->COM( "sel_move", "dx" => 0, "dy" => abs( $lim->{"xMax"} - $lim->{"xMin"} ) + 2 * $self->{"printFrm"} );
	}
}

# if layer is multilayer, move data to zero point
sub __MirrorLayer {
	my $self      = shift;
	my $layerName = shift;
	my $lim       = shift;

	my $inCAM = $self->{"inCAM"};

	if ( $layerName eq "ps" ) {

		CamLayer->MirrorLayerData( $inCAM, $layerName, "y" );

		if ( $self->{"rotation"} ) {

			$inCAM->COM( "sel_move", "dx" => abs( $lim->{"yMax"} - $lim->{"yMin"} ) + 2 * $self->{"printFrm"}, "dy" => 0 );

		}
		else {

			$inCAM->COM( "sel_move", "dx" => abs( $lim->{"xMax"} - $lim->{"xMin"} ) + 2 * $self->{"printFrm"}, "dy" => 0 );

		}

	}
}

# Create special step, which IPC will be exported from
sub __CreateJetprintStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @silkL = map { $_->{"gROWname"} } @{ $self->{"layers"} };

	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"jetprintStep"}, 0, \@silkL );

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

	my $jobId    = "d293788";
	my $stepName = "panel";

	my $export = ExportFiles->new( $inCAM, $jobId, undef, undef );

	$export->Run();

}

1;

