
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::Helpers::NCHelper;

#3th party library
use strict;
use warnings;
use File::Copy;
use Try::Tiny;
use List::MoreUtils qw(uniq);
use List::Util qw[max min];

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsDrill';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::TifFile::TifNCOperations';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamRouting';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Smaller value means higher priority
# Layer with lower priority, will be processed by machine later, than layer with higher priority
# Example of final nc file:
# 1) File header
# 2) Layer blind top
# 3) Layer plated rout
# 4) Layer through drill
# 5) Tool definition (Footer)
sub SortLayersByRules {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @ordered = ();

	my %priority = ();

	# plated layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_plt_dcDrill }    = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cDrill }     = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cFillDrill } = 0;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillBot } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nFillDrill }    = 1030;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nDrill }    = 1030;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fDrill }    = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fcDrill }   = 1040;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillTop } = 1070;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillBot } = 1070;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nMill }    = 1080;

	# nplted layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nDrill }   = 2010;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } = 2020;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } = 2030;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nMill }    = 2040;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_rsMill }   = 2050;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_frMill }   = 2060;

	#1) sort by priority bz tep of layer

	my @sorted = sort { $priority{ $b->{"type"} } <=> $priority{ $a->{"type"} } } @layers;

	#2) sort by unique number in layer, if layer such number contains
	# this provide functionality, that layers with lower number, will be
	# processed on NC machine before layer with higher number

	#split layers according same type
	my @splitted = ();

	my $lBefore;
	my @group = ();
	for ( my $i = 0 ; $i < scalar(@sorted) ; $i++ ) {

		my $l = $sorted[$i];

		if ( $lBefore->{"type"} && $lBefore->{"type"} eq $l->{"type"} ) {
			push( @group, $l );
		}
		else {
			if ( scalar(@group) ) {
				my @tmp = @group;
				push( @splitted, \@tmp );
			}
			@group = ();
			push( @group, $l );
		}
		$lBefore = $l;

		if ( $i == scalar(@sorted) - 1 ) {

			my @tmp = @group;
			push( @splitted, \@tmp );
		}
	}

	#now sort each group in @splitted
	for ( my $i = 0 ; $i < scalar(@splitted) ; $i++ ) {

		my $g = $splitted[$i];

		#add key (number in layer) to every item for sorting
		foreach ( @{$g} ) {
			my ($num) = $_->{"gROWname"} =~ m/[\D]*(\d*)/g;

			if ( $num eq "" ) { $num = 0; }

			$_->{"key"} = $num;
		}

		# sort layers example: fz_c3, fz_c1, fz_c2, => fz_c1, fz_c2, fz_c3
		my @sortedG = sort { $b->{"key"} <=> $a->{"key"} } @{$g};

		$splitted[$i] = \@sortedG;
	}

	#join splitted groups
	my @sorted2 = ();

	foreach my $g (@splitted) {

		push( @sorted2, @{$g} );
	}

	return @sorted2;
}

#Tell what file header will be used, when theese layers will be merged
sub GetHeaderLayer {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my %priority = ();

	# plated layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_plt_dcDrill }    = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cDrill }     = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cFillDrill } = 0;

	$priority{ EnumsGeneral->LAYERTYPE_plt_nDrill }    = 1010;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } = 1020;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillTop } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillBot } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nMill }    = 1050;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillTop } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillBot } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nFillDrill }    = 1050;

	$priority{ EnumsGeneral->LAYERTYPE_plt_fcDrill } = 1090;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fDrill }  = 1090;

	# nplated layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nDrill }   = 2060;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } = 2020;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } = 2030;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nMill }    = 2010;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_rsMill }   = 2040;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_frMill }   = 2050;

	my @sorted = sort { $priority{ $a->{"type"} } <=> $priority{ $b->{"type"} } } @layers;

	return $sorted[0];

}

# Helper function which move M47 messsage on right place in rout files
# Reason: for rout file, we request for every tool with G83 display info
# message, but messages are placed together above "body" lines after export
sub PutMessRightPlace {
	my $self = shift;
	my $file = shift;
	my @mess = ();

	#find and delete all m47 mess from body
	for ( my $i = scalar( @{ $file->{"body"} } ) - 1 ; $i >= 0 ; $i-- ) {

		my $l = @{ $file->{"body"} }[$i];
		if ( $l->{"line"} =~ /M47,\s*.*/ ) {
			unshift( @mess, $l );
			splice @{ $file->{"body"} }, $i, 1;
		}
	}

	#push mess on right place
	my $messPrev = undef;
	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) + scalar(@mess) ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];
		if ( $l->{"tool"} ) {
			my $m = shift(@mess);

			my $lVal = quotemeta $m->{"line"};

			# if message is same as previous message, do not add message
			if ( !( defined $messPrev && $messPrev->{"line"} =~ $lVal ) ) {

				$m->{"line"} = "\n" . $m->{"line"} . "\n";
				splice @{ $file->{"body"} }, $i, 0, $m;
				$i++;    #skip right added line
			}

			$messPrev = $m;

			unless ( scalar(@mess) ) {
				last;
			}
		}
	}
}

