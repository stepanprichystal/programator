#-------------------------------------------------------------------------------------------#
# Description: Helper module for counting of job in panel | csv | xml
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::MergeHelper::MergePoolHelper;

#3th party library
#use strict;
#use warnings;

use aliased 'Packages::ProductionPanel::PanelDimension';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub CopyJobToMaster {
	my $self        = shift;
	my $inCAM       = shift;
	my $masterOrder = shift;
	my @jobList     = @_;

	( my $masterJob ) = $masterOrder =~ /([DdFf]\d{5,})/;

	$inCAM->COM( 'open_job', job  => "$masterJob" );
	$inCAM->COM( 'set_step', name => 'o+1' );

	my @slaveJobList = grep { $_ ne $masterJob} @jobList;

	foreach my $oneJob (@slaveJobList) {

		$inCAM->COM( 'open_job', job => "$oneJob", open_win => 'no' );

		$inCAM->COM(
			'copy_entity',
			type          => 'step',
			source_job    => "$oneJob",
			source_name   => 'o+1',
			dest_job      => "$masterJob",
			dest_name     => "$oneJob",
			dest_database => 'incam'
		);

		$inCAM->COM( 'set_step', name => "$oneJob" );
		
		_WriteIdentification( $inCAM, $oneJob, $masterJob);

	}

	# Write identification for Master => o+1
		_WriteIdentification( $inCAM, 'o+1', $masterJob);

	$inCAM->COM('editor_page_close');
	$inCAM->COM( 'set_step', name => "o+1" );
	$inCAM->COM( 'matrix_auto_rows', job => "$masterJob", matrix => 'matrix' );

 #			my $panelSizeName = '';
 #			if ($suffix eq 'xml') {
 #					$panelSizeName = PanelDimension->GetPanelName($inCAM, $masterJob, $file);
 #			}

}

