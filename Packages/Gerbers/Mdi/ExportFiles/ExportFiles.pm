
#-------------------------------------------------------------------------------------------#
# Description: Export data for MDI, gerbers + xml
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Mdi::ExportFiles::ExportFiles;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::Gerbers::Export::ExportLayers';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::FiducMark';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Enums';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::ExportXml';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Technology::EtchOperation';
use aliased 'Packages::TifFile::TifSigLayers';

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

	# Get limits of fr, profile ===============

	my %frLim = $self->__GetFrLimits();
	$self->{"frLim"} = \%frLim;

	my %profLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	$self->{"profLim"} = \%profLim;

	# Other properties ========================

	$self->{"tifFile"} = TifSigLayers->new( $self->{"jobId"} );

	unless ( $self->{"tifFile"}->TifFileExist() ) {
		die "Dif file must exist when MDI data are exported.\n";
	}

	$self->{"mdiStep"} = "mdi_panel";

	$self->{"exportXml"} = ExportXml->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"profLim"}, $self->{"layerCnt"} );

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

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );

		# new result item for lyer
		my $resultItem = $self->_GetNewItem( $l->{"gROWname"} );

		# get limits (define physic dimension) for layer
		my %lim = $self->__GetLayerLimit( $l->{"gROWname"} );

		# 1) Optimize levels
		$self->__OptimizeLayer($l);

		# 2) insert frame 100µm width around pcb (fr frame coordinate)
		$self->__PutFrameAorundPcb( $l->{"gROWname"}, \%lim );

		# 3) clip data by limits
		$self->__ClipAreaLayer( $l->{"gROWname"}, \%lim );

		# 4) compensate layer by computed compensation
		$self->__CompensateLayer( $l->{"gROWname"} );

		# 5) export gerbers
		my $fiducDCode = undef;
		my $tmpFile = $self->__ExportGerberLayer( $l->{"gROWname"}, \$fiducDCode, $resultItem );

		# 6) export xml
		$self->{"exportXml"}->Export( $l, $fiducDCode );

		# 7) Copy file to mdi folder after exportig xml template
		my $finalName = EnumsPaths->Jobs_PCBMDI . $jobId . $l->{"gROWname"} . "_mdi.ger";
		copy( $tmpFile, $finalName ) or die "Unable to copy mdi gerber file from: $tmpFile.\n";
		unlink($tmpFile);

		#  reise result of export
		$self->_OnItemResult($resultItem);
	}
}

# Delete old gerber + xml files
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

	if ( $layerTypes->{ Enums->Type_GOLD } ) {

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI,    $jobId . "^gold[cs]_mdi" );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDI, $jobId . "^gold[cs]_mdi" );

		push( @file2del, ( @f, @f2 ) );

	}

	foreach (@file2del) {
		unless ( unlink($_) ) {
			die "Can not delete mdi file $_.\n";
		}
	}

}

# Return which layers export by type
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

	if ( $layerTypes->{ Enums->Type_GOLD } ) {

		my @l = grep { $_->{"gROWname"} =~ /^gold[cs]$/ } @all;
		push( @exportLayers, @l );
	}

	return @exportLayers;
}

# Get limits, by phisic dimension of pcb
sub __GetLayerLimit {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};

	my %lim = ();

	# clip around fr frame if:

	# - mask layer (mc;ms) layer
	# - gold layer (goldc; golds)
	# - signal layer (c;s) and not outer rigid flex
	# - plg(c/s) layers
	if (
		$self->{"layerCnt"} > 2
		&& $layerName =~ /^((gold)|m|plg)?[cs]$/
	  )
	{
		%lim = %{ $self->{"frLim"} };
	}

	# clip around profile if
	# - inner layers (vx)
	# - signal layer (c;s) and pcb is flex
	# - all other cases
	else {

		%lim = %{ $self->{"profLim"} };
	}

	# Exceptions for Outer Rigid-Flex with top coverlay
	if ( JobHelper->GetIsFlex( $self->{"jobId"} ) ) {

		if (    JobHelper->GetPcbFlexType( $self->{"jobId"} ) eq EnumsGeneral->PcbFlexType_RIGIDFLEXO
			 && CamHelper->LayerExists( $inCAM, $self->{"jobId"}, "coverlayc" ) )
		{
			%lim = %{ $self->{"profLim"} };
		}
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
	my $fiducDCode    = shift;
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
	my %l = (
			  "name"   => $layerName,
			  "mirror" => 0
	);
	my @layers = ( \%l );

	# 1 ) Export gerber to temp directory

	ExportLayers->ExportLayers( $resultItemGer, $inCAM, $self->{"mdiStep"}, \@layers, EnumsPaths->Client_INCAMTMPOTHER, "", $suffixFunc, undef, 1 );

	my $tmpFullPath = EnumsPaths->Client_INCAMTMPOTHER . $layerName . $tmpFileId;

	# 2) Add fiducial mark on the bbeginning of gerber data
	CamHelper->SetStep( $inCAM, $self->{"step"} );
	$$fiducDCode = FiducMark->AddalignmentMark( $inCAM, $jobId, $layerName, 'inch', $tmpFullPath, 'cross_*', $self->{"step"} );
	CamHelper->SetStep( $inCAM, $self->{"mdiStep"} );

	return $tmpFullPath;
}

