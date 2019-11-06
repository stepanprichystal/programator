
#-------------------------------------------------------------------------------------------#
# Description: Builder of procedure for 1v +2v PCB
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderRiFlex;
use base('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderBase');

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::IProcBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';
use aliased 'Packages::Stackup::StackupOperation';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;
}

sub Build {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;

	$self->__BuildSemiProducts( $procViewerFrm, $signalLayers, $stackup );

	$self->__BuildPressing( $procViewerFrm, $signalLayers, $stackup );

}

sub __BuildSemiProducts {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;
	
	
#	my @lamPackages = StackupOperation->GetJoinedFlexRigidPackages($jobId, $stackup);
#
#	foreach my $lamPckg (@lamPackages) {
#
#		if (    $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_FLEX
#			 && $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_RIGID )
#		{
#
#			# find first Cu layer in BOT package
#			my $lName = undef;
#
#			for ( my $i = 0 ; $i < scalar( @{ $lamPckg->{"packageBot"}->{"layers"} } ) ; $i++ ) {
#				if ( $lamPckg->{"packageBot"}->{"layers"}->[$i]->GetType() eq EnumsStack->MaterialType_COPPER ) {
#					$lName = $lamPckg->{"packageBot"}->{"layers"}->[$i]->GetCopperName();
#					last;
#				}
#			}
#
#			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );
#			push( @layers, [ $lName, CamMatrix->GetLayerPolarity( $inCAM, $jobId, $lName ) ] );
#
#		}
#		elsif (    $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_RIGID
#				&& $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_FLEX )
#		{
#
#			# find first Cu layer in TOP package
#			my $lName = undef;
#
#			for ( my $i = scalar( @{ $lamPckg->{"packageTop"}->{"layers"} } ) - 1 ; $i >= 0 ; $i-- ) {
#				if ( $lamPckg->{"packageTop"}->{"layers"}->[$i]->GetType() eq EnumsStack->MaterialType_COPPER ) {
#					$lName = $lamPckg->{"packageTop"}->{"layers"}->[$i]->GetCopperName();
#					last;
#				}
#			}
#
#			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );
#
#			push( @layers, [ $lName, CamMatrix->GetLayerPolarity( $inCAM, $jobId, $lName ) ] );
#		}
#	}
#	
	

	$procViewerFrm->AddGroupSep(Enums->Group_SEMIPRODUC);

	for ( my $i = 0 ; $i < 4 ; $i++ ) {

		my $g = $procViewerFrm->AddGroupStackup($i, Enums->Group_SEMIPRODUC);

		$g->AddCopperRow( $i + 30 );

		if ( $i % 2 == 0 ) {

			$g->AddIsolRow( Enums->RowSeparator_CORE );
			$g->AddCopperRow( $i + 40 );

			my $g = $procViewerFrm->AddGroupSep(1);

		}
		else {

			my $g = $procViewerFrm->AddGroupSep(2);
		}

	}
 $procViewerFrm->AddGroupSep( Enums->Group_PRESSING);
	my $g = $procViewerFrm->AddGroupStackup(10, Enums->Group_PRESSING);

	$g->AddCopperRow(50);
	$g->AddIsolRow( Enums->RowSeparator_PRPG );
	$g->AddCopperRow(60);
	$g->AddIsolRow( Enums->RowSeparator_CORE );
	$g->AddCopperRow(70);

}

sub __BuildPressing {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

