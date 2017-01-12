
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Mdi::ExportFiles::ExportFiles;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';

#use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';

#use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
#use aliased 'Packages::Export::GerExport::Helper';

use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::PolygonHelper';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::Gerbers::Export::ExportLayers';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::Mdi::ExportFiles::FiducMark';
use aliased 'Packages::Mdi::ExportFiles::Enums';
use aliased 'Packages::Mdi::ExportFiles::ExportXml';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Technology::EtchOperation';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	# Info about  pcb ===========================

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"pcbClass"} = CamJob->GetJobPcbClass( $self->{"inCAM"}, $self->{"jobId"} );

	if ( $self->{"layerCnt"} > 2 ) {
		$self->{"stackup"} = Stackup->new( $self->{"jobId"} );
	}

	# Get limits of fr, profile ===============

	my @frLim = $self->__GetFrLimits();
	$self->{"frLim"} = \@frLim;

	my %profLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	$self->{"profLim"} = \%profLim;

	# Other properties ========================

	$self->{"mdiStep"} = "mdi_panel";

	$self->{"exportXml"} = ExportXml->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stackup"}, $self->{"profLim"} );

	return $self;
}

sub Run {
	my $self       = shift;
	my $layerTypes = shift;

	# delete old MDI files
	$self->__DeleteOldFiles($layerTypes);
	
	# Get all layer for export 
	my @layers = $self->__GetLayers2Export($layerTypes);

	unless ( scalar(@layers) ) {
		return 0;
	}

	$self->__CreateMDIStep();
	$self->__ExportLayers( \@layers );
	$self->__DeleteMdiStep();

	return 1;

}

sub __ExportLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l (@layers) {
		
		CamLayer->WorkLayer($inCAM, $l->{"gROWname"});

		# new result item for lyer
		my $resultItem = $self->_GetNewItem( $l->{"gROWname"} );

		# get limits (define physic dimension) for layer
		my %lim = $self->__GetLayerLimit( $l->{"gROWname"} );

		# 2) insert frame 100µm width around pcb (fr frame coordinate)
		$self->__PutFrameAorundPcb( $l->{"gROWname"}, \%lim );

		# 1) clip data by limits
		$self->__ClipAreaLayer( $l->{"gROWname"}, \%lim );

		# 3) compensate layer by computed compensation
		$self->__CompensateLayer( $l->{"gROWname"} );

		# 4) export gerbers
		my $fiducDCode = $self->__ExportGerberLayer( $l->{"gROWname"} );

		$self->{"exportXml"}->__ExportXmlLayer( $l, $fiducDCode );

		#  reise result of export
		$self->_OnItemResult($resultItem);
	}

}

sub __DeleteOldFiles {
	my $self       = shift;
	my $layerTypes = shift;

	my $jobId = $self->{"jobId"};

	my @file2del = ();

	if ( $layerTypes->{ Enums->Type_SIGNAL } ) {

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI,    $jobId . '^[csv]\d*_mdi' );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDI, $jobId . '^[csv]\d*_mdi' );

		push( @file2del, ( @f, @f2 ) );
	}

	if ( $layerTypes->{ Enums->Type_MASK } ) {

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI,    $jobId . "^m[cs]_mdi" );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDI, $jobId . "^m[cs]_mdi" );

		push( @file2del, ( @f, @f2 ) );
	}

	if ( $layerTypes->{ Enums->Type_PLUG } ) {

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI,    $jobId . "^plg[cs]_mdi" );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDI, $jobId . "^plg[cs]_mdi" );

		push( @file2del, ( @f, @f2 ) );

	}

	foreach (@file2del) {
		unless ( unlink($_) ) {
			die "Can not delete mdi file $_.\n";
		}
	}

}

sub __GetLayers2Export {
	my $self       = shift;
	my $layerTypes = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @exportLayers = ();

	my @all = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	if ( $layerTypes->{ Enums->Type_SIGNAL } ) {

		my @l = grep { $_->{"gROWname"} =~ /^[csv]\d*$/ } @all;
		push( @exportLayers, @l );
	}

	if ( $layerTypes->{ Enums->Type_MASK } ) {

		my @l = grep { $_->{"gROWname"} =~ /^m[cs]$/ } @all;
		push( @exportLayers, @l );
	}

	if ( $layerTypes->{ Enums->Type_PLUG } ) {

		my @l = grep { $_->{"gROWname"} =~ /^plg[cs]$/ } @all;
		push( @exportLayers, @l );
	}

	return @exportLayers;
}

sub __GetLayerLimit {
	my $self  = shift;
	my $layerName = shift;

	# 0) Get limits by layer type

	my %lim = ();

	# if top/bot layer, clip around profile
	if ( $layerName =~ /^c$/ || $layerName =~ /^s$/ ) {

		%lim = %{ $self->{"profLim"} };
	}

	#if inner layers, clip around fr frame
	elsif ($layerName =~ /^v\d$/ ) {

		%lim = %{ $self->{"frLim"} };
	}

	return %lim;
}

