
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::Helpers::PnlToJSON;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';
use aliased 'Packages::Polygon::Features::Features::Features';

use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE';
use aliased 'Packages::CAM::SymbolDrawing::Symbol::SymbolBase';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $self = {};
	bless $self;

	# Properties
	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;
	$self->{"step"}  = $step;

	$self->{"jsonStorable"} = JsonStorable->new();

	return $self;
}

sub CheckBeforeParse {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $result = 1;

	# 1) Check if step exist
	unless ( CamHelper->StepExists( $inCAM, $jobId, $step ) ) {

		$$errMess .= "Step: $step doesn't exist";
		$result = 0;

		return $result;

	}

	# 2) Check if nested steps
	my @steps = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $step );

	if ( scalar(@steps) == 0 ) {

		$$errMess .= "No nested step in panel";
		$result = 0;
	}

	return $result;

}

sub ParsePnlToJSON {
	my $self      = shift;
	my $dim       = shift // 1;    # parse dimension
	my $sr        = shift // 1;    # parse steps
	my $srCpn     = shift // 0;    # parse coupon steps
	my $notStdDim = shift // 0;    # assume, profile is not rectangle (4 lines)

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %sett = ();
	$sett{"profFeats"} = undef;
	$sett{"profLim"}   = undef;
	$sett{"areaLim"}   = undef;
	$sett{"profZero"}  = undef;
	$sett{"sr"}        = undef;
	$sett{"srCpn"}     = undef;

	if ($dim) {

		# Panel + active area limits
		my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step, 1 );
		my %areaLim = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step, 1 );

		$sett{"profLim"}         = \%profLim;
		$sett{"areaLim"}         = \%areaLim;
		$sett{"profZero"}->{"x"} = $profLim{"xMin"};
		$sett{"profZero"}->{"y"} = $profLim{"yMin"};

		if ($notStdDim) {

			# Load profile as polygon
			#CamHelper->SetStep( $inCAM, $jobId, $step );
			my $profL = GeneralHelper->GetGUID();
			CamStep->ProfileToLayer( $inCAM, $step, $profL, 200 );
			my $f = Features->new();
			$f->Parse( $inCAM, $jobId, $step, $profL );
			my @features = $f->GetFeatures();

			CamMatrix->DeleteLayer( $inCAM, $jobId, $profL );

			$sett{"profFeats"} = \@features;

		}
	}

	if ($sr) {

		# Step placement
		my @coupons = JobHelper->GetCouponStepNames();
		my @steps = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $step );

		for ( my $i = scalar(@steps) - 1 ; $i >= 0 ; $i-- ) {

			my $isCpn = scalar( grep { $steps[$i]->{"stepName"} =~ /^$_/ } @coupons ) ? 1 : 0;
			splice @steps, $i, 1 if ($isCpn);
		}

		$sett{"sr"} = \@steps;

	}

	if ($srCpn) {

		# Step placement
		my @coupons = JobHelper->GetCouponStepNames();
		my @steps = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $step );

		for ( my $i = scalar(@steps) - 1 ; $i >= 0 ; $i-- ) {

			my $isCpn = scalar( grep { $steps[$i]->{"stepName"} =~ /^$_/ } @coupons ) ? 1 : 0;
			splice @steps, $i, 1 unless ($isCpn);
		}

		$sett{"srCpn"} = \@steps;

	}

	my $JSON = $self->{"jsonStorable"}->Encode( \%sett );

	return $JSON;
}

