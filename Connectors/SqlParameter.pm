

package Connectors::SqlParameter;

use utf8;

sub new {
	my $self = shift;

	my $name   = shift;
	my $dbType = shift;
	my $value  = shift;

	$self = {};
	bless $self;

	$self->{"name"}   = $name;
	$self->{"dbType"} = $dbType;
	$self->{"value"}  = $value;

	bless($self);

	return $self;
}

1;