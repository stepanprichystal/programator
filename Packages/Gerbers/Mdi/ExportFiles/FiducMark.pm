#-------------------------------------------------------------------------------------------#
# Description: Vyhleda OLEC znacky v Genesisu a jejich souradnice zapise do Gerber file pod nový DCODE.
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::Gerbers::Mdi::ExportFiles::FiducMark;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';

my $FIDMARK_MM   = "5.16120000";
my $FIDMARK_INCH = "0.202815";

sub AddalignmentMark {
	my $self                = shift;
	my $genesis             = shift;
	my $jobName             = shift;
	my $layerName           = shift;
	my $units               = shift;
	my $pathGerber          = shift;
	my $searchMark          = shift;
	my $stepName            = shift;
	my @arrFiducialPosition = ();
	my $valueDcode          = 0;

	$self->_GetCoorFiducial( $genesis, $layerName, $units, $jobName, $stepName, $searchMark );

	my $maxDcode = $self->_GetHighestDcode("$pathGerber");

	# if max code doesnt exist, set fake max code 9, because first dcode in gerbers start with 10
	my $noDcode = 0;
	unless ( defined $maxDcode ) {
		$noDcode  = 1;
		$maxDcode = 9;
	}

	push( @arrFiducialPosition, 'G54D' . ( $maxDcode + 1 ) . '*' );
	for ( my $i = 1 ; $i <= 4 ; $i++ ) {
		push( @arrFiducialPosition,
			      sprintf( "X%010d", sprintf "%3.0f", $featCoor->{"fid$i"}->{'x'} * 1000000 )
				. sprintf( "Y%010d", sprintf "%3.0f", $featCoor->{"fid$i"}->{'y'} * 1000000 )
				. 'D03*' );
	}

	# Temporary solution, for FR4 materials and inner layer, delete one fiducial mark
	# Fr4 cores has only 3 fiduc drill layer
	if (  $layerName =~ /^v\d+/ && HegMethods->GetMaterialKind($jobName) =~ /fr4/i ) {

		my @sorted =
		  sort { ( $b =~ /X(\d+)/ )[0] <=> ( $a =~ /X(\d+)/ )[0] or ( $b =~ /Y(\d+)/ )[0] <=> ( $a =~ /Y(\d+)/ )[0] }
		  grep { $_ =~ /X(\d+)Y(\d+)/ } @arrFiducialPosition;
		  
		 for(my $i= 0;  $i < scalar(@arrFiducialPosition); $i++){
		 	
		 	if($arrFiducialPosition[$i] eq $sorted[0]){
		 		
		 		splice @arrFiducialPosition, $i, 1;
		 		last;
		 	}
		 	
		 }


	}

	my $NEWFILE;
	my $SOURCEFILE;
	open( $NEWFILE,    ">>${pathGerber}_temp" );
	open( $SOURCEFILE, "$pathGerber" );
	my $lastDcode  = '%ADD' . $maxDcode;
	my $existFiduc = 0;
	while (<$SOURCEFILE>) {
		if ( $_ =~ /G75*/ and $existFiduc == 0 ) {
			print $NEWFILE "$_";
			foreach my $line (@arrFiducialPosition) {
				print $NEWFILE "$line\n";
			}
			$existFiduc = 1;

		}

		# when there are more dcodes OR when no anohter dcode are defined
		elsif ( $_ =~ /$lastDcode/ || ( $noDcode && $_ =~ /MOIN/ ) ) {

			print $NEWFILE "$_";
			if ( $units eq 'mm' ) {
				$valueDcode = $FIDMARK_MM;
			}
			else {
				$valueDcode = $FIDMARK_INCH;
			}
			my $newDcode = '%ADD' . ( $maxDcode + 1 ) . 'C,' . $valueDcode . '*%';
			print $NEWFILE "$newDcode\n";
		}
		else {
			print $NEWFILE "$_";
		}

	}
	close $SOURCEFILE;
	close $NEWFILE;
	unlink "$pathGerber";
	rename( "${pathGerber}_temp", "$pathGerber" );

	return $maxDcode + 1;
}