sub __GetFrLimits {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %lim = ();

	if ( CamHelper->LayerExists($inCAM, $jobId, "fr") ) {

		my $route = RouteFeatures->new();
		$route->Parse( $inCAM, $jobId, $self->{"step"}, "fr" );
		my @features = $route->GetFeatures();
		%lim = PolygonHelper->GetLimByRectangle( \@features );

		# fr width is 2mm, reduce limits by 1mm from each side
		$lim{"xMin"} = $lim{"xMin"} + 1;
		$lim{"xMax"} = $lim{"xMax"} - 1;
		$lim{"yMin"} = $lim{"yMin"} + 1;
		$lim{"yMax"} = $lim{"yMax"} - 1;
	}

	return %lim;

}

 

sub __GetBaseCuThick {
	my $self      = shift;
	my $layerName = shift;

	my $cuThick;

	if ( $self->{"layerCnt"} > 2 ) {

		my $cuLayer = $self->{"stackup"}->GetCuLayer($layerName);
		$cuThick = $cuLayer->GetThick();
	}
	else {

		$cuThick = HegMethods->GetOuterCuThick( $self->{"jobId"}, $layerName );
	}

	return $cuThick;
}

sub __ExportGerberLayer {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tmpFileId = GeneralHelper->GetGUID();

	# function, which build output layer name
	my $suffixFunc = sub {

		my $layerName = shift;
		return $tmpFileId;
	};

	my $resultItemGer = ItemResult->new("Output layers");
	
	# init layer
	my %l = ("name" => $layerName, "mirror" => 0);
	my @layers = (\%l);
	
	# 1 ) Export gerber to temp directory

	ExportLayers->ExportLayers( $resultItemGer, $inCAM, $self->{"mdiStep"}, \@layers, EnumsPaths->Client_INCAMTMPOTHER, "",
								$suffixFunc );

	my $tmpFullPath = EnumsPaths->Client_INCAMTMPOTHER .$layerName. $tmpFileId;

	# 2) Add fiducial mark on the bbeginning of gerber data
	
	my $fiducDCode = FiducMark->AddalignmentMark( $inCAM, $jobId, $layerName, 'inch', $tmpFullPath, 'cross_*', $self->{"mdiStep"} );

	# 3) Copy file to mdi folder
	my $finalName = EnumsPaths->Jobs_PCBMDI . $jobId. $layerName . "_mdi.ger";
	copy( $tmpFullPath, $finalName ) or die "Unable to copy mdi gerber file from: $tmpFullPath.\n";

	return $fiducDCode;

}

# Cut layer data, according physic dimension of pcb
sub __ClipAreaLayer {
	my $self      = shift;
	my $layerName = shift;
	my %lim       = %{ shift(@_) };

	CamLayer->ClipLayerData( $self->{"inCAM"}, $layerName, \%lim );
}

sub __CompensateLayer {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $class   = $self->{"pcbClass"};
	my $cuThick = $self->__GetBaseCuThick($layerName);

	my $comp = 0;

	# when neplat, there is layer "c" but 0 comp
	if ( $cuThick > 0 ) {
		$comp = EtchOperation->GetCompensation( $cuThick, $class );
	}

	if ( $comp > 0 ) {
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
	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r100", "positive");
}

# create special step, which IPC will be exported from
sub __CreateMDIStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 
	CamStep->CreateFlattenStep($inCAM, $jobId, $self->{"step"}, $self->{"mdiStep"});
 
	CamHelper->SetStep($inCAM, $self->{"mdiStep"});
}

# delete pdf step
sub __DeleteMdiStep {
	my $self = shift;
	my $step = $self->{"mdiStep"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $step ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $step, "type" => "step" );
	}
}



#
#sub __Export {
#	my $self = shift;
#
#
#
#	my $inCAM = $self->{"inCAM"};
#	my $jobId = $self->{"jobId"};
#
#	my $step = "panel";
#
#	my $archive     = JobHelper->GetJobArchive($jobId);
#	my $output      = JobHelper->GetJobOutput($jobId);
#	my $archivePath = $archive . "zdroje";
#
#	#delete old ger form archive
#	my @filesToDel = FileHelper->GetFilesNameByPattern( $archivePath, ".ger" );
#
#	foreach my $f (@filesToDel) {
#		unlink $f;
#	}
#
#	# function, which build output layer name, based on layer info
#	my $suffixFunc = sub {
#
#		my $l = shift;
#
#		my $suffix = "_komp" . $l->{"comp"} . "um-.ger";
#
#		if ( $l->{"polarity"} eq "negative" ) {
#			$suffix = "n" . $suffix;
#		}
#
#		return $suffix;
#	};
#
#	my $resultItemGer = $self->_GetNewItem("Output layers");
#
#	Helper->ExportLayers( $resultItemGer, $inCAM,  $step, $self->{"layers"}, $archivePath, $jobId, $suffixFunc );
#
#	$self->_OnItemResult($resultItemGer);
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Mdi::ExportFiles::ExportFiles';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "f13608";
	my $stepName = "panel";

	my $export = ExportFiles->new( $inCAM, $jobId, $stepName );

	my %type = ( Enums->Type_SIGNAL => "1" );

	$export->Run( \%type );

}

1;

