#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains calculation about surface area
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamCopperArea;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# return area of gold fingers, if exist
sub GetGoldFingerArea {
	my $self        = shift;
	my $cuThickness = shift;
	my $pcbThick    = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $stepName    = shift;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my %area = ( "area" => 0, "percentage" => 0, "exist" => 0 );
	my @layers = ();

	push( @layers, "c" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) );
	push( @layers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	CamHelper->OpenStep( $inCAM, $jobId, $stepName );

	foreach my $l (@layers) {

		CamHelper->ClearEditor( $inCAM, $jobId, );

		$inCAM->COM( 'flatten_layer', source_layer => $l, target_layer => $l . "__gold__" );
		$inCAM->COM( 'affected_layer', name => $l . "__gold__", mode => "single", affected => "yes" );
		$inCAM->COM( 'filter_reset', filter_name => "popup" );
		$inCAM->COM( 'filter_atr_set', filter_name => 'popup', condition => 'yes', attribute => '.gold_plating' );
		$inCAM->COM('filter_area_strt');
		$inCAM->COM(
					 'filter_area_end',
					 layer          => '',
					 filter_name    => 'popup',
					 operation      => 'select',
					 area_type      => 'none',
					 inside_area    => 'no',
					 intersect_area => 'yes',
					 lines_only     => 'no',
					 ovals_only     => 'no',
					 min_len        => 0,
					 max_len        => 0,
					 min_angle      => 0,
					 max_angle      => 0
		);

		$inCAM->COM('get_select_count');

		if ( $inCAM->GetReply() > 0 ) {
			$inCAM->COM('sel_reverse');
			$inCAM->COM('sel_delete');

			my %areaTmp;

			if ( $l eq "c" ) {
				%areaTmp = $self->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, $stepName, $l . "__gold__", undef, "m" . $l );
			}
			elsif ( $l eq "s" ) {
				%areaTmp = $self->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, $stepName, undef, $l . "__gold__", "m" . $l );
			}

			$area{"area"}       += $areaTmp{"area"};
			$area{"percentage"} += $areaTmp{"percentage"};

		}
		$inCAM->COM( 'affected_layer', name => $l . "__gold__", mode => "single", affected => "no" );
		$inCAM->COM( 'delete_layer', layer => $l . "__gold__" );
	}

	if ( $area{"area"} > 0 ) {
		$area{"exist"} = 1;
	}

	return %area;
}

# Return hash of two values
# "area"
# "percentage"
# Area is computed from profile of step
# If only one layer is measured AND edges are measured too, method take only half of pcb edge thickness
sub GetCuArea {
	my $self        = shift;
	my $cuThickness = shift;
	my $pcbThick    = shift;
	my $inCAM       = shift;
	my $jobName     = shift;
	my $stepName    = shift;
	my $topLayer    = shift;    #first layer
	my $botLayer    = shift;    #second layer

	my $considerHole = shift;   #default is yes (include plated holes)
	my $considerEdge = shift;   #default is no  (inclusde area of panel edges)

	my %result = $self->__GetCuArea(
									 $cuThickness, $pcbThick, 0,     $inCAM, $jobName, $stepName,
									 $topLayer,    $botLayer, undef, undef,  undef,    $considerHole,
									 $considerEdge
	);
	return %result;
}

# Return hash of two values
# "area"
# "percentage"
# Area is computed from given coordinates
# If only one layer is measured AND edges are measured too, method take only half of pcb edge thickness
sub GetCuAreaByBox {
	my $self        = shift;
	my $cuThickness = shift;
	my $pcbThick    = shift;
	my $inCAM       = shift;
	my $jobName     = shift;
	my $stepName    = shift;
	my $topLayer    = shift;    #first layer
	my $botLayer    = shift;    #second layer
	my $areaTmp     = shift;    #area, given in hash with key: xmin, xmax, ymin, ymax

	my $considerHole = shift;   #default is yes (include plated holes)
	my $considerEdge = shift;   #default is no  (inclusde area of panel edges)

	my %result = $self->__GetCuArea(
									 $cuThickness, $pcbThick, 0,     $inCAM, $jobName, $stepName,
									 $topLayer,    $botLayer, undef, undef,  $areaTmp, $considerHole,
									 $considerEdge
	);
	return %result;
}

