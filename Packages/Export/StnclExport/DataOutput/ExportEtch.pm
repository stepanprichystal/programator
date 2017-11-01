
#-------------------------------------------------------------------------------------------#
# Description: Export of etched stencil
# If exist half-etched fiducials, add it only to one gerber file top or bot
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::DataOutput::ExportEtch;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::Gerbers::Export::ExportLayers'            => 'Helper';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper' => 'StencilHelper';
use aliased 'Programs::Stencil::StencilCreator::Enums'           => 'StnclEnums';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"thick"}     = shift;    # stencil thick
	$self->{"fiducInfo"} = shift;    # fiduc mark info

	$self->{"step"} = "o+1";         # step which stnecil data are exported from

	$self->{"workLayer"} = "ds";
	$self->{"maxW"}      = 400;      # max width of stencil possible to produce with schema
	$self->{"maxH"}      = 555;      # max length of stencil possible to produce with schema

	my %profLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	$self->{"profLim"} = \%profLim;

	my %stencilInfo = StencilHelper->GetStencilInfo( $self->{"jobId"} );
	$self->{"stencilInfo"} = \%stencilInfo;
	
	my $ser    = StencilSerializer->new( $self->{"jobId"} );
	$self->{"params"} = $ser->LoadStenciLParams();
	
 
	$self->{"exportFiles"} = [];     # paths of exported files3
	
	 

	return $self;
}

# Prepare gerber files
sub Output {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	CamHelper->SetStep( $inCAM, $step );

	# 1) Export layers

	push( @{ $self->{"exportFiles"} }, $self->__PrepareTopBotLayer("top") );
	push( @{ $self->{"exportFiles"} }, $self->__PrepareTopBotLayer("bot") );
	push( @{ $self->{"exportFiles"} }, $self->__PrepareMeasureLayer() );

	if ( scalar( @{ $self->{"exportFiles"} } ) != 3 ) {

		die "Not all 3 layers are exported";
	}

	# 2) zip files
	my $archive = JobHelper->GetJobArchive( $self->{"jobId"} ) . "zdroje\\data_stencil";

	unless ( -e $archive ) {
		mkdir($archive) or die "Can't create dir: " . $archive . $_;
	}

	my $zip = Archive::Zip->new();

	foreach my $f ( @{ $self->{"exportFiles"} } ) {

		$zip->addFile( $f->{"path"}, $f->{"name"} );
	}

	my $path = $archive . "\\" . $jobId . "_leptana.zip";
	unless ( $zip->writeToFileNamed($path) == AZ_OK ) {

		die 'Error when zip stencil data files';
	}

}

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