sub _GetCoorFiducial {
	my $self       = shift;
	my $genesis    = shift;
	my $layer      = shift;
	my $units      = shift;
	my $jobName    = shift;
	my $stepName   = shift;
	my $searchMark = shift;

	#$searchMark = 'cross_outer*';
	#$searchMark = 'mask_fiduc*';

	$genesis->COM('clear_layers');
	$genesis->COM( 'display_layer', name => "$layer", display => 'yes', number => '1' );
	$genesis->COM( 'work_layer', name => "$layer" );

	$genesis->COM( 'filter_reset', filter_name => "popup" );
	$genesis->COM( 'filter_set', filter_name => 'popup', update_popup => 'no', include_syms => "$searchMark" );
	$genesis->COM('filter_area_strt');
	$genesis->COM(
				   'filter_area_end',
				   layer          => '',
				   filter_name    => 'popup',
				   operation      => 'select',
				   area_type      => 'none',
				   inside_area    => 'no',
				   intersect_area => 'no'
	);
	$genesis->COM('get_select_count');

	unless ( $genesis->{COMANS} ) {
		$genesis->COM( 'filter_reset', filter_name => "popup" );
		$genesis->COM( 'filter_set', filter_name => 'popup', update_popup => 'no', polarity => 'positive' );
		$genesis->COM(
					   'filter_atr_set',
					   filter_name => 'popup',
					   condition   => 'yes',
					   attribute   => '.pnl_place',
					   text        => "$searchMark",
					   min_int_val => '999',
					   max_int_val => '999'
		);
		$genesis->COM('filter_area_strt');
		$genesis->COM(
					   'filter_area_end',
					   layer          => '',
					   filter_name    => 'popup',
					   operation      => 'select',
					   area_type      => 'none',
					   inside_area    => 'no',
					   intersect_area => 'no'
		);
		$genesis->COM('get_select_count');
	}

	if ( $genesis->{COMANS} ) {
		my $infoFile = $genesis->INFO(
									   'units'       => "$units",
									   'entity_type' => 'layer',
									   'entity_path' => "$jobName/$stepName/$layer",
									   'data_type'   => 'FEATURES',
									   options       => 'select',
									   parse         => 'no'
		);
		my $INFOFILE;
		open( $INFOFILE, $infoFile );

		my $count = 1;
		while (<$INFOFILE>) {
			if ( $_ =~ /^#P/ ) {
				my @points = split /\s+/;

				# 												if (GenesisHelper->countSignalLayers($jobName) > 2) {   							# for multilayer
				# 														unless(GenesisHelper->GetLayerSide($jobName,$stepName,$layer) eq 'inner'){	# for innerlayer
				#																my ($coorXfr, $coorYfr) = _GetCoorRoutFR("$units", $jobName, $stepName);
				#																				# recalculate value with rout layer FR
				#																		$points[1] = $points[1] - $coorXfr;
				#																		$points[2] = $points[2] - $coorYfr;
				#														}
				#												};
				$featCoor->{"fid$count"} = {
											 'x' => $points[1],
											 'y' => $points[2],
				};
				$count++;
			}
		}

		unlink $infoFile;
		close $INFOFILE;
	}

	$genesis->COM( 'display_layer', name => "$layer", display => 'no', number => '1' );
	$genesis->COM( 'filter_reset', filter_name => "popup" );
	return ();
}

sub _GetHighestDcode {
	my $self      = shift;
	my $layerPath = shift;
	my $highestDcode;
	my $f;

	if ( open( $f, "<", "$layerPath" ) ) {
		while (<$f>) {
			if ( $_ =~ /^\%ADD(\d{1,4})/ ) {
				$highestDcode = $1;
			}
		}
		close $f;
	}

	# no dcode in gerber
	unless ( defined $highestDcode ) {
		$highestDcode = undef;
	}

	return ($highestDcode);
}
1;