# Return hash of two values
# "area"
# "percentage"
# Area is computed from profile step, only oncovered area is computed
# If only one layer is measured AND edges are measured too, method take only half of pcb edge thickness
sub GetCuAreaMask {
	my $self        = shift;
	my $cuThickness = shift;
	my $pcbThick    = shift;
	my $inCAM       = shift;
	my $jobName     = shift;
	my $stepName    = shift;
	my $topLayer    = shift;    #first layer
	my $botLayer    = shift;    #second layer
	my $topMask     = shift;    #first mask
	my $botMask     = shift;    #second mask

	my $considerHole = shift;   #default is yes (include plated holes)
	my $considerEdge = shift;   #default is no  (inclusde area of panel edges)

	my %result = $self->__GetCuArea(
									 $cuThickness, $pcbThick, 1,        $inCAM,   $jobName, $stepName,
									 $topLayer,    $botLayer, $topMask, $botMask, undef,    $considerHole,
									 $considerEdge
	);
	return %result;
}

# Return hash of two values
# "area"
# "percentage"
# Area is computed from given coordinates, only oncovered area is computed
# If only one layer is measured AND edges are measured too, method take only half of pcb edge thickness
sub GetCuAreaMaskByBox {
	my $self        = shift;
	my $cuThickness = shift;
	my $pcbThick    = shift;
	my $inCAM       = shift;
	my $jobName     = shift;
	my $stepName    = shift;
	my $topLayer    = shift;    #first layer
	my $botLayer    = shift;    #second layer
	my $topMask     = shift;    #first mask
	my $botMask     = shift;    #second mask
	my $areaTmp     = shift;    #area, given in hash with key: xmin, xmax, ymin, ymax

	my $considerHole = shift;   #default is yes (include plated holes)
	my $considerEdge = shift;   #default is no  (inclusde area of panel edges)

	my %result = $self->__GetCuArea( $cuThickness, $pcbThick, 1,        $inCAM,   $jobName,      $stepName, $topLayer,
									 $botLayer,    $topMask,  $botMask, $areaTmp, $considerHole, $considerEdge );
	return %result;
}

