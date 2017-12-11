
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::NCHelper;

#3th party library
use strict;
use warnings;
use File::Copy;
use Try::Tiny;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Helpers::GeneralHelper';

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
	$priority{ EnumsGeneral->LAYERTYPE_plt_dcDrill }   = 1010;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } = 1030;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillTop }  = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillBot }  = 1050;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nMill }     = 1060;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nDrill }    = 1070;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cDrill }    = 1080;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fDrill }    = 1090;

	# nplted layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } = 2010;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } = 2020;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nMill }    = 2030;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_rsMill }   = 2040;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_frMill }   = 2050;

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
	$priority{ EnumsGeneral->LAYERTYPE_plt_dcDrill }   = 1100;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } = 1030;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillTop }  = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillBot }  = 1050;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nMill }     = 1060;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nDrill }    = 1010;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cDrill }    = 1080;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fDrill }    = 1090;

	# nplated layer are merged together
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print $test;

}

1;

