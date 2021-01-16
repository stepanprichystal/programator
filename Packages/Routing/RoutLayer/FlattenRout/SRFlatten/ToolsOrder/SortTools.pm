
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::ToolsOrder::SortTools;

#3th party library
use utf8;
use strict;
use warnings;

#local library
#use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';

#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# More types of sorting:
# BTRL -  from BOT -> TOP -> RIGHT -> LEFT
# BTRL -  from BOT -> TOP -> LEFT -> RIGHT
sub SortOutlineTools {
	my $self          = shift;
	my $outlineChains = shift;
	my $seqType       = shift;    # SEQUENCE_BTRL / SEQUENCE_BTLR

	my $tol = 10;                 # pcb are split to  columns. Column contain outlines, which has footdown in this column
	my @sortedChains = $self->__SortByStartPoint( $outlineChains, $tol, $seqType );

	my @final = ();

	foreach my $sCh (@sortedChains) {
		my %inf = ( "chainGroupId" => $sCh->{"chainGroupId"}, "chainOrder" => $sCh->{"chainTool"}->GetChainOrder() );
		push( @final, \%inf );
	}

	return @final;
}

# More types of sorting:
# BTRL -  from BOT -> TOP -> RIGHT -> LEFT
# BTRL -  from BOT -> TOP -> LEFT -> RIGHT
sub __SortByStartPoint {
	my $self       = shift;
	my @unsortedCh = @{ shift(@_) };    #array of hashes with starting point of chain
	my $tol        = shift;             #tolerance for chains in same column in mm
	my $seqType    = shift;             # SEQUENCE_BTRL / SEQUENCE_BTLR

	my @sortedCh = ();                  #final sorted array
	my $isSorted = 0;

	my @columnByX = ();

	@unsortedCh = sort { $a->{coord}->{x} <=> $b->{coord}->{x} } @unsortedCh;

	#$seqType = EnumsRout->SEQUENCE_BTRL;

	#sort by X value
	if ( $seqType eq EnumsRout->SEQUENCE_BTRL ) {

		while ( !$isSorted ) {

			#take last one largest X point value
			my $largestX = $unsortedCh[$#unsortedCh]->{coord}->{x};

			#test if more chain has same X coordinate
			my $idxOfMaxY = -1;
			my $max       = -1;

			for ( my $i = 0 ; $i < scalar(@unsortedCh) ; $i++ ) {
				if ( $unsortedCh[$i]->{coord}->{x} == $largestX && $unsortedCh[$i]->{coord}->{y} > $max ) {

					$max       = $unsortedCh[$i]->{coord}->{y};
					$idxOfMaxY = $i;
				}
			}

			#get Y value of most right point
			my $yOflargestX = $unsortedCh[$idxOfMaxY]->{coord}->{y};

			#get points, which X coordinate is larger then ($largestX - $tol)
			@columnByX = grep { $_->{coord}->{x} >= $largestX - $tol } @unsortedCh;

			#remove selected points from @unsortedCh array
			@unsortedCh = @unsortedCh[ 0 .. $#unsortedCh - $#columnByX - 1 ];

			#sort selected points by their Y coordinate. Ascending
			@columnByX = sort { $a->{coord}->{y} <=> $b->{coord}->{y} } @columnByX;

			#sort selected point by Y coordinate (ascending) and push to @sortedCh array
			push @sortedCh, ( map { $_ } @columnByX );

			$isSorted = 1 if ( scalar(@unsortedCh) == 0 );

		}

	}
	elsif ( $seqType eq EnumsRout->SEQUENCE_BTLR ) {

		while ( !$isSorted ) {

			#take last first smaller X point value
			my $smallestX = $unsortedCh[0]->{coord}->{x};

			#test if more chain has same X coordinate
			my $idxOfMaxY = -1;
			my $max       = -1;

			for ( my $i = 0 ; $i < scalar(@unsortedCh) ; $i++ ) {
				if ( $unsortedCh[$i]->{coord}->{x} == $smallestX && $unsortedCh[$i]->{coord}->{y} > $max ) {

					$max       = $unsortedCh[$i]->{coord}->{y};
					$idxOfMaxY = $i;
				}
			}

			#get Y value of most right point
			my $yOflargestX = $unsortedCh[$idxOfMaxY]->{coord}->{y};

			#get points, which X coordinate is larger then ($largestX + $tol)
			@columnByX = grep { $_->{coord}->{x} < $smallestX + $tol } @unsortedCh;

			#remove selected points from @unsortedCh array
			@unsortedCh = @unsortedCh[ $#columnByX + 1 .. $#unsortedCh];
			
			#sort selected points by their Y coordinate. Ascending
			@columnByX = sort { $a->{coord}->{y} <=> $b->{coord}->{y} } @columnByX;

			#sort selected point by Y coordinate (ascending) and push to @sortedCh array
			push @sortedCh, ( map { $_ } @columnByX );

			$isSorted = 1 if ( scalar(@unsortedCh) == 0 );

		}
	}

	return @sortedCh;
}

# $toolQueues hash of chains
# keys are step guid and value is array of object (type of UniChainTool)
# Return sorted array of items, by alghorithm
# "item" is array og cstep chain group represent as hash, where key is step id and value is  object type of UniChainTool
sub SortNotOutlineTools {
	my $self        = shift;
	my $toolQueues  = shift;
	my $outlineTool = shift;    # if defined, consider outline tool during sorting

	my @finalQueue = ();
	my @uniTools   = $self->__GetUniqTools($toolQueues);

	my $qNotEmpty = scalar( map { @{ $toolQueues->{$_} } } keys $toolQueues );

	while ($qNotEmpty) {

		# 1) Choose next current tool
		my $currTool = $self->__ChooseNextTool( \@uniTools, $toolQueues, $outlineTool );

		# 2) Move all tools from queues tops to final queue
		$self->__PutToFinalQueue( \@finalQueue, $toolQueues, $currTool );

		# 3) Test if queues are empty
		$qNotEmpty = scalar( map { @{ $toolQueues->{$_} } } keys $toolQueues );
	}

	return @finalQueue;
}

sub __PutToFinalQueue {
	my $self       = shift;
	my $finalQueue = shift;
	my $toolQueues = shift;
	my $currTool   = shift;

	# provide that chain with same compensation are processed in sequence
	my @compOrder = ( EnumsRout->Comp_NONE, EnumsRout->Comp_CW, EnumsRout->Comp_CCW, EnumsRout->Comp_RIGHT, EnumsRout->Comp_LEFT );

	foreach my $comp (@compOrder) {

		foreach my $chainGroupId ( sort { $a cmp $b } keys $toolQueues ) {

			if ( scalar( @{ $toolQueues->{$chainGroupId} } ) == 0 ) {
				next;
			}

			# check if tool on top of quue has requesteed diameter and comp
			while (    scalar( @{ $toolQueues->{$chainGroupId} } )
					&& $toolQueues->{$chainGroupId}->[0]->GetChainSize() == $currTool
					&& $toolQueues->{$chainGroupId}->[0]->GetComp() eq $comp )
			{

				my %inf = ( "chainGroupId" => $chainGroupId, "chainOrder" => ( shift @{ $toolQueues->{$chainGroupId} } )->GetChainOrder() );

				push( @{$finalQueue}, \%inf );

			}
		}
	}
}

sub __ChooseNextTool {
	my $self        = shift;
	my @uniTools    = @{ shift(@_) };
	my $toolQueues  = shift;
	my $outlineTool = shift;            # if defined, consider outline tool during sorting

	my $next = undef;

	my @nextCandidates = ();            # tools, which are candidates on current tool

	# Find "unique tool" on top of queues. ("unique tool" one by one)

	for ( my $i = 0 ; $i < scalar(@uniTools) ; $i++ ) {

		foreach my $chainGroupId ( sort { $a cmp $b } keys $toolQueues ) {

			my @actQueue = @{ $toolQueues->{$chainGroupId} };

			if ( scalar(@actQueue) ) {

				# 1) Test if top of queue is wanted tool
				if ( $actQueue[0]->GetChainSize() == $uniTools[$i] ) {

					# This is candidate on wanted tool
					# Test if same tool is contained in some queues on another position
					# If so, this is not tool what we want, but it is a possible candidate

					# all tools from all queues (except tools on top of queuq)
					my @buffTools = map { @{ $toolQueues->{$_} }[ -( scalar( @{ $toolQueues->{$_} } ) - 1 ) .. -1 ] } keys $toolQueues;

					# consider here "outline tools" (can have same diameter too)
					if ( defined $outlineTool ) {
						push( @buffTools, $outlineTool );
					}

					my @sameTools = grep { $_->GetChainSize() == $uniTools[$i] } @buffTools;

					if ( scalar(@sameTools) == 0 ) {
						$next = $uniTools[$i];
						last;
					}
					else {
						push( @nextCandidates, $uniTools[$i] );
						last;    # go and search next unique tool
					}
				}
			}
		}

		if ($next) {
			last;
		}

	}

	# Choose "next" tool, which is not contained in some queues on another position
	# If there is not such a tool, take smaller tool diameter from candidates (tools are sorted ASC)
	if ( !defined $next && scalar(@nextCandidates) ) {

		$next = $nextCandidates[0];

	}

	return $next;
}

sub __GetUniqTools {
	my $self       = shift;
	my $toolQueues = shift;

	my @uniTools = ();

	my @allTools = map { @{ $toolQueues->{$_} } } keys $toolQueues;

	foreach my $chainTool (@allTools) {

		my $exist = scalar( grep { $_ == $chainTool->GetChainSize() } @uniTools );

		unless ($exist) {
			push( @uniTools, $chainTool->GetChainSize() );
		}
	}

	@uniTools = sort ( { $a <=> $b } @uniTools );

	return @uniTools;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

