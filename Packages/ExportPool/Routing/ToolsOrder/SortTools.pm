
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::StepCheck::StepCheck;

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

sub SortTools {
	my $self       = shift;
	my $toolQueues = shift;


	my @uniTools = $self->__GetUniqTools($toolQueues);
	
	my $qNotEmpty = scalar(map { @{ $toolQueues->{$_} } } keys $toolQueues);
	
	while ($qNotEmpty){
		
		# 1) Choose next current tool
		my $currTool = $self->__ChooseNextTool($toolQueues);
		
		# 2) Move all tools from queues tops to final queue
		
		
		$qNotEmpty = scalar(map { @{ $toolQueues->{$_} } } keys $toolQueues);
	}
	
	# Go through final queue and sort tools by compensation in each group
	
	
 
}

sub __ChooseNextTool {
	my $self       = shift;
	my @uniTools   = @{ shift(@_) };
	my $toolQueues = shift;

	my $next = undef;

	# Find "unique tool" on top of queues. ("unique tool" one by one)

	for ( my $i = 0 ; $i < scalar(@uniTools) ; $i++ ) {

		foreach my $stepId ( keys $toolQueues ) {

			my @actQueue = @{ $toolQueues->{$stepId} };

			if ( scalar(@actQueue) ) {

				# 1) Test if top of queue is wanted tool
				if ( $actQueue[0]->GetToolSize() == $uniTools[$i] ) {

					unless ( defined $next ) {
						$next = $i;
					}

					# This is candidate on wanted tool
					# Test if same tool is contained in some queues on another position
					# If so, this is not tool what we want, take another

					# all tools from all queues (except tools on top of queuq)
					my @buffTools = map  { @{ $toolQueues->{$_} }[ -scalar( @{ $toolQueues->{$_} } ) .. -1 ] } keys $toolQueues;
					my @sameTools = grep { $_->GetToolSize() == $uniTools[$i] } @buffTools;

					if ( scalar(@sameTools) == 0 ) {
						$next = $uniTools[$i];
					}
					else {
						last;    # go and search next unique tool
					}
				}
			}
		}

	}

	return $next;
}

sub __GetUniqTools {
	my $self       = shift;
	my $toolQueues = shift;

	my @uniTools = ();

	my @allTools = map { @{ $toolQueues->{$_} } } keys $toolQueues;

	foreach my $chainTool (@allTools) {

		my $exist = scalar( grep { $_ == $chainTool->GetToolSize() } @uniTools );

		unless ($exist) {
			push( @uniTools, $chainTool->GetToolSize() );
		}
	}
 
	@uniTools = sort ({$a<=>$b} @uniTools);

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