#Open job and step in genesis
sub __GetCuArea {

	my $self         = shift;
	my $cuThickness  = shift;
	my $pcbThick     = shift;
	my $mask         = shift;
	my $inCAM        = shift;
	my $jobName      = shift;
	my $stepName     = shift;
	my $topLayer     = shift;
	my $botLayer     = shift;
	my $topMask      = shift;
	my $botMask      = shift;
	my $areaTmp      = shift;
	my $considerHole = shift;
	my $considerEdge = shift;

	unless ($cuThickness) {
		$cuThickness = JobHelper->GetBaseCuThick( $jobName, $topLayer );
	}

	unless ($pcbThick) {
		$pcbThick = JobHelper->GetFinalPcbThick($jobName);
	}

	#set default value
	unless ( defined $considerHole ) {
		$considerHole = "yes";
	}
	else {
		if ($considerHole) {
			$considerHole = "yes";
		}
		else {
			$considerHole = "no";
		}
	}

	#set default value
	unless ( defined $considerEdge ) {
		$considerEdge = "no";
	}
	else {
		if ($considerEdge) {
			$considerEdge = "yes";
		}
		else {
			$considerEdge = "no";
		}
	}

	unless ($topLayer) {
		$topLayer = "";
	}

	unless ($topMask) {
		$topMask = "";
	}

	unless ($botLayer) {
		$botLayer = "";
	}

	unless ($botMask) {
		$botMask = "";
	}

	my %area = ();
	if ($areaTmp) {

		%area = %{$areaTmp};
	}
	else {

		%area = CamJob->GetProfileLimits( $inCAM, $jobName, $stepName );
	}

	# If consider edge is "yes" AND only one layer is mesured => devide pcb thickness/2
	# That is because, we want compute area/measure only for half oh pcb height

	if ( $considerEdge eq "yes" ) {
		if ( $topLayer eq "" || $botLayer eq "" ) {
			$pcbThick = $pcbThick / 2;
		}
	}

	#my $outFile = EnumsPaths->Client_INCAMTMP . $jobName . "cuarea";

	my $outFile = undef;

	#if(-e $outFile){
	#	unlink($outFile);
	#}

	#my $outFile = "out_file";

	CamHelper->OpenStep( $inCAM, $jobName, $stepName );

	if ($mask) {
		$self->__GetCuAreaMask( $inCAM,        $topLayer,    $botLayer, $topMask, $botMask, $considerHole,
								$considerEdge, $cuThickness, $pcbThick, \%area,   $outFile );
	}
	else {
		$self->__GetCuAreaNoMask( $inCAM, $topLayer, $botLayer, $considerHole, $considerEdge, $cuThickness, $pcbThick, \%area, $outFile );
	}

	my %res = ();

	my @fields = split( /\s+/, $inCAM->GetReply() );

	$res{"area"}       = sprintf "%.2f", ( $fields[0] / 100 );
	$res{"percentage"} = sprintf "%.2f", ( $fields[1] );

	#if ($areaTmp) {
	#unlink $outFile;
	#%res = $self->__ResultFromMessBar($inCAM);
	#}
	#else {
	#	%res = $self->__ResultFromFile($outFile);
	#}

# copper_area,layer1=c,layer2=,drills=yes,y1=25,copper_thickness=18,consider_rout=yes,area=yes,out_layer=sum,x1=5,drills_list=,ignore_pth_no_pad=no,dist_map=no,y_boxes=3,drills_source=matrix,x2=302,out_file=c:\tmp\InCam\f13609cuarea,edges=yes,thickness=788.919,x_boxes=3,resolution=1,resolution_value=25.4,f_type=all,y2=382
# copper_area,layer1=c,layer2=,drills=yes,drills_source=matrix,consider_rout=no,ignore_pth_no_pad=no,edges=yes,copper_thickness=0,drills_list=m\;v1\;sc1,thickness=0,resolution_value=25.4,area=no,f_type=all,out_file=out_file,out_layer=first,x_boxes=3,y_boxes=3,dist_map=yes

	return %res;
}

sub __GetCuAreaNoMask {
	my $self         = shift;
	my $inCAM        = shift;
	my $topLayer     = shift;
	my $botLayer     = shift;
	my $considerHole = shift;
	my $considerEdge = shift;
	my $cuThickness  = shift;
	my $pcbThick     = shift;
	my %area         = %{ shift(@_) };
	my $outFile      = shift;

	$inCAM->COM(
		"copper_area",
		"area"              => "yes",
		"layer1"            => $topLayer,
		"layer2"            => $botLayer,
		"drills"            => $considerHole,
		"drills_source"     => "matrix",
		"drills_list"       => "",
		"consider_rout"     => "yes",
		"ignore_pth_no_pad" => "no",
		"edges"             => $considerEdge,
		"copper_thickness"  => $cuThickness,
		"thickness"         => $pcbThick,
		"resolution"        => 1,
		"resolution_value"  => 25.4,
		"f_type"            => "all",

		#"out_file"          => $outFile,
		"out_layer" => "sum",
		"x_boxes"   => 3,
		"y_boxes"   => 3,
		"dist_map"  => "no",
		"x1"        => $area{"xmin"},
		"x2"        => $area{"xmax"},
		"y1"        => $area{"ymin"},
		"y2"        => $area{"ymax"},
	);
}

