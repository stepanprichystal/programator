
#-------------------------------------------------------------------------------------------#
# Description: Base class for all layout class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::WizardModelBase;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"__CLASS__"} = caller();

	$self->{"jsonStorable"} = JsonStorable->new();
	$self->{"settings"}     = {};

	return $self;

}

sub SetShowPreview {
	my $self = shift;

	$self->{"showPreview"} = shift;

}

sub GetShowPreview {
	my $self = shift;

	return $self->{"showPreview"};

}

#
sub ExportCreatorSettings {
	my $self = shift;

	my $serialized = $self->{"jsonStorable"}->Encode( $self->{"settings"} );

	return $serialized;

}
#
sub ImportCreatorSettings {
	my $self       = shift;
	my $serialized = shift;

	die "Serialized data are empty" if ( !defined $serialized || $serialized eq "" );

	my $data = $self->{"jsonStorable"}->Decode($serialized);

	# Do check if some keys are not missing or if there are some extra
	my @newSettings = keys %{$data};
	my @oldSettings = keys %{ $self->{"settings"} };

	my %hash;
	$hash{$_}++ for ( @newSettings, @oldSettings );

	my @wrongKeys = grep { $hash{$_} != 2 } keys %hash;

	die "Import settings keys do not match with object setting keys (keys: " . join( "; ", @wrongKeys ) . " )" if (@wrongKeys);

	$self->{"settings"} = $data;

}

# Important because of serialize class
sub TO_JSON { return { %{ shift() } }; }

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

