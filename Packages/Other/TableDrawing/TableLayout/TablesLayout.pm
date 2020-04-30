
#-------------------------------------------------------------------------------------------#
# Description: Layout for tables
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::TablesLayout;
use base qw(Packages::Other::TableDrawing::TableLayout::TableLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Other::TableDrawing::TableLayout::TableLayout';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"tables"} = [];

	$self->{"scaleX"}  = 1;
	$self->{"scaleY"}  = 1;
	$self->{"originX"} = 0;    # this offset do not consider ScaleX
	$self->{"originY"} = 0;    # this offset do not consider ScaleY

	return $self;
}

sub AddTable {
	my $self        = shift;
	my $key         = shift;
	my $origin      = shift // { "x" => 0, "y" => 0 };
	my $borderStyle = shift;
	my $cellOverWrite = shift;

	my $t = TableLayout->new( $key, $origin, $borderStyle, $cellOverWrite );

	push( @{ $self->{"tables"} }, $t );

	return $t;
}

sub DuplicateTable {
	my $self  = shift;
	my $key   = shift;
	my $table = shift;

	my $dupl = dclone($table);

	$dupl->{"key"} = $key;

	push( @{ $self->{"tables"} }, $dupl );

	return $dupl;
}

sub GetAllTables {
	my $self = shift;

	return @{ $self->{"tables"} };

}

#sub SetScaleX {
#	my $self = shift;
#
#	$self->{"scaleX"} = shift;
#}
#
#sub SetScaleY {
#	my $self = shift;
#
#	$self->{"scaleY"} = shift;
#}
#
#sub SetOriginX {
#	my $self = shift;
#
#	$self->{"originX"} = shift;
#}
#
#sub SetOriginY {
#	my $self = shift;
#
#	$self->{"originY"} = shift;
#}
#
#
#
#sub GetScaleX {
#	my $self = shift;
#
#	return $self->{"scaleX"};
#}
#
#sub GetScaleY {
#	my $self = shift;
#
#	return $self->{"scaleY"};
#}
#
#sub GetOriginX {
#	my $self = shift;
#
#	return $self->{"originX"};
#}
#
#sub GetOriginY {
#	my $self = shift;
#
#	return $self->{"originY"};
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

