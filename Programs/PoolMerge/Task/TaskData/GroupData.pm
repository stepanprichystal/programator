
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
use JSON;

#local library
use aliased "Enums::EnumsPaths";

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

sub GetPnlW {
	my $self = shift;

	return $self->{"pnlDim"}->{"width"};
}

sub GetPnlH {
	my $self = shift;

	return $self->{"pnlDim"}->{"height"};
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

	return $self->{"infoFile"};
}

sub GetInfoFileVal {
	my $self = shift;
	my $key  = shift;

	my $p = EnumsPaths->Client_INCAMTMPOTHER . $self->{"infoFile"};

	# Read old data
	my %hashData = ();

	my $json = JSON->new();

	if ( open( my $f, "<", $p ) ) {

		my $str = join( "", <$f> );
		%hashData = %{ $json->decode($str) };
		close($f);
	}
	else {
		print STDERR "Info file $p doesn't exist. Cant read value $key";
	}

	return $hashData{$key};
}

# return single pcb count on panel, by order id
sub GetCountOnPanel {
	my $self    = shift;
	my $orderId = shift;

	my @orders = @{ $self->{"ordersInfo"} };
	@orders = grep { $_->{"orderId"} eq $orderId } @orders;

	my $cnt = 0;
	foreach my $ord (@orders) {

		$cnt += @{ $ord->{"pos"} };

	}

	return $cnt;
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

