
#-------------------------------------------------------------------------------------------#
# Description: Helper class, which holds information about existing>;
# - operations on technical procedure
# - possible groups of operations on technical procedure
# - units, which contain info which layer merge, what is name of final nc file etc (OperationItem.pm)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::OperationMngr;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Export::NCExport::Operation::OperationItem';
use aliased 'Packages::Export::NCExport::Operation::OperationDef';
use aliased 'Packages::Export::NCExport::Operation::OperationGroup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $self = shift;
	$self = {};
	bless $self;

	my @operDefs = ();
	$self->{"operDefs"} = \@operDefs;
	my @operGroups = ();
	$self->{"operGroups"} = \@operGroups;
	my @operItems = ();
	$self->{"operItems"} = \@operItems;

	$self->{"operationBuilder"} = undef;

	return $self;

}

sub CreateOperations {
	my $self = shift;

	$self->{"operationBuilder"}->DefineOperations($self);
	$self->__BuildOperationItems();
}

sub GetOperationItems {
	my $self = shift;

	return @{ $self->{"operItems"} };
}

sub GetOperationDef {
	my $self = shift;
	my $name = shift;

	my @o = grep { $_->{"name"} eq $name } @{ $self->{"operDefs"} };

	if ( scalar(@o) ) {
		return $o[0];
	}
	else {
		return 0;
	}
}

sub AddOperationDef {
	my $self       = shift;
	my $name       = shift;
	my $layers     = shift;
	my $pressOrder = shift;

	if (    defined $name
		 && $layers
		 && scalar( @{$layers} )
		 && defined $pressOrder )
	{

		die "Operation definition: $name, already exists" if ( $self->GetOperationDef($name) );

		my $def = OperationDef->new( $name, $layers, $pressOrder );
		push( @{ $self->{"operDefs"} }, $def );

		return $def;
	}
	else {

		return 0;
	}
}

sub AddGroupDef {
	my $self       = shift;
	my $name       = shift;
	my $operations = shift;

	# Group has to have at least one operation
	if ( $operations && scalar( @{$operations} ) >= 1 ) {

		die "Operation group: $name, already exists" if ( grep { $_->{"name"} eq $name } @{$self->{"operGroups"}} );

		my $group = OperationGroup->new( $name, $operations );
		push( @{ $self->{"operGroups"} }, $group );

		return $group;
	}
	else {

		return 0;
	}
}

# Return info, which contains information, which oparaions are merged
# and which machine can process it
sub GetInfoTable {
	my $self = shift;

	my @groupInfoAll = ();

	# this add info for all groups and operation containes in groups
	my @opGroups = @{ $self->{"operGroups"} };
	for ( my $i = 0 ; $i < scalar(@opGroups) ; $i++ ) {

		my %infoHash = ( "group" => 1 );
		my @groupInfo = ();

		my $g = $opGroups[$i];

		my %info = ();
		$info{"name"} = "";

		my @operations = @{ $g->{"operations"} };
		my @names      = ();

		foreach (@operations) {
			push( @names, $_->{"name"} );
		}

		$info{"name"} = join( ", ", @names );
		$info{"groupName"} = $g->{"name"};
		my $opItemTmp = $self->__GetOperationItem( $g->{"name"}, 1 );

		my @mach = map { $_->{"suffix"} } @{ $opItemTmp->{"machines"} };

		$info{"machines"} = \@mach;

		push( @groupInfo, \%info );

		foreach (@operations) {

			my %info2 = ();
			$info2{"name"} = $_->{"name"};
			my $opItemTmp = $self->__GetOperationItem( $_->{"name"}, 0 );

			my @mach = map { $_->{"suffix"} } @{ $opItemTmp->{"machines"} };

			$info2{"machines"} = \@mach;

			push( @groupInfo, \%info2 );
		}

		$infoHash{"data"} = \@groupInfo;
		push( @groupInfoAll, \%infoHash );
	}

	# this add info for operations, which are not contained in groups
	for ( my $i = 0 ; $i < scalar( @{ $self->{"operItems"} } ) ; $i++ ) {

		my $item = ${ $self->{"operItems"} }[$i];

		# only if item is not contained in another item created from group
		unless ( $self->__ReturnGroupItem($item) ) {

			my %infoHash = ( "group" => 0 );
			my @groupInfo = ();

			my @operations = @{ $item->{"operations"} };
			if ( scalar(@operations) ) {

				my %info = ();
				$info{"name"} = $item->{"name"};

				my @mach = map { $_->{"suffix"} } @{ $item->{"machines"} };
				$info{"machines"} = \@mach;

				push( @groupInfo, \%info );
				$infoHash{"data"} = \@groupInfo;
				push( @groupInfoAll, \%infoHash );
			}
		}
	}

	return @groupInfoAll;

}

