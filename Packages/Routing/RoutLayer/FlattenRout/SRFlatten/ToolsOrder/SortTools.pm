
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
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
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub SortOutlineTools {
	my $self          = shift;
	my $outlineChains = shift;

	my @sortedChains = $self->__SortByStartPoint( $outlineChains, 10 );

	my @final = ();

	foreach my $sCh (@sortedChains) {
		my %inf = ( "chainGroupId" => $sCh->{"chainGroupId"}, "chainOrder" => $sCh->{"chainTool"}->GetChainOrder() );
		push( @final, \%inf );
	}

	return @final;
}

sub __SortByStartPoint {

	my $self       = shift;
	my @unsortedCh = @{ shift(@_) };    #array of hashes with starting point of chain
	my $tol        = shift;             #tolerance for chains in same column in mm

	my @sortedCh = ();                  #final sorted array
	my $isSorted = 0;

	#sort by X value - descending
	@unsortedCh = sort { $a->{coord}->{x} <=> $b->{coord}->{x} } @unsortedCh;
	my @columnByX = ();

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
		@columnByX = grep {
			( $_->{coord}->{x} >= $largestX - $tol )

			  #&&
			  #($_->{coord}->{y} <= $yOflargestX)
		} @unsortedCh;

		#remove chose points from @unsortedCh array
		@unsortedCh = @unsortedCh[ 0 .. $#unsortedCh - $#columnByX - 1 ];

		#sort chose points by their Y coordinate. Ascending
		@columnByX = sort { $a->{coord}->{y} <=> $b->{coord}->{y} } @columnByX;

		#sort chose point by Y coordinate (ascending) and push to @sortedCh array
		push @sortedCh, ( map { $_ } @columnByX );

		if ( scalar(@unsortedCh) == 0 ) {
			$isSorted = 1;
		}

	}

	return @sortedCh;
}

# $toolQueues hash of chains
# keys are step guid and value is array of object (type of UniChainTool)
# Return sorted array of items, by alghorithm
# "item" is array og cstep chain group represent as hash, where key is step id and value is  object type of UniChainTool
sub SortNotOutlineTools {
	my $self       = shift;
	my $toolQueues = shift;

	my @finalQueue = ();
	my @uniTools   = $self->__GetUniqTools($toolQueues);

	my $qNotEmpty = scalar( map { @{ $toolQueues->{$_} } } keys $toolQueues );

	while ($qNotEmpty) {

		# 1) Choose next current tool
		my $currTool = $self->__ChooseNextTool( \@uniTools, $toolQueues );

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
	my $self       = shift;
	my @uniTools   = @{ shift(@_) };
	my $toolQueues = shift;

	my $next = undef;

	my @nextCandidates = ();    # tools, which are candidates on current tool

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
					my @buffTools = map  { @{ $toolQueues->{$_} }[ -( scalar( @{ $toolQueues->{$_} } ) - 1 ) .. -1 ] } keys $toolQueues;
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
	if(!defined $next && scalar(@nextCandidates)){
		
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

