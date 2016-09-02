
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::UnitBase;

# Abstract class #

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupWrapperForm';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	#$self->{"jobId"} = shift;
	#$self->{"title"} = shift;
	
	$self->{"unitId"} = undef;
	$self->{"form"} = undef;    #form which represent GUI of this group

	$self->{"unitExport"} = undef;

	$self->{"groupData"} = undef;

	return $self;
}

 

sub InitForm {
	my $self   = shift;
	my $parent = shift;

	#my $inCAM        = shift;

	$self->{"form"} = GroupWrapperForm->new( $parent, $self->{"unitId"} );

	$self->{"form"}->Init( $self->{"unitId"} );

}

sub GetExportClass{
	my $self = shift;
	
	return $self->{"unitExport"};
}


sub ProcessItemResult {
	my $self       = shift;
	my $id         = shift;
	my $result     = shift;
	my $group      = shift;
	my $errorsStr  = shift;
	my $warningStr = shift;

	my $item = $self->{"groupData"}->{"itemsMngr"}->CreateExportItem( $id, $result, $group, $errorsStr, $warningStr );
	$self->{"form"}->AddItem($item);
}

sub ProcessGroupEnd {
	my $self       = shift;
	
}

sub ProcessProgress {
	my $self       = shift;
	my $value       = shift;
	$self->{"groupData"}->SetProgress($value);
	
}

sub GetProgress {
	my $self = shift;
	return $self->{"groupData"}->GetProgress();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
