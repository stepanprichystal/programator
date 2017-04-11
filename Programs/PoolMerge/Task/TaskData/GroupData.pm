
#-------------------------------------------------------------------------------------------#
# Description: Contain data parsed form pool xml, which will be used by "pool merger" groups
# This data will be passed to each group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::Task::TaskData::GroupData;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless($self);

	# dim where values are in hash (keys: width, height)
	my %dim = ();
	$self->{"pnlDim"} = \%dim;

	# nae of mother job
	$self->{"motherJob"} = undef;

	# all job names, which are merged, except maother job
	my @childJobs = ();
	$self->{"childJobs"} = \@childJobs;

	# child job info
	my @jobsInfo = ();
	$self->{"jobsInfo"} = \@jobsInfo;

	return $self;
}

sub GetMotherJob {
	my $self = shift;

	return $self->{"motherJob"};
}

sub GetPnlDim {
	my $self = shift;

	return %{ $self->{"pnlDim"} };
}

sub SetPnlDim {
	my $self = shift;

	$self->{"pnlDim"} = shift;
}

sub GetChildJobs {
	my $self = shift;

	return @{ $self->{"childJobs"} };
}

sub SetChildJobs {
	my $self = shift;

	return $self->{"childJobs"} = shift;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::PoolMerge->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

