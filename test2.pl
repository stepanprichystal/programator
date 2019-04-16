if ( $result->GetClassResult( OutEnums->Type_DRILL, 1 ) ) {

				my $drillResult = $result->GetClassResult( OutEnums->Type_DRILL, 1 );

				if ($drillResult) {
					$inCAM->COM(
								 "copy_layer",
								 "source_job"   => $jobId,
								 "source_step"  => $self->{"step"},
								 "source_layer" => $drillResult->GetSingleLayer()->GetLayerName(),
								 "dest"         => "layer_name",
								 "dest_step"    => $self->{"step"},
								 "dest_layer"   => $lNameDrillMap,
								 "mode"         => "append"
					);
				}
			}
		}

		my $lData = LayerData->new( $type, $lMain, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map, only if exist holes ($lNameDrillMap ha sto be created)
		if ( CamHelper->LayerExists( $inCAM, $jobId, $lNameDrillMap ) ) {

			# After merging layers, merge tools in DTM
			$inCAM->COM( "tools_merge", "layer" => $lNameDrillMap );

			my $drillMap = $self->__CreateDrillMaps( $lMain, $lNameDrillMap, Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );

			if ($drillMap) {
				$drillMap->SetParent($lData);
				$self->{"layerList"}->AddLayer($drillMap);
			}

			$inCAM->COM( "delete_layer", "layer" => $lNameDrillMap );
		}