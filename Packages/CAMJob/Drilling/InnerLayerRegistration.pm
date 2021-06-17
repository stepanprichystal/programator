#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::InnerLayerRegistration;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Enums' => "StackEnums";
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupBase::StackupBase';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub RequireInnerLayerReg {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $stackup = shift // StackupBase->new($jobId);

	my $require = 0;

	my $jobClassInner = CamJob->GetJobPcbClassInner( $inCAM, $jobId );

	my @allLayers = $stackup->GetAllLayers();

	# Only not empty inner layer
	my $innLayerCnt =
	  scalar( grep { $_->GetType() eq StackEnums->MaterialType_COPPER && $_->GetCopperName() =~ /^v\d+$/ && $_->GetUssage() > 0 }
			  @allLayers )
	  ;

	if (    ( $jobClassInner >= 8 && $innLayerCnt >= 3 )
		 || ( JobHelper->GetIsFlex($jobId) && $innLayerCnt >= 1 ) )
	{
		$require = 1;

	}

	return $require;

}

# Return isolation/cu thick + type for whole stackup
# Do consider plating and cu usage
# Array of hash with keys: thick (in mm); type (cu/isol	)
sub GetInnerLayerDepths {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $stackup = shift // Stackup->new( $inCAM, $jobId );

	my @thicks = $stackup->GetAllLayers();

	my @depths       = ();
	my $curType      = undef;    # cu/isol
	my $curIsolThick = 0;
	for ( my $i = 0 ; $i < scalar(@thicks) ; $i++ ) {

		my $l = $thicks[$i];

		if ( $l->GetType() eq StackEnums->MaterialType_COPPER ) {

			# Hit copper, store isolation thick if exist
			if ( defined $curType && $curType eq "isol" && $curIsolThick > 0 ) {

				my %depthInfo = ();
				$depthInfo{thick} = sprintf( "%.3f", $curIsolThick / 1000 );
				$depthInfo{type} = "isol";
				push( @depths, \%depthInfo );

				$curIsolThick = 0;
			}

			# Store Cu thick
			my %depthInfo = ();

			my $cuThick = $l->GetThick();

			# Add cu plating if not first or last copper layer
			if ( $l->GetCopperNumber() > 1 && $l->GetCopperNumber() < $stackup->GetCuLayerCnt() ) {

				my $IProduct = $stackup->GetProductByLayer( $l->GetCopperName(), 0, 0 );

				$cuThick +=
				  $IProduct->GetIsPlated()
				  ? StackEnums->Plating_STD
				  : 0;
			}

			$depthInfo{thick} = sprintf( "%.3f", $cuThick / 1000 );
			$depthInfo{type} = "cu";

			push( @depths, \%depthInfo );

			$curType = "cu";

		}
		elsif ( $l->GetType() eq StackEnums->MaterialType_CORE || $l->GetType() eq StackEnums->MaterialType_PREPREG ) {

			if ( $curType eq "cu" ) {
				$curIsolThick = $l->GetThick();
			}
			elsif ( $curType eq "isol" ) {
				$curIsolThick += $l->GetThick();

			}

			$curType = "isol";
		}
	}

	return @depths;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Drilling::InnerLayerRegistration';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d321505";

	my $mess = "";

	my @d = InnerLayerRegistration->RequireInnerLayerReg( $inCAM, $jobId );

	print STDERR "Result is: @d, error \n";

}

1;