sub __GetCuAreaMask {
	my $self         = shift;
	my $inCAM        = shift;
	my $topLayer     = shift;
	my $botLayer     = shift;
	my $topMask      = shift;
	my $botMask      = shift;
	my $considerHole = shift;
	my $considerEdge = shift;
	my $cuThickness  = shift;
	my $pcbThick     = shift;
	my %area         = %{ shift(@_) };
	my $outFile      = shift;

	$inCAM->COM(
		"exposed_area",
		"area"              => "yes",
		"layer1"            => $topLayer,
		"layer2"            => $botLayer,
		"mask1"             => $topMask,
		"mask2"             => $botMask,
		"drills"            => $considerHole,
		"drills_source"     => "matrix",
		"drills_list"       => "",
		"consider_rout"     => "yes",
		"ignore_pth_no_pad" => "no",
		"edges"             => $considerEdge,
		"copper_thickness"  => $cuThickness,
		"thickness"         => $pcbThick,
		"resolution"        => 1,
		"resolution_value"  => 25.4,
		"f_type"            => "all",

		#"out_file"          => $outFile,
		"out_layer" => "sum",
		"x_boxes"   => 3,
		"y_boxes"   => 3,
		"dist_map"  => "no",
		"x1"        => $area{"xmin"},
		"x2"        => $area{"xmax"},
		"y1"        => $area{"ymin"},
		"y2"        => $area{"ymax"},
	);
}

# Return area of profile in square mm
sub GetProfileArea {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $lName = GeneralHelper->GetGUID();

	CamHelper->OpenStep( $inCAM, $jobId, $stepName );

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	$inCAM->COM(
				 "sr_fill",
				 "type"          => "solid",
				 "solid_type"    => "surface",
				 "min_brush"     => "25.4",
				 "cut_prims"     => "no",
				 "polarity"      => "positive",
				 "consider_rout" => "no",
				 "dest"          => "layer_name",
				 "layer"         => $lName,
				 "stop_at_steps" => ""
	);

	my %area = $self->GetCuArea( 0, 1, $inCAM, $jobId, $stepName, $lName, "" );

	

	$inCAM->COM( 'delete_layer', layer => $lName );

	return $area{"area"}*100;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;
	#	my $jobName          = shift;
	#	my $stepName         = shift;
	#	my $layerNameTop     = shift;
	#	my $layerNameBot     = shift;
	#
	#	my $considerHole     = shift;
	#	my $considerEdge     = shift;

	#my $cuThickness = JobHelper->GetBaseCuThick( "f13610", "c" );
	#my $pcbThick = JobHelper->GetFinalPcbThick("f13610");

	use aliased 'CamHelpers::CamCopperArea';

	my $inCAM = InCAM->new();


	my $test = CamCopperArea->GetProfileArea($inCAM, "f13610", "o+1");
	
	print $test."\n";

	#my %test = CamHelpers::CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, "f13610", "panel", "c", "s", 1, 1 );

	#my %test1 = CamHelpers::CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, "F13608", "panel", "c" );

	#my %lim = CamJob->GetLayerLimits( $inCAM, "F13608", "panel", "fr" );

	#my %test1 = CamHelpers::CamCopperArea->GetCuAreaByBox($cuThickness, $pcbThick, $inCAM, "F13608", "panel", "c", "s", \%lim );
	#$inCAM->COM("get_message_bar");
	#print STDERR "TEXT BAR: " . $inCAM->GetReply();

	#my %test2 = CamHelpers::CamCopperArea->GetCuAreaMask($cuThickness, $pcbThick, $inCAM, "F13608", "panel", "c", "s", "mc", "ms" );
	#
	#	print $test2{"area"};
	#	print "\n";
	#	print $test2{"percentage"};
	#
	#	my %test3 = CamHelpers::CopperArea->GetCuAreaMaskByBox( $inCAM, "F13608", "panel", "c", "s", "mc", "ms", \%lim );

	#print $test3{"area"};
	#print "\n";
	#print $test3{"percentage"};
	#my %test3 = CamHelpers::CopperArea->GetCuAreaMask( $inCAM, "F13608", "panel", "c", undef, "mc");

	#	my %test2 = CamHelpers::CopperArea->GetGoldFingerArea($cuThickness, $pcbThick, $inCAM, "F13608", "panel");

	#print $test2{"area"};
	#print "\n";
	#print $test2{"percentage"};

	print 1;

}

1;

 
