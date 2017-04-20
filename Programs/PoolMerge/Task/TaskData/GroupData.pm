
#-------------------------------------------------------------------------------------------#
# Description: Contain data parsed form pool xml, which will be used by "pool merger" groups
# This data will be passed to each group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::Task::TaskData::GroupData;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);


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
 
	# child job info
	my @ordersInfo = ();
	$self->{"ordersInfo"} = \@ordersInfo;
	
	# name of file for manager group comunication
	$self->{"infoFile"} = undef;

	return $self;
}

sub GetJobNames {
	my $self = shift;

	my @names = map { $_->{"jobName"} } @{ $self->{"ordersInfo"} };
	
	@names = uniq(@names);

	return @names;
}

sub GetOrderNames {
	my $self = shift;

	my @names = map { $_->{"orderId"} } @{ $self->{"ordersInfo"} };

	return @names;
}

sub GetPnlDim {
	my $self = shift;

	return %{ $self->{"pnlDim"} };
}

sub SetPnlDim {
	my $self = shift;

	$self->{"pnlDim"} = shift;
}

sub GetOrdersInfo {
	my $self = shift;

	return @{ $self->{"ordersInfo"} };
}

sub SetOrdersInfo {
	my $self = shift;

	return $self->{"ordersInfo"} = shift;
}

sub GetInfoFile {
	my $self = shift;

	return  $self->{"infoFile"};
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