# Cut layer data, according physic dimension of pcb
sub __ClipAreaLayer {
	my $self      = shift;
	my $layerName = shift;
	my %lim       = %{ shift(@_) };

	CamLayer->ClipLayerData( $self->{"inCAM"}, $layerName, \%lim, undef, 1 );
}

# Optimize lazer in order contain only one level of features
# Before optimiyation, countourize data in negative layers
# (in other case "sliver fills" are broken during data compensation)
sub __OptimizeLayer {
	my $self = shift;
	my $l    = shift;

	my $layerName = $l->{"gROWname"};

	if ( $layerName =~ /^(plg)?[cs]$/ || $layerName =~ /^v\d$/ ) {

		if ( $l->{"gROWpolarity"} eq "negative" ) {
			CamLayer->Contourize( $self->{"inCAM"}, $layerName );
			CamLayer->WorkLayer( $self->{"inCAM"}, $layerName );
		}

		my $res = CamLayer->OptimizeLevels( $self->{"inCAM"}, $layerName, 1 );
		CamLayer->WorkLayer( $self->{"inCAM"}, $layerName );
	}
}

# Compensate layer by compensation
sub __CompensateLayer {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $class = $self->{"pcbClass"};

	my $comp = 0;

	if ( $layerName =~ /^c$/ || $layerName =~ /^s$/ || $layerName =~ /^v\d$/ ) {

		#		# read comp from tif file
		#		if ( $self->{"tifFile"}->TifFileExist() ) {

		my %sigLayers = $self->{"tifFile"}->GetSignalLayers();
		$comp = $sigLayers{$layerName}->{'comp'};

		#		}
		#		# read default comp (old pcb doesn't contain dif file)
		#		else{
		#
		#			my $inner = $layerName =~ /^v\d+$/ ? 1 : 0;
		#			my $cuThick = JobHelper->GetBaseCuThick($jobId, $layerName);
		#
		#			$comp = EtchOperation->GetCompensation( $cuThick, $class, $inner );
		#		}

	}

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

	my %p1 = (
			   "x" => $lim{"xMin"},
			   "y" => $lim{"yMin"}
	);
	my %p2 = (
			   "x" => $lim{"xMin"},
			   "y" => $lim{"yMax"}
	);
	my %p3 = (
			   "x" => $lim{"xMax"},
			   "y" => $lim{"yMax"}
	);
	my %p4 = (
			   "x" => $lim{"xMax"},
			   "y" => $lim{"yMin"}
	);
	push( @coord, \%p1 );
	push( @coord, \%p2 );
	push( @coord, \%p3 );
	push( @coord, \%p4 );

	# frame 100µm width around pcb (fr frame coordinate)
	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r100", "positive", 1 );
}

# Create special step, which IPC will be exported from
sub __CreateMDIStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"mdiStep"} );

	CamHelper->SetStep( $inCAM, $self->{"mdiStep"} );
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::Mdi::ExportFiles::ExportFiles';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d222768";
	my $stepName = "panel";

	my $export = ExportFiles->new( $inCAM, $jobId, $stepName );

	my %type = (
				 Enums->Type_SIGNAL => "1",
				 Enums->Type_MASK   => "1",
				 Enums->Type_PLUG   => "1",
				 Enums->Type_GOLD   => "1"
	);

	$export->Run( \%type );

}

1;