sub CreatePnlByJSON {
	my $self  = shift;
	my $JSON  = shift;
	my $dim   = shift // 1;    # create profile by dimension
	my $sr    = shift // 1;    # crete steps
	my $srCpn = shift // 0;    # crete coupon steps

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %sett = %{ $self->{"jsonStorable"}->Decode($JSON) };
	my $SRStep = SRStep->new( $inCAM, $jobId, $step );

	if ($dim) {

		my $bL = abs( $sett{"profLim"}->{"xMin"} - $sett{"areaLim"}->{"xMin"} );
		my $bR = abs( $sett{"profLim"}->{"xMax"} - $sett{"areaLim"}->{"xMax"} );
		my $bT = abs( $sett{"profLim"}->{"yMax"} - $sett{"areaLim"}->{"yMax"} );
		my $bB = abs( $sett{"profLim"}->{"yMin"} - $sett{"areaLim"}->{"yMin"} );

		my $w = abs( $sett{"profLim"}->{"xMax"} - $sett{"profLim"}->{"xMin"} );
		my $h = abs( $sett{"profLim"}->{"yMax"} - $sett{"profLim"}->{"yMin"} );

		$SRStep->Create( $w, $h, $bT, $bB, $bL, $bR, $sett{"profZero"} );

		# Adjust shape by features data if exist
		if ( defined $sett{"profFeats"} ) {

			CamHelper->SetStep( $inCAM, $step );
			my $profL = GeneralHelper->GetGUID();
			CamMatrix->CreateLayer( $inCAM, $jobId, $profL, "document", "positive", 0 );
			CamLayer->WorkLayer( $inCAM, $profL );

			my $draw = SymbolDrawing->new( $inCAM, $jobId );

			# 1) create one symbol which will contains all rout edges
			my $sym = SymbolBase->new();
			$draw->AddSymbol($sym);

			my @feats = @{ $sett{"profFeats"} };

			# 1) Create layer and draw profile features
			for ( my $i = 0 ; $i < scalar(@feats) ; $i++ ) {

				my $f = $feats[$i];

				# draw rout
				my $primitive = undef;
				if ( $f->{"type"} eq "L" ) {

					$primitive = PrimitiveLine->new( Point->new( $f->{"x1"}, $f->{"y1"} ), Point->new( $f->{"x2"}, $f->{"y2"} ), "r400" );

				}
				elsif ( $f->{"type"} eq "A" ) {

					$primitive = PrimitiveArcSCE->new( Point->new( $f->{"x1"}, $f->{"y1"} ),
													   Point->new( $f->{"xmid"}, $f->{"ymid"} ),
													   Point->new( $f->{"x2"},   $f->{"y2"} ),
													   $f->{"newDir"}, "r400" );

				}

				$sym->AddPrimitive($primitive);
			}

			$draw->Draw();

			# Create profile according drawn profile
			$inCAM->COM( "sel_create_profile", "create_profile_with_holes" => "no" );
			CamMatrix->DeleteLayer( $inCAM, $jobId, $profL );

		}

	}

	if ($sr) {

		# Set step if "dim" is not creted, because if panel is created, step is set
		CamHelper->SetStep( $inCAM, $step ) unless ($dim);

		my @coupons = JobHelper->GetCouponStepNames();

		foreach my $s ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) ) {

			my $isCpn = scalar( grep { $s->{"stepName"} =~ /^$_/ } @coupons ) ? 1 : 0;

			CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $step, $s->{"stepName"} ) if ( !$isCpn );
		}

		foreach my $sr ( @{ $sett{"sr"} } ) {

			$SRStep->AddSRStep( $sr->{"stepName"}, $sr->{"gSRxa"}, $sr->{"gSRya"}, $sr->{"gSRangle"},
								$sr->{"gSRnx"},    $sr->{"gSRny"}, $sr->{"gSRdx"}, $sr->{"gSRdy"} );
		}

	}
	if ($srCpn) {

		# Set step if "dim" is not creted, because if panel is created, step is set
		CamHelper->SetStep( $inCAM, $step ) unless ($dim);

		my @coupons = JobHelper->GetCouponStepNames();

		foreach my $s ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) ) {

			my $isCpn = scalar( grep { $s->{"stepName"} =~ /^$_/ } @coupons ) ? 1 : 0;

			CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $step, $s->{"stepName"} ) if ($isCpn);
		}

		foreach my $sr ( @{ $sett{"srCpn"} } ) {

			$SRStep->AddSRStep( $sr->{"stepName"}, $sr->{"gSRxa"}, $sr->{"gSRya"}, $sr->{"gSRangle"},
								$sr->{"gSRnx"},    $sr->{"gSRny"}, $sr->{"gSRdx"}, $sr->{"gSRdy"} );
		}

	}

	return 1;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::CAM::PanelClass::PnlClassParser';
	#	use aliased 'Packages::InCAM::InCAM';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "d222606";
	#	my $parser = PnlClassParser->new( $inCAM, $jobId );
	#	$parser->Parse();
	#
	#	my @classes  = $parser->GetClassesProductionPanel();
	#	my @mclasses = $parser->GetClassesCustomerPanel();
	#
	#	die;
}

1;
