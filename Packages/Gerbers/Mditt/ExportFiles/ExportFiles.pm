
#-------------------------------------------------------------------------------------------#
# Description: Export data for MDI, gerbers + xml
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Mditt::ExportFiles::ExportFiles;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use File::Copy;
use List::Util qw[max min first];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::Gerbers::Export::ExportLayers';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::FiducMark';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::Enums';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::ExportXml';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Technology::EtchOperation';
use aliased 'Packages::TifFile::TifLayers';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::Helper';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAMJob::Dim::JobDim';

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
	$self->{"units"} = shift // "inch";    # default units recommended by Schmoll machinen

	# Info about  pcb ===========================

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );
	}

	$self->{"pcbClass"} = CamJob->GetJobPcbClass( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"pcbType"} = JobHelper->GetPcbType( $self->{"jobId"} );

	# Get limits of fr, profile ===============

	my %frLim = $self->__GetFrLimits();
	$self->{"frLim"} = \%frLim;

	my %profLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	$self->{"profLim"} = \%profLim;

	# Other properties ========================

	$self->{"tifFile"} = TifLayers->new( $self->{"jobId"} );

	unless ( $self->{"tifFile"}->TifFileExist() ) {
		die "Dif file must exist when MDI data are exported.\n";
	}

	$self->{"mdiStep"} = "mditt_panel";

	$self->{"fiducMark"} = FiducMark->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"units"} );

	$self->{"exportXml"} = ExportXml->new( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Run {
	my $self       = shift;
	my $layerTypes = shift;

	# delete old MDI files
	$self->__DeleteOldFiles($layerTypes);

	# Get all layer for export
	my @lCouples = $self->__GetLayers2Export($layerTypes);

	unless ( scalar(@lCouples) ) {
		return 0;
	}

	$self->__CreateMDIStep( [ map { @{$_} } @lCouples ] );
	$self->__ExportLayers( \@lCouples );

	$self->__DeleteMdiStep();

	return 1;
}

sub __ExportLayers {
	my $self     = shift;
	my @lCouples = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Go through layer couples
	foreach my $couples (@lCouples) {

		# new result item for layer couple
		my $resultItem = $self->_GetNewItem( join( " + ", map { $_->{"gROWname"} } @{$couples} ) );

		my %dataLim = $self->__GetLayerLimit( $couples->[0]->{"gROWname"} );
		my %pnlDim = ( "w" => $dataLim{"xMax"} - $dataLim{"xMin"}, "h" => $dataLim{"yMax"} - $dataLim{"yMin"} );

		$self->{"exportXml"}->Create( \%pnlDim );

		# Go through Primary/Secondary layer
		for ( my $i = 0 ; $i < scalar( @{$couples} ) ; $i++ ) {

			my $l = $couples->[$i];

			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );

			# 1) Find position of fiducial marks
			my @fiducials = $self->__GetFiducials( $l->{"gROWname"}, \%dataLim );

			# 1) Optimize layer (move layer data to zero + optimize levels)
			$self->__OptimizeLayer( $l, \%dataLim );

			# 2) insert frame 100µm width around pcb (fr frame coordinate)
			$self->__PutFrameAorundPcb( $l->{"gROWname"}, \%pnlDim );

			# 3) clip data by limits
			$self->__ClipAreaLayer( $l->{"gROWname"}, \%pnlDim );

			# 4) compensate layer by computed compensation
			$self->__CompensateLayer( $l->{"gROWname"} );

			# 5) export gerbers
			my $tmpFile = $self->__ExportGerberLayer( $l->{"gROWname"}, $resultItem );

			# 6) Add fiducial marks to gerber file
			my $fiducDCode = $self->{"fiducMark"}->AddFiducialMarks( $tmpFile, \@fiducials );

			#my $fiducDCode = 1;

			# 7) Generate file name
			my $fileName = $l->{"gROWname"};

			if ( $l->{"gROWname"} =~ /outer/ ) {

				# Convert outer signal layer name to standard layer name
				$fileName = Helper->ConverOuterName2FileName( $l->{"gROWname"}, $self->{"layerCnt"} );

			}
			elsif ( $l->{"gROWname"} =~ /^v\d+$/ ) {

				my %lPars = JobHelper->ParseSignalLayerName( $l->{"gROWname"} );

				my $p = $self->{"stackup"}->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

				if ( $p->GetProductType() eq StackEnums->Product_PRESS ) {

					my $side = $self->{"stackup"}->GetSideByCuLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

					my $matL = $p->GetProductOuterMatLayer( $side eq "top" ? "first" : "last" )->GetData();

					if ( $matL->GetType() eq StackEnums->MaterialType_COPPER && !$matL->GetIsFoil() ) {

						# Convert standard inner signal layer name to name "after press"
						$fileName = Helper->ConverInnerName2AfterPressFileName($fileName);
					}
				}

			}

			$fileName = "${jobId}${fileName}_mdi";

			# 8) Add exposition settings for specific layers to XML
			if ( $i == 0 ) {

				$self->{"exportXml"}->AddPrimarySide( $l->{"gROWname"}, $fiducDCode, $fileName );
			}
			elsif ( $i == 1 ) {
				$self->{"exportXml"}->AddSecondarySide( $l->{"gROWname"}, $fiducDCode, $fileName );
			}

			#9 ) Copy file to mdi folder after exportig xml template
			my $finalName = EnumsPaths->Jobs_PCBMDITT . $fileName . ".ger";
			copy( $tmpFile, $finalName ) or die "Unable to copy mdi gerber file from: $tmpFile.\n";
			unlink($tmpFile);

		}

		$self->{"exportXml"}->Export();

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

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDITT,    $jobId . '^[csv]\d*' );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDITT, $jobId . '^[csv]\d*' );

		push( @file2del, ( @f, @f2 ) );
	}

	if ( $layerTypes->{ Enums->Type_MASK } ) {

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDITT,    $jobId . "^m[cs]_mdi" );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDITT, $jobId . "^m[cs]_mdi" );

		push( @file2del, ( @f, @f2 ) );
	}

	if ( $layerTypes->{ Enums->Type_PLUG } ) {

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDITT,    $jobId . "^plg[cs]_mdi" );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDITT, $jobId . "^plg[cs]_mdi" );

		push( @file2del, ( @f, @f2 ) );

	}

	if ( $layerTypes->{ Enums->Type_GOLD } ) {

		my @f  = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDITT,    $jobId . "^gold[cs]_mdi" );
		my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDITT, $jobId . "^gold[cs]_mdi" );

		push( @file2del, ( @f, @f2 ) );

	}

	foreach (@file2del) {
		unless ( unlink($_) ) {
			die "Can not delete mdi file $_.\n";
		}
	}

}