# Export top or bot layer
sub __PrepareTopBotLayer {
	my $self = shift;
	my $type = shift;    # top/bot

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $t = $self->{"params"}->GetStencilType();

	# 1) prepare data layer
	my $lData = GeneralHelper->GetGUID();

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lData ) ) {

		$inCAM->COM( 'delete_layer', "layer" => $lData );
	}

	$inCAM->COM( "merge_layers", "source_layer" => $self->{"workLayer"}, "dest_layer" => $lData );

	# consider half-etched fiducial marks
	if ( $self->{"fiducInfo"}->{"halfFiducials"} ) {

		my $readable = $self->{"fiducInfo"}->{"fiducSide"} eq "readable" ? 1 : 0;

		my $removeFiduc = 0;

		# data for top layer
		if ( $type eq "top" ) {

			if (    ( ( $t eq StnclEnums->StencilType_TOP || $t eq StnclEnums->StencilType_TOPBOT ) && !$readable )
				 || ( $t eq StnclEnums->StencilType_BOT && $readable ) )
			{
				# remove fiduc marks from top layer
				$self->__RemoveFiduc($lData);
			}
		}
		elsif ( $type eq "bot" ) {

			if (    ( ( $t eq StnclEnums->StencilType_TOP || $t eq StnclEnums->StencilType_TOPBOT ) && $readable )
				 || ( $t eq StnclEnums->StencilType_BOT && !$readable ) )
			{
				# remove fiduc marks from bot layer
				$self->__RemoveFiduc($lData);
			}
		}
	}

	CamLayer->WorkLayer( $inCAM, $lData );

	# if bot layer remove pcbid if exist in layer

	if (    ( ( $t eq StnclEnums->StencilType_TOP || $t eq StnclEnums->StencilType_TOPBOT ) && $type eq "bot" )
		 || ( $t eq StnclEnums->StencilType_BOT && $type eq "top" ) )
	{
		$self->__RemovePcbId($lData);
	}

	$self->__CheckPads($lData);

	$self->__DoComp($lData);

	# 2) Prepare schema layer

	my $lName = $type eq "top" ? "_t" : "_b";

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {

		$inCAM->COM( 'delete_layer', "layer" => $lName );
	}

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );


	my $addDim = 0; # add dimension to schema
	if (    ( ( $t eq StnclEnums->StencilType_TOP || $t eq StnclEnums->StencilType_TOPBOT ) && $type eq "top" )
		 || ( $t eq StnclEnums->StencilType_BOT && $type eq "bot" ) )
	{
		$addDim = 1;
	}

	$self->__AddSchema( $lName, $addDim, $type);

	# 3) Merge prepared schema and data layer

	$inCAM->COM( "merge_layers", "source_layer" => $lData, "dest_layer" => $lName );

	$inCAM->COM( 'delete_layer', "layer" => $lData );

	# 4) Export layer

	my $fileName = GeneralHelper->GetGUID();
	my $path     = EnumsPaths->Client_INCAMTMPOTHER;
	my %layer    = ( "name" => $lName, "polarity" => "positive", "comp" => 0, "mirror" => $type eq "top" ? 1 : 0, "angle" => 270 );
	my @layers   = ( \%layer );

	my $resultItemGer = $self->_GetNewItem("Layer $type");

	Helper->ExportLayers2( $resultItemGer, $inCAM, $step, \@layers, $path, sub { return $fileName }, 0, 1 );

	$self->_OnItemResult($resultItemGer);

	$inCAM->COM( 'delete_layer', "layer" => $lName );

	my %info = ( "name" => $type eq "top" ? "_t.ger" : "_b.ger", "path" => $path . $fileName );

	return \%info;
}

# measure layer used for control
sub __PrepareMeasureLayer {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# 1) Export layer

	my $fileName = GeneralHelper->GetGUID();
	my $path     = EnumsPaths->Client_INCAMTMPOTHER;
	my %layer    = ( "name" => $self->{"workLayer"}, "polarity" => "positive", "comp" => 0, "mirror" => 0, "angle" => 270 );
	my @layers   = ( \%layer );

	my $resultItemGer = $self->_GetNewItem("Layer measure");

	Helper->ExportLayers2( $resultItemGer, $inCAM, $step, \@layers, $path, sub { return $fileName }, 0, 1 );

	$self->_OnItemResult($resultItemGer);

	my %info = ( "name" => "_m.ger", "path" => $path . $fileName );

	return \%info;

}

# If some pad is surface or line, create pad from him
sub __CheckPads {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	
	CamLayer->WorkLayer( $inCAM, $lName);
 	$inCAM->COM( 'sel_break');
	$inCAM->COM( 'sel_contourize', "accuracy"  => '6.35', "break_to_islands" => 'yes', "clean_hole_size" => '60',  "clean_hole_mode" => 'x_and_y' );
	$inCAM->COM( 'sel_cont2pad',   "match_tol" => '25.4', "restriction"      => '',    "min_size"        => '127', "max_size"        => '12000' );
	

	# test on  lines presence
	my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $lName );
	if ( $fHist{"line"} > 0 || $fHist{"arc"} > 0 ) {

		die "Error during convert featrues to apds. Layer ("
		  . $self->{"workLayer"}
		  . ") can't contain line and arcs. Only pad and surfaces are alowed.";
	}
	
	# check error on surfaces
	if ( $fHist{"surf"} == 1 && $fHist{"pad"} == 0) {
		die "Error during creating pads in stencil";
	}

}

