#-------------------------------------------------------------------------------------------#
# Description: Methods for setting proper NC layer drill direction
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::NCLayerDir;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamMatrix';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamDTM';
#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamHistogram';
#use aliased 'CamHelpers::CamFilter';
#use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# If there is some non board layer which should be board, return 0
# Not check NC layers
#sub SetNpltDrillDir {
#	my $self  = shift;
#	my $inCAM = shift;
#	my $jobId = shift;
# 
#	my $result = 1;
#
#	my @nplt_nDrill = CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_nDrill);	
#	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@nplt_nDrill );
# 
#	my @nplt_bMillBot = CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillBot);	
# 
#
#	foreach my $l  (@nplt_nDrill){
# 
#		my $dir = $l->{"gROWdrl_dir"};
#	 
#	 	# if direction is top2bot but, there is z-axis from bot, change dir b2t
#		if((!defined $dir || $dir eq "top2bot") && scalar(@nplt_bMillBot) ){
#			
#			 CamMatrix->SetLayerDirection($inCAM, $jobId, $l->{"gROWname"}, "bottom_to_top");
#		}
#		# set t2b
#		elsif( $dir eq "bot2top" && !scalar(@nplt_bMillBot) ){
#			
#			 CamMatrix->SetLayerDirection($inCAM, $jobId, $l->{"gROWname"}, "top_to_botom");
#			
#		}
#	}
# 
#}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Drilling::NCLayerDir';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $mess = "";
 
	my @l = ();
	my $result = NCLayerDir->CheckNpltDrillDir( $inCAM, $jobId,  \@l );

	print STDERR "Result is: $result, error \n";

 

}

1;