# Return all layer couples (always TOP + BOT layer for semiproduct)
# If only one layer exist (eg one sided PCB, it doesn't matter)
sub __GetLayers2Export {
	my $self       = shift;
	my $layerTypes = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @exportLayers = ();

	my @all = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	# Signal layers
	if ( $layerTypes->{ Enums->Type_SIGNAL } ) {

		if ( $self->{"layerCnt"} <= 2 ) {

			my @couple = grep { $_->{"gROWname"} =~ /^[cs]$/ } @all;

			push( @exportLayers, \@couple );

		}
		else {

			my @products = $self->{"stackup"}->GetAllProducts();

			foreach my $p (@products) {

				# Skip if producti is parent input product,
				# - which doesn not contain any pressing
				# - or doesn't contain Cu foil as outer layers (Cu foil must be not "empty")
				if ( $p->GetProductType() eq StackEnums->Product_INPUT && $p->GetIsParent() ) {

					my $matLTop = $p->GetProductOuterMatLayer("first")->GetData();
					my $matLBot = $p->GetProductOuterMatLayer("last")->GetData();

					if (
						 scalar( $p->GetLayers() ) == 1
						 || !(
							      $matLTop->GetType() eq StackEnums->MaterialType_COPPER
							   && $matLBot->GetType() eq StackEnums->MaterialType_COPPER
							   && !$p->GetTopEmptyFoil()
							   && !$p->GetBotEmptyFoil()
						 )
					  )
					{
						next;
					}
				}

				my $topLName = JobHelper->BuildSignalLayerName( $p->GetTopCopperLayer(), $p->GetOuterCoreTop(), 0 );
				my $botLName = JobHelper->BuildSignalLayerName( $p->GetBotCopperLayer(), $p->GetOuterCoreBot(), 0 );

				my $topL = first { $_->{"gROWname"} =~ /^$topLName$/ } @all;
				my $botL = first { $_->{"gROWname"} =~ /^$botLName$/ } @all;

				push( @exportLayers, [ $topL, $botL ] );
			}
		}
	}

	# Solder mask layers
	if ( $layerTypes->{ Enums->Type_MASK } ) {

		my @l = grep { $_->{"gROWname"} =~ /^m[cs]2?$/ } @all;    # number 2 is second soldermask

		my @suffixes = ( "", "2" );                               #mask name suffix

		foreach my $suff (@suffixes) {

			my @l = grep { $_->{"gROWname"} =~ /^m[cs]$suff$/ } @l;

			if ( scalar(@l) ) {

				push( @exportLayers, \@l );
			}
		}
	}

	# Plugging layers
	if ( $layerTypes->{ Enums->Type_PLUG } ) {

		if ( $self->{"layerCnt"} <= 2 ) {

			my @couple = grep { $_->{"gROWname"} =~ /^plg[cs]$/ } @all;

			push( @exportLayers, \@couple );

		}
		else {

			my @products = $self->{"stackup"}->GetAllProducts();

			foreach my $p (@products) {

				if ( $p->GetPlugging() ) {

					my $topLName = JobHelper->BuildSignalLayerName( $p->GetTopCopperLayer(), 0, $p->GetPlugging() );
					my $botLName = JobHelper->BuildSignalLayerName( $p->GetBotCopperLayer(), 0, $p->GetPlugging() );

					my $topL = first { $_->{"gROWname"} =~ /^$topLName$/ } @all;
					my $botL = first { $_->{"gROWname"} =~ /^$botLName$/ } @all;

					push( @exportLayers, [ $topL, $botL ] );
				}
			}

		}
	}

	# Gold layers
	if ( $layerTypes->{ Enums->Type_GOLD } ) {

		my @l = grep { $_->{"gROWname"} =~ /^gold[cs]$/ } @all;

		push( @exportLayers, \@l ) if ( scalar(@l) );
	}

	# Check if all couples has 1-2 layers

	foreach my $couple (@exportLayers) {

		my $lCnt = scalar( @{$couple} );

		die "Wrong number of layers (min 1 max 2)" if ( $lCnt < 1 || $lCnt > 2 );

		my @undef = grep { !defined $_ } @{$couple};

		die "Layer is not defined " if ( scalar(@undef) );

	}

	return @exportLayers;
}