# Helper function add G82 command, where tool has defined G83 command
# Reason: In rout files G82 is missing - bug in InCAM
sub AddG83WhereMissing {
	my $self = shift;
	my $file = shift;

	my $search      = 0;
	my $searchStart = 0;
	my $extraCnt    = 0;
	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) + $extraCnt ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];

		if ( !$search && $l->{"tool"} ) {

			if ( $l->{"line"} =~ /G83/ ) {

				#search for G82 OR next TOOL
				$search      = 1;
				$searchStart = $i;
				next;
			}
		}

		if ( $search && ( $l->{"line"} =~ /G82/ || $l->{"tool"} ) ) {

			# tool was searched before G82
			# it means, G82 is missing
			if ( $l->{"tool"} ) {
				my %g82 = ( "line" => "G82\n" );

				#find place, where new line could be added
				for ( my $j = $i - 1 ; $j >= $searchStart ; $j-- ) {

					my $l2 = @{ $file->{"body"} }[$j];

					if ( $l2->{"line"} =~ /M47,.*/ || $l2->{"line"} =~ /^[\n\t\r]*$/ ) {
						next;
					}
					else {
						splice @{ $file->{"body"} }, $j + 1, 0, \%g82;
						$extraCnt++;
						last;
					}
				}
			}

			$search = 0;
		}
	}
}

# Helper function renumber TOOLs in whole program
# First tool in program => T01, next T02, etc...
# Sort program footer tool definitions ASC T01, T02, etc
sub RenumberToolASC {
	my $self = shift;
	my $file = shift;

	my %t      = ();      #translate table
	my $prefix = "@%";    # helper substitute symbol for renumbering tool

	# 1) Build translate table
	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];

		if ( $l->{"tool"} && !exists $t{ $l->{"tool"} } ) {

			my $tNew = scalar( keys %t ) + 1;
			$t{ $l->{"tool"} } = $tNew;
		}
	}

	# 2) Renumber tools in "body" and "footer"

	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		if ( $file->{"body"}->[$i]->{"tool"} ) {

			my $old = sprintf( "%02d", $file->{"body"}->[$i]->{"tool"} );
			my $new = sprintf( "%02d", $t{ $file->{"body"}->[$i]->{"tool"} } );

			$file->{"body"}->[$i]->{"line"} =~ s/T$old/$prefix$new/;

			# update tool in parsed file
			$file->{"body"}->[$i]->{"tool"} = $t{ $file->{"body"}->[$i]->{"tool"} };
		}
	}

	for ( my $i = 0 ; $i < scalar( @{ $file->{"footer"} } ) ; $i++ ) {

		my $old = sprintf( "%02d", $file->{"footer"}->[$i]->{"tool"} );
		my $new = sprintf( "%02d", $t{ $file->{"footer"}->[$i]->{"tool"} } );

		$file->{"footer"}->[$i]->{"line"} =~ s/T$old/$prefix$new/;

		# update tool in parsed file
		$file->{"footer"}->[$i]->{"tool"} = $t{ $file->{"footer"}->[$i]->{"tool"} };
	}

	#  sustitute prefix with "T"

	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		$file->{"body"}->[$i]->{"line"} =~ s/$prefix/T/ if ( $file->{"body"}->[$i]->{"tool"} );

	}

	for ( my $i = 0 ; $i < scalar( @{ $file->{"footer"} } ) ; $i++ ) {

		$file->{"footer"}->[$i]->{"line"} =~ s/$prefix/T/;
	}

	# Sort footer tools
	my @sorted = sort { $a->{"tool"} <=> $b->{"tool"} } @{ $file->{"footer"} };

	$file->{"footer"} = \@sorted;

}

# search drilled number in file and change:
# - Cu thickness mark
# - Add core mark, if exist
sub ChangeDrilledNumber {
	my $self        = shift;
	my $file        = shift;
	my $cuThickMark = shift;
	my $coreMark    = shift;

	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];

		if ( $l->{"line"} =~ m/(m97,[a-f][\d]+)([\/\-\:\+]{0,2})(\D*)/i ) {

			my $pcbid   = $1;
			my $machine = $3;

			my $newDrillNum = $pcbid . $cuThickMark . $machine . " " . $coreMark;

			$newDrillNum =~ s/[\n\t\r]//;
			$newDrillNum .= "\n";

			#$l
			@{ $file->{"body"} }[$i]->{"line"} =~ s/(m97,[a-f][\d]+)([\/\-\:\+]{0,2})(\D*)/$newDrillNum/i;

			last;
		}
	}
}

sub UpdateNCInfo {
	my $self      = shift;
	my $jobId     = shift;
	my @info      = @{ shift(@_) };
	my $errorMess = shift;

	my $result = 1;

	my $infoStr = $self->__BuildNcInfo( \@info );

	eval {

		# TODO this is temporary solution
		#		my $path = GeneralHelper->Root() . "\\Connectors\\HeliosConnector\\UpdateScript.pl";
		#		my $ncInfo = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
		#
		#		print STDERR "path nc info is:".$ncInfo."\n\n";
		#		print STDERR "path script is :".$path."\n\n";
		#		my $f;
		#		open($f, ">", $ncInfo);
		#		print $f $infoStr;
		#		close($f);
		#		system("perl $path $jobId $ncInfo");
		# TODO this is temporary solution

		$result = HegMethods->UpdateNCInfo( $jobId, $infoStr, 1 );
		unless ($result) {

			$$errorMess = "Failed to update NC-info.";
		}

	};
	if ( my $e = $@ ) {

		if ( ref($e) && $e->isa("Packages::Exceptions::HeliosException") ) {

			$$errorMess = $e->{"mess"};
		}

		$result = 0;
	}

	return $result;
}