# Do compensation, depand on pad size
sub __DoComp {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};

	# Get compensation
	my @comp = ();

	my @lines = @{ FileHelper->ReadAsLines( GeneralHelper->Root() . "\\Packages\\Export\\StnclExport\\DataOutput\\Comp" ) };
	@lines = grep { $_ !~ /^\s*$/ } @lines;    # remove blank

	my $thick = $self->{"thick"};

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];

		my ($thickCur) = $l =~ m/tl\s*=\s*(\d+.?\d*)/;
		if ( defined $thickCur && $thickCur == $thick ) {

			# parece comp, format: min = 0.219; max = 0.261; res = -30

			$i++;
			for ( ; $lines[$i] !~ /tl/ ; $i++ ) {

				$l = $lines[$i];

				$l =~ s/\s//g;

				my ( $min, $max, $res ) = $l =~ m/min=(\d+.?\d*);max=(\d+.?\d*);res=(-?\d+.?\d*)/;

				my %h = ( "min" => $min, "max" => $max, "res" => $res );
				push( @comp, \%h );
			}

			last;
		}
	}

	unless ( scalar(@comp) ) {

		die "Compensation for given stencil thick: $thick was not found";
	}

	# do resize of pads
	
	CamLayer->WorkLayer( $inCAM, $lName );
	
	foreach my $c (@comp) {

		my $result = CamFilter->ByBoundBox( $inCAM, $c->{"min"}, $c->{"max"} );

		if ($result) {

			$inCAM->COM(
						 'sel_resize',
						 "size"     => $c->{"res"},
						 corner_ctl => 'no'
			);
		}
	}
}

sub __RemoveFiduc {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamLayer->WorkLayer($inCAM, $lName);

	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".fiducial_name" ) ) {
		$inCAM->COM("sel_delete");
	}
	
	

}

sub __RemovePcbId {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamLayer->WorkLayer($inCAM, $lName);

	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".string", "pcbid" ) ) {
		$inCAM->COM("sel_delete");
	}

}