# Search if operation definition of given item is contained also in
# another operation item created from group definition
sub __ReturnGroupItem {
	my $self = shift;
	my $item = shift;

	my $name = ${ $item->{"operations"} }[0]->{"name"};

	my @opGroups = @{ $self->{"operGroups"} };
	foreach my $g (@opGroups) {

		foreach my $oDef ( @{ $g->{"operations"} } ) {

			if ( $oDef->{"name"} eq $name ) {

				return $g;
			}

		}

	}
}

# All single operations will not be exported for each machine, which can process this
# operation item
# Export only for these machines/operations, which are not included in group operation
# In other words, we want export only 'complete' (eg: m + r + sc1) nc programs and not complete (eg: only m)
sub ReduceMachines {
	my $self = shift;

	#my $machines = shift;
	my $opItem = shift;

	if ( $opItem->{"operationGroup"} ) {
		return 0;
	}

	my @machinesForDel = ();
	my $opDef          = ${ $opItem->{"operations"} }[0];

	#find operation item, which this Operation item is merged in

	#all operation items
	my @items = @{ $self->{"operItems"} };

	foreach my $opSearch (@items) {

		if ( !$opSearch->{"operationGroup"} ) {
			next;
		}

		#all operation definitions of actual operation Item
		my @opSearchOps = @{ $opSearch->{"operations"} };

		#if opDef was found in @opSearchOps, get all machines
		if ( scalar( grep { $opDef->{"name"} eq $_->{"name"} } @opSearchOps ) ) {

			my @m = ();
			$opItem->{"machines"} = \@m;
			last;
		}
	}
}

## All single operations will not be exported for each machine, which can process this
## operation item
## Export only for these machines, which are not included in group operation, which contain
## given operation item
#sub ReduceMachines {
#	my $self = shift;
#
#	#my $machines = shift;
#	my $opItem = shift;
#
#	if ( $opItem->{"operationGroup"} ) {
#		return 0;
#	}
#
#	my @machinesForDel = ();
#	my $opDef          = ${ $opItem->{"operations"} }[0];
#
#	#find operation item, which this Operation item is merged in
#
#	#all operation items
#	my @items = @{ $self->{"operItems"} };
#
#	foreach my $opSearch (@items) {
#
#		if ( !$opSearch->{"operationGroup"} ) {
#			next;
#		}
#
#		#all operation definitions of actual operation Item
#		my @opSearchOps = @{ $opSearch->{"operations"} };
#
#		#if opDef was found in @opSearchOps, get all machines
#		if ( scalar( grep { $opDef->{"name"} eq $_->{"name"} } @opSearchOps ) ) {
#
#			@machinesForDel = @{ $opSearch->{"machines"} };
#			last;
#		}
#	}
#
#	#Redce machines of given operation... Delete machines contain in @machinesForDel
#	if ( scalar(@machinesForDel) ) {
#
#		my $machRef = $opItem->{"machines"};
#
#		for ( my $i = scalar( @{$machRef} ) - 1 ; $i >= 0 ; $i-- ) {
#
#			#if machine is contained in @machinesForDel, delete it
#			if ( scalar( grep { ${$machRef}[$i]->{"id"} eq $_->{"id"} } @machinesForDel ) ) {
#
#				splice @{$machRef}, $i, 1;
#			}
#		}
#	}
#}

# Create units, which contain info which layer merge, what is name of final nc file etc
sub __BuildOperationItems {

	my $self = shift;

	my @groups = @{ $self->{"operGroups"} };
	my @items  = @{ $self->{"operDefs"} };

	# Built Items from group. This must be first, before build single items
	# Because first, machine are assigned to operation items, created from group
	# Then for every another item are machines reduced by machines contained in "Item created from group"

	foreach my $g (@groups) {
		$self->__AddGroupOperationItem($g);
	}

	#Buil Items from single items
	foreach my $i (@items) {
		$self->__AddSingleOperationItem($i);
	}
}

sub __AddSingleOperationItem {
	my $self      = shift;
	my $operation = shift;

	if ($operation) {
		my @ops = ($operation);

		my $item = OperationItem->new( $operation->{"name"}, \@ops );
		push( @{ $self->{"operItems"} }, $item );

		return $item;
	}
	else {

		return 0;
	}
}

sub __AddGroupOperationItem {
	my $self  = shift;
	my $group = shift;

	my $operations = $group->{"operations"};

	if ( $operations && scalar( @{$operations} ) ) {
		my $item = OperationItem->new( $group->{"name"}, $operations, $group );
		push( @{ $self->{"operItems"} }, $item );
		return $item;
	}
	else {

		return 0;
	}
}

# Return operation item by name and group
sub __GetOperationItem {
	my $self    = shift;
	my $name    = shift;
	my $isGroup = shift;

	my @o;

	if ($isGroup) {
		@o = grep { $_->{"name"} eq $name && $_->{"operationGroup"} } @{ $self->{"operItems"} };
	}
	else {
		@o = grep { $_->{"name"} eq $name && !$_->{"operationGroup"} } @{ $self->{"operItems"} };
	}

	if ( scalar(@o) ) {
		return $o[0];
	}
	else {
		return 0;
	}
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