# Build string "nc info" based on information from nc manager
sub __BuildNcInfo {
	my $self = shift;
	my @info = @{ shift(@_) };

	my $str = "";

	for ( my $i = 0 ; $i < scalar(@info) ; $i++ ) {

		my %item = %{ $info[$i] };

		my @data = @{ $item{"data"} };

		if ( $item{"group"} ) {
			$str .= "\nSkupina operaci:\n";
		}
		else {
			$str .= "\nSamostatna operace:\n";
		}

		foreach my $item (@data) {

			my $row = "[ " . $item->{"name"} . " ] - ";

			my $mach = join( ", ", @{ $item->{"machines"} } );

			$row .= uc($mach) . "\n";

			$str .= $row;
		}

	}

	return $str;
}

sub StoreOperationInfoTif {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $step          = shift;
	my $operationMngr = shift;

	my $tif = TifNCOperations->new($jobId);

	# 1) store operations

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );    # Signal layer cnt

	my @op = ();

	my @opItems = ();
	foreach my $opItem ( $operationMngr->GetOperationItems() ) {

		if ( defined $opItem->GetOperationGroup() ) {

			push( @opItems, $opItem );
			next;
		}

		if ( !defined $opItem->GetOperationGroup() ) {

			# unless operation definition is defined at least in one operations in group operation items
			# process this operation

			my $o = ( $opItem->GetOperations() )[0];

			my $isInGroup = scalar( grep { $_->GetName() eq $o->GetName() }
									map { $_->GetOperations() } grep { defined $_->GetOperationGroup() } $operationMngr->GetOperationItems() );

			push( @opItems, $opItem ) if ( !$isInGroup );

		}

	}

	foreach my $opItem (@opItems) {
		my %opInf = ();

		# Set Operation name
		$opInf{"opName"} = $opItem->GetName();

		my @layers = $opItem->GetSortedLayers();

		# Ser Operation machines
		my @machines = map { $_->{"suffix"} } $opItem->GetMachines();
		$opInf{"machines"} = {};
		$opInf{"machines"}->{$_} = {} foreach @machines;

		# Set if operation contains rout layers
		my $isRout = scalar( grep { $_->{"gROWlayer_type"} eq "rout" } @layers ) ? 1 : 0;
		$opInf{"isRout"} = $isRout;

		my $matThick;
		if ( $layerCnt <= 2 ) {

			$matThick = HegMethods->GetPcbMaterialThick($jobId);
		}
		else {
			my $stackup = Stackup->new( $inCAM, $jobId );
			$matThick = $stackup->GetThickByCuLayer( $layers[0]->{"NCSigStart"} ) / 1000;
		}

		# Set material thickness during operation
		$opInf{"ncMatThick"} = $matThick * 1000;

		# Set operation min standard "not special" slot tool
		$opInf{"minSlotTool"} = undef;

		if ($isRout) {

			foreach my $layer (@layers) {

				my $unitDTM = UniDTM->new( $inCAM, $jobId, $step, $layer->{"gROWname"}, 1 );
				my $tool = $unitDTM->GetMinTool( EnumsDrill->TypeProc_CHAIN, 1 );    # slot tool, default (no special)

				# tool type chain doesn't have exist
				next if ( !defined $tool );

				if ( !defined $opInf{"minSlotTool"} || $tool->GetDrillSize() < $opInf{"minSlotTool"} ) {
					$opInf{"minSlotTool"} = $tool->GetDrillSize();
				}
			}
		}

		# Set operation layers
		@layers = map { $_->{"gROWname"} } @layers;
		$opInf{"layers"} = \@layers;

		push( @op, \%opInf );

	}

	$tif->SetNCOperations( \@op );

	# 2) store rout tool info
	my %toolInfo = ();

	my @layers =
	  map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "rout" && $_->{"gROWname"} ne "score" } CamJob->GetNCLayers( $inCAM, $jobId );
	foreach my $s ( ( map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step ) ), $step ) {

		$toolInfo{$s} = {};

		foreach my $l (@layers) {

			my $rtm = UniRTM->new( $inCAM, $jobId, $s, $l );

			foreach my $ch ( $rtm->GetChains() ) {

				my $outline = scalar( grep { $_->IsOutline() } $ch->GetChainSequences() ) == scalar( $ch->GetChainSequences() ) ? 1 : 0;
				$toolInfo{$s}->{$l}->{ $ch->GetChainTool()->GetChainOrder() } = { "isOutline" => $outline };
			}
		}
	}

	$tif->SetToolInfos( \%toolInfo );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print $test;

}

1;

