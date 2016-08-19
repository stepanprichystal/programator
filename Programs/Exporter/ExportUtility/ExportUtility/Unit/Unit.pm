
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Unit::Unit;

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
#use aliased "Packages::Events::Event";
#use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupWrapperForm';
#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	
	

	#$self->{"onCheckEvent"} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub Init {
	my $self = shift;
	my $parent = shift;
 	$self->{"form"} = GroupWrapperForm->new($parent);
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