# Get limits, by phisic dimension of pcb
sub __GetLayerLimit {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %lim = ();

	# clip around fr frame if:

	# - mask layer (mc;ms; ) layer
	# - gold layer (goldc; golds)
	# - signal layer (c;s) and not outer rigid flex
	# - plg(c/s) layers
	# - mask layer second (mc2;ms2; ) layer
	# - mask layer flex (mcflex;msflex; ) layer
	if ( $self->{"layerCnt"} > 2
		 && ( $layerName =~ /^((gold)|m|plg)?[cs]$/ || $layerName =~ /^m[cs]2?(flex)?$/ ) )
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

	#	# Exceptions for goldc/s when panel is cut
	my $cutHeight;
	if ( $layerName =~ /^gold[cs]$/ && JobDim->GetCutPanel( $inCAM, $jobId, undef, \$cutHeight, undef, \%lim ) ) {

		$lim{"yMax"} = $lim{"yMin"} + $cutHeight;
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

# Return fiducial position of OLEC holes in mm
sub __GetFiducials {
	my $self      = shift;
	my $layerName = shift;
	my $dataLim   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# 1) Decide wich drill layer take fiducial position from
	# v - panel profile frame drilling
	# v1 - core frame drilling

	my $fiducLayer = undef;

	if ( $layerName =~ /^((outer)|(plg))?v\d+$/ || $layerName =~ /^outer[cs]$/ ) {

		$fiducLayer = "v1";

	}
	elsif (    ( $layerName =~ /^mc\d?$/ && CamHelper->LayerExists( $inCAM, $jobId, "c" ) && $self->{"pcbType"} ne EnumsGeneral->PcbType_NOCOPPER )
			|| ( $layerName =~ /^ms\d?$/ && CamHelper->LayerExists( $inCAM, $jobId, "s" ) ) )
	{

		$fiducLayer = "c";
	}
	else {

		$fiducLayer = "v";
	}

	# 2) Choose proper 4 camera marks
	my $f = Features->new();
	$f->Parse( $inCAM, $jobId, $step, $fiducLayer );

	my @features = undef;

	if ( $fiducLayer eq "c" ) {
		@features = grep { defined $_->{"att"}->{".geometry"} && $_->{"att"}->{".geometry"} =~ /^score_fiducial$/ && $_->{"polarity"} eq "P" }
		  $f->GetFeatures();
	}
	else {

		@features =
		  grep { defined $_->{"att"}->{".geometry"} && $_->{"att"}->{".geometry"} =~ /^OLEC_otvor_((IN)|(2V))$/ } $f->GetFeatures();
	}

	my $useCut = ( $layerName =~ /^gold[cs]$/ && CamAttributes->GetJobAttrByName( $inCAM, $jobId, "technology_cut" ) !~ /no/i ) ? 1 : 0;

	# Exception 1: for layers goldc/golds. Thera are 4 top camera marks and wee need lower one, which remain after pnl cut
	unless ($useCut) {
		@features = grep { $_->{"att"}->{".pnl_place"} !~ /cut/i } @features;
	}

	# Exception 2: If inner layer and sequential lamination, use OLEC which contain SL - sequential lamination
	if ( $layerName =~ /^(plg)?v\d+$/ && $self->{"stackup"}->GetSequentialLam() ) {

		my %lPars = JobHelper->ParseSignalLayerName($layerName);

		if ( $self->{"stackup"}->GetCuLayer( $lPars{"sourceName"} )->GetIsFoil() ) {

			@features = grep { $_->{"att"}->{".pnl_place"} =~ /-SL-/i } @features;
		}
		else {

			@features = grep { $_->{"att"}->{".pnl_place"} !~ /-SL-/i } @features;
		}
	}

	# There are 4-6 (2 extra top marks when cut panel) marks
	die "All fiducial marks (four marks) were not found in layer: $fiducLayer" if ( scalar(@features) < 4 );

	# Take position and sort them: lefttop; right-top; right-bot; left-bot
	my @fiducials = ();

	my $fLT = ( grep { $_->{"att"}->{".pnl_place"} =~ /left-top/i } @features )[0];     # left top mark can contain suffix
	my $fRT = ( grep { $_->{"att"}->{".pnl_place"} =~ /right-top/i } @features )[0];    # right top mark can contain suffix

	if ($useCut) {
		$fLT = ( grep { $_->{"att"}->{".pnl_place"} =~ /left-top.*cut/i } @features )[0];     # left top mark can contain suffix
		$fRT = ( grep { $_->{"att"}->{".pnl_place"} =~ /right-top.*cut/i } @features )[0];    # right top mark can contain suffix
	}

	my $fRB = ( grep { $_->{"att"}->{".pnl_place"} =~ /right-bot$/i } @features )[0];
	my $fLB = ( grep { $_->{"att"}->{".pnl_place"} =~ /left-bot$/i } @features )[0];

	die "Fiducial mark left-top was not found"  if ( !defined $fLT );
	die "Fiducial mark right-top was not found" if ( !defined $fRT );
	die "Fiducial mark right-top was not found" if ( !defined $fRB );
	die "Fiducial mark left-bot was not found"  if ( !defined $fLB );

	push( @fiducials, { "x" => $fLT->{"x1"}, "y" => $fLT->{"y1"} } );                         # left-top
	push( @fiducials, { "x" => $fRT->{"x1"}, "y" => $fRT->{"y1"} } );                         # right-top
	push( @fiducials, { "x" => $fRB->{"x1"}, "y" => $fRB->{"y1"} } );                         # right-bot
	push( @fiducials, { "x" => $fLB->{"x1"}, "y" => $fLB->{"y1"} } );                         # left-bot

	# Adjust fiducial position by real PCB dimension (move to InCAM job zero)
	foreach my $f (@fiducials) {

		$f->{"x"} -= $dataLim->{"xMin"};
		$f->{"y"} -= $dataLim->{"yMin"};
	}

	return @fiducials;
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
	my %l = (
			  "name"   => $layerName,
			  "mirror" => 0
	);

	my @layers = ( \%l );

	# 1 ) Export gerber to temp directory

	ExportLayers->ExportLayers( $resultItemGer, $inCAM, $self->{"mdiStep"}, \@layers, EnumsPaths->Client_INCAMTMPOTHER,
								"", $suffixFunc, undef, 1, undef, $self->{"units"} );

	my $tmpFullPath = EnumsPaths->Client_INCAMTMPOTHER . $layerName . $tmpFileId;

	return $tmpFullPath;
}

# Cut layer data, according physic dimension of pcb
sub __ClipAreaLayer {
	my $self      = shift;
	my $layerName = shift;
	my %pnlDim    = %{ shift(@_) };

	my %pnlLim = ();
	$pnlLim{"xMin"} = 0;
	$pnlLim{"yMin"} = 0;
	$pnlLim{"xMax"} = $pnlDim{"w"};
	$pnlLim{"yMax"} = $pnlDim{"h"};

	CamLayer->ClipLayerData( $self->{"inCAM"}, $layerName, \%pnlLim, undef, 1 );
}

# Optimize lazer in order contain only one level of features
# Before optimiyation, countourize data in negative layers
# (in other case "sliver fills" are broken during data compensation)
sub __OptimizeLayer {
	my $self    = shift;
	my $l       = shift;
	my $dataLim = shift;

	my $layerName = $l->{"gROWname"};

	# 1) Move data layer to zero
	if ( $dataLim->{"xMin"} != 0 || $dataLim->{"yMin"} != 0 ) {

		CamLayer->WorkLayer( $self->{"inCAM"}, $layerName );
		my %srcP = ( "x" => $dataLim->{"xMin"}, "y" => $dataLim->{"yMin"} );
		my %trgtP = ( "x" => 0, "y" => 0 );
		CamLayer->MoveSelSameLayer( $self->{"inCAM"}, $layerName, \%srcP, \%trgtP );
		CamLayer->WorkLayer( $self->{"inCAM"}, $layerName );
	}

	# 2) Optimize data
	if ( $layerName =~ /^(plg)?[cs]$/ || $layerName =~ /^v\d+$/ ) {

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

	# Find layer settings in TIF file
	my $lTIF = $self->{"tifFile"}->GetLayer($layerName);

	die "Output layer settings was not found in tif file for layer: " . $layerName unless ( defined $lTIF );

	my $comp = $lTIF->{"comp"};

	if ( $comp != 0 ) {
		CamLayer->CompensateLayerData( $inCAM, $layerName, $comp );
	}

}

# Frame define border of data for pcb layer
# border must be size like physic pcb
sub __PutFrameAorundPcb {
	my $self      = shift;
	my $layerName = shift;
	my %pnlDim    = %{ shift(@_) };

	my @coord = ();

	my %p1 = (
			   "x" => 0,
			   "y" => 0
	);
	my %p2 = (
			   "x" => 0,
			   "y" => $pnlDim{"h"}
	);
	my %p3 = (
			   "x" => $pnlDim{"w"},
			   "y" => $pnlDim{"h"}
	);
	my %p4 = (
			   "x" => $pnlDim{"w"},
			   "y" => 0
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
	my $self   = shift;
	my @layers = @{ shift @_ };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @lNames = map { $_->{"gROWname"} } @layers;
	push( @lNames, "v" );
	push( @lNames, "v1" ) if ( $self->{"layerCnt"} > 2 );
	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"mdiStep"}, 0, \@lNames );

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

	use aliased 'Packages::Gerbers::Mditt::ExportFiles::ExportFiles';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d271439";
	my $stepName = "panel";

	use aliased 'Packages::Export::PreExport::FakeLayers';

	FakeLayers->CreateFakeLayers( $inCAM, $jobId, undef, 1 );

	my $export = ExportFiles->new( $inCAM, $jobId, $stepName );

	my %type = (
				 Enums->Type_SIGNAL => "0",
				 Enums->Type_MASK   => "1",
				 Enums->Type_PLUG   => "0",
				 Enums->Type_GOLD   => "0"
	);

	$export->Run( \%type );

	#FakeLayers->RemoveFakeLayers( $inCAM, $jobId );

}

1;

