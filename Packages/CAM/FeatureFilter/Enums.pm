package Packages::CAM::FeatureFilter::Enums;

use constant {
			   Logic_AND => "and",
			   Logic_OR  => "or"
};

# mode of reference filter
use constant {
			   RefMode_TOUCH => "touch",
			   RefMode_DISJOINT => "disjoint",
			   RefMode_COVER => "cover",
			   RefMode_MULTICOVER => "multi_cover",
			   RefMode_INCLUDE => "include",
			   RefMode_SAMECENTER => "same_center",
};

# What area will be considered during filtering
use constant {
			   ProfileMode_IGNORE => 0,
			   ProfileMode_INSIDE => 1,
			   ProfileMode_OUTSIDE => 2
};
 
# Polarity of considered features
use constant {
			   Polarity_POSITIVE => "positive",
			   Polarity_NEGATIVE => "negative",
			   Polarity_BOTH => "both",
			   
};

1;
