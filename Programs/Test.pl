

#use LoadLibrary;
 
 


 
 
#use aliased 'CamGuide::Actions::MillingActions';
use CamGuide::Guide;
use CamGuide::GuideTypeOne;

#MillingActions->DoFinalRout();

my $inCam = 1;

my $guideTypeOne = CamGuide::GuideTypeOne->new($inCam);
$guideTypeOne->RunGuide();


print 2;