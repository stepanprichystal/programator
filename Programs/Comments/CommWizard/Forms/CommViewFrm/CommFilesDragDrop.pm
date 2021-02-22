#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommViewFrm::CommFilesDragDrop;

#3th party library
use strict;
use warnings;
use Wx;
use Wx::DND;
use base qw(Wx::FileDropTarget);

#local library
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $filesFrm = shift;
	my $self     = $class->SUPER::new(@_);

	$self->{"filesFrm"} = $filesFrm;

	# DEFINE EVENTS
	$self->{'onAddFileEvt'} = Event->new();

	return $self;
}

sub OnDropFiles {
	my ( $self, $x, $y, $files ) = @_;

	foreach my $f ( @{$files} )
	{
		$self->{"onAddFileEvt"}->Do($f);
	}

	return 1;
}

1;