sub _WriteIdentification {
	my $inCAM     = shift;
	my $step      = shift;
	my $masterJob = shift;

	my $nevkladatX = 0;
	my $nevkladatY = 0;
	my $mirrorText;
	my @signalLayers = _GetSignal($inCAM, $masterJob);

	$inCAM->COM( 'set_step', name => "$step" );

	foreach my $layer (@signalLayers) {
		$inCAM->COM('clear_layers');
		$inCAM->COM(
			'affected_layer',
			name     => "",
			mode     => "all",
			affected => "no"
		);
		$inCAM->COM(
			'display_layer',
			name    => "$layer",
			display => 'yes',
			number  => '1'
		);
		$inCAM->COM( 'work_layer', name => "$layer" );

		### mereni rozmeru desky
		$inCAM->INFO(
			units       => 'mm',
			entity_type => 'step',
			entity_path => "$masterJob/$step",
			data_type   => 'PROF_LIMITS'
		);
		my $myDpX = sprintf "%3.3f",
		  ( $inCAM->{doinfo}{gPROF_LIMITSxmax} -
			  $inCAM->{doinfo}{gPROF_LIMITSxmin} );
		my $myDpY = sprintf "%3.3f",
		  ( $inCAM->{doinfo}{gPROF_LIMITSymax} -
			  $inCAM->{doinfo}{gPROF_LIMITSymin} );

		if ( $myDpX >= 25 ) {
			$Xh         = ( $myDpX / 2 );
			$Yh         = ( $myDpY + 2.1 );
			$fontXtop   = 2.35;
			$fontYtop   = 2.35;
			$factorTtop = 1;
		}
		elsif ( $myDpX >= 12 ) {
			$Xh         = ( $myDpX / 2 );
			$Yh         = ( $myDpY + 2.1 );
			$fontXtop   = ( 2.35 / 100 ) * ( ( 100 / 25 ) * $myDpX );
			$fontYtop   = ( 2.35 / 100 ) * ( ( 100 / 25 ) * $myDpX );
			$factorTtop = ( 1 / 100 ) * ( ( 100 / 25 ) * $myDpX );
		}
		else {
			$nevkladatX = 1;
		}

		if ( $myDpY >= 25 ) {
			$Xv          = ( $myDpX - $myDpX - 2.1 );
			$Yv          = ( $myDpY / 2 );
			$fontXleft   = 2.35;
			$fontYleft   = 2.35;
			$factorTleft = 1;
		}
		elsif ( $myDpY >= 12 ) {
			$Xv          = ( $myDpX - $myDpX - 2.1 );
			$Yv          = ( $myDpY / 2 );
			$fontXleft   = ( 2.35 / 100 ) * ( ( 100 / 25 ) * $myDpY );
			$fontYleft   = ( 2.35 / 100 ) * ( ( 100 / 25 ) * $myDpY );
			$factorTleft = ( 1 / 100 ) * ( ( 100 / 25 ) * $myDpY );
		}
		else {
			$nevkladatY = 1;
		}

		my $XhLine1 = ( $Xh - 1 );
		my $XhLine2 = ( $Xh - 4 );
		my $YhLine  = ( $Yh - 1.8 );

		my $YvLine1 = ( $Yv - 1 );
		my $XvLine2 = ( $Yv - 4 );
		my $XvLine  = ( $Xv + 1.8 );

		if (   $layer eq 's'
			or $layer eq 'v3'
			or $layer eq 'v5'
			or $layer eq 'v7' )
		{
			$mirrorText = 'yes';    ## strana spoju "S"
			$angleTest1 = 0;
			$angleTest2 = 90;
			if ( $myDpX < 25 ) {
				$Xh += ( 14 / 100 ) * ( ( 100 / 25 ) * $myDpX );
			}
			else {
				$Xh += 14;
			}
			if ( $myDpY < 25 ) {
				$Yv += ( 14 / 100 ) * ( ( 100 / 25 ) * $myDpY );
			}
			else {
				$Yv += 14;
			}
		}
		else {
			$mirrorText = 'no';    ## strana soucastek "C"
			$angleTest1 = 0;
			$angleTest2 = 270;
		}

		if ( $step eq 'o+1' ) {
			$setName = $masterJob;
		}
		else {
			$setName = $step;
		}

		if ( $nevkladatX == 0 ) {
			$inCAM->COM(
				'add_text',
				attributes => 'no',
				type       => 'string',
				x          => "$Xh",
				y          => "$Yh",
				text       => "$setName",
				x_size     => "$fontXtop",
				y_size     => $fontYtop,
				w_factor   => "$factorTtop",
				polarity   => 'positive',
				angle      => "$angleTest1",
				mirror     => "$mirrorText",
				fontname   => 'standard',
				ver        => '1'
			);

			$inCAM->COM( 'add_polyline_strt ' ); # '
			$inCAM->COM( 'add_polyline_xy', x => "$XhLine1", y => "$Yh" + 1 );
			$inCAM->COM( 'add_polyline_xy', x => "$XhLine2", y => "$Yh" + 1 );
			$inCAM->COM( 'add_polyline_xy', x => "$XhLine2", y => "$YhLine" );
			$inCAM->COM(
				'add_polyline_end',
				attributes    => 'no',
				symbol        => 'r300',
				polarity      => 'positive',
				bus_num_lines => '0',
				bus_dist_by   => 'pitch',
				bus_distance  => '0',
				bus_reference => 'left'
			);
		}

		if ( $nevkladatY == 0 ) {
			$inCAM->COM(
				'add_text',
				attributes => 'no',
				type       => 'string',
				x          => "$Xv",
				y          => "$Yv",
				text       => "$setName",
				x_size     => "$fontXleft",
				y_size     => "$fontYleft",
				w_factor   => "$factorTleft",
				polarity   => 'positive',
				angle      => "$angleTest2",
				mirror     => "$mirrorText",
				fontname   => 'standard',
				ver        => '1'
			);

			$inCAM->COM('add_polyline_strt');  # '
			$inCAM->COM( 'add_polyline_xy', x => "$Xv" - 1, y => "$YvLine1" );
			$inCAM->COM( 'add_polyline_xy', x => "$Xv" - 1, y => "$XvLine2" );
			$inCAM->COM( 'add_polyline_xy', x => "$XvLine", y => "$XvLine2" );
			$inCAM->COM(
				'add_polyline_end',
				attributes    => 'no',
				symbol        => 'r300',
				polarity      => 'positive',
				bus_num_lines => '0',
				bus_dist_by   => 'pitch',
				bus_distance  => '0',
				bus_reference => 'left'
			);
		}

		$inCAM->COM(
			'affected_layer',
			name     => "",
			mode     => "all",
			affected => "no"
		);
		$inCAM->COM(
			'display_layer',
			name    => "$layer",
			display => 'no',
			number  => '1'
		);
	}
}

sub _GetSignal {
	my $inCAM = shift;
	my $jobId = shift;

	my @poleLAYERS = ();
	$inCAM->INFO(
		'entity_type' => 'matrix',
		'entity_path' => "$jobId/matrix",
		'data_type'   => 'ROW'
	);
	my $totalRows = ${ $inCAM->{doinfo}{gROWrow} }[-1];
	for ( $count = 0 ; $count <= $totalRows ; $count++ ) {
		my $rowFilled  = ${ $inCAM->{doinfo}{gROWtype} }[$count];
		my $rowName    = ${ $inCAM->{doinfo}{gROWname} }[$count];
		my $rowContext = ${ $inCAM->{doinfo}{gROWcontext} }[$count];
		my $rowType    = ${ $inCAM->{doinfo}{gROWlayer_type} }[$count];
		if (
			   $rowFilled ne "empty"
			&& $rowContext eq "board"
			&& (   $rowType eq "signal"
				|| $rowType eq "mixed"
				|| $rowType eq "power_ground" )
		  )
		{
			push( @poleLAYERS, $rowName );
		}
	}
	return (@poleLAYERS);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

1;