sub __AddSchema {
	my $self   = shift;
	my $lName  = shift;
	my $addDim = shift;
	my $lType = shift; # top/bot

	my $inCAM = $self->{"inCAM"};
	my %lim   = %{ $self->{"profLim"} };

	CamLayer->WorkLayer( $inCAM, $lName );

	# Decide if add schema and if add fixed (max size of schema) or dynamic schema

	my $addSchema        = 1;
	my $schemaFrameTB    = 73;    # mm max size frame top+bot
	my $schemaFrameLR    = 50;    # mm max size frame left+right
	my $minSchemaFrameTB = 5;     # mm min size
	my $minSchemaFrameLR = 26;    # mm min size

	my $placeForSchemaV = $self->{"maxH"} - ( $lim{"yMax"} - $lim{"yMin"} );    # vertical place
	my $placeForSchemaH = $self->{"maxW"} - ( $lim{"xMax"} - $lim{"xMin"} );    # horizontal place

	# Decide for fixed or dynamic schema
	my $dynamicV = $placeForSchemaV < $schemaFrameTB ? 1 : 0;
	my $dynamicH = $placeForSchemaH < $schemaFrameLR ? 1 : 0;

	# Dont place schema if no vertical space (less than 5mm), or if horizontal space smaller than 26 (width of semach marks)

	if ( $placeForSchemaV < $minSchemaFrameTB || $placeForSchemaH < $minSchemaFrameLR ) {
		$addSchema = 0;
	}

	# compute position of outer "thin" frame  (dynamic or fixed)
	my %frLim = ();

	$frLim{"xMin"} = $dynamicH ? -$placeForSchemaH / 2               : -25;
	$frLim{"xMax"} = $dynamicH ? $lim{"xMax"} + $placeForSchemaH / 2 : $lim{"xMax"} + 25;
	$frLim{"yMin"} = $dynamicV ? -$placeForSchemaV / 2               : -37.5;
	$frLim{"yMax"} = $dynamicV ? $lim{"yMax"} + $placeForSchemaV / 2 : $lim{"yMax"} + 37.5;

	if ($addSchema) {

		CamLayer->WorkLayer( $inCAM, $lName );

		# Add semach marks
		my %lb = ( "x" => $frLim{"xMin"} + 9.37, "y" => $frLim{"yMin"} + 6.72 );
		CamSymbol->AddPad( $inCAM, "semach_mark", \%lb );

		my %lt = ( "x" => $frLim{"xMin"} + 9.37, "y" => $frLim{"yMax"} - 6.72 );
		CamSymbol->AddPad( $inCAM, "semach_mark", \%lt );

		my %rt = ( "x" => $frLim{"xMax"} - 9.37, "y" => $frLim{"yMax"} - 6.72 );
		CamSymbol->AddPad( $inCAM, "semach_mark", \%rt );

		my %rb = ( "x" => $frLim{"xMax"} - 9.37, "y" => $frLim{"yMin"} + 6.72 );
		CamSymbol->AddPad( $inCAM, "semach_mark", \%rb );

		# Add frame 1
		$inCAM->COM(
					 "sr_fill",
					 "type"            => "solid",
					 "solid_type"      => "surface",
					 "step_margin_x"   => $frLim{"xMin"} + 4.8,
					 "step_margin_y"   => $frLim{"yMin"} + 2.5,
					 "step_max_dist_x" => "0",
					 "step_max_dist_y" => "0",
					 "consider_feat"   => "yes",
					 "feat_margin"     => "1",
					 "dest"            => "layer_name",
					 "layer"           => $lName
		);

		if ($addDim) {

			# Add big text
			my %bigTextPos = ( "x" => -10, "y" => $lim{"yMax"} * 3 / 4 );
			my $bigText = ( $lim{"xMax"} - $lim{"xMin"} ) . " x " . ( $lim{"yMax"} - $lim{"yMin"} ) . " mm";
			CamSymbol->AddText( $inCAM, $bigText, \%bigTextPos, 4.2, 1, ($lType eq "bot" ? 1:0), "negative", 270 );
			 

			# Add small text

			my %smallTextPos = ( "x" => $frLim{"xMin"} + 3 + ($lType eq "bot" ? -2:0), "y" => $frLim{"yMin"} + 3 );
			my $smallText = ( $frLim{"xMax"} - $frLim{"xMin"} ) . " x " . ( $frLim{"yMax"} - $frLim{"yMin"} ) . "";
			CamSymbol->AddText( $inCAM, $smallText, \%smallTextPos, 2, 1, ($lType eq "bot" ? 1:0), undef, 90 );
		}

		# Add frame

		my @coord = ();

		my %p1 = ( "x" => $frLim{"xMin"}, "y" => $frLim{"yMin"} );
		my %p2 = ( "x" => $frLim{"xMin"}, "y" => $frLim{"yMax"} );
		my %p3 = ( "x" => $frLim{"xMax"}, "y" => $frLim{"yMax"} );
		my %p4 = ( "x" => $frLim{"xMax"}, "y" => $frLim{"yMin"} );
		push( @coord, \%p1 );
		push( @coord, \%p2 );
		push( @coord, \%p3 );
		push( @coord, \%p4 );

		# frame 100µm width around pcb (fr frame coordinate)
		CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r300", "positive" );

	}
	else {

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
		CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r300", "positive" );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::DataOutput::ExportEtch';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my $export = ExportEtch->new( $inCAM, $jobId, 0.25 );
	$export->Output();

	#print $test;

}

1;

