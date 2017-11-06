
package Programs::Stencil::StencilCreator::Enums;

use constant {
			   StencilSource_JOB       => "sourceJob",  
			   StencilSource_CUSTDATA        => "sourceCustomerData"     
};


use constant {
			   Spacing_PROF2PROF        => "Prof to prof",  
			   Spacing_DATA2DATA        => "Data to data"     
};

use constant {
			   Center_BYPROF        => "By profile",  
			   Center_BYDATA        => "By paste data" 	   
};


use constant {
			   StencilSize_300x480        => "300 x 480mm", 
			   StencilSize_300x520        => "300 x 520mm", 
			   StencilSize_CUSTOM        => "custom"
		 
};

use constant {
			   StencilType_TOP        => "Top", 
			   StencilType_BOT        => "Bot", 
			   StencilType_TOPBOT        => "Top + Bot"
};

use constant {
			   Schema_STANDARD        => "Standard holes",  
			   Schema_FRAME        => "Vlepeni do ramu",
			    Schema_INCLUDED        => "Included in data",
			   	   
};
 	 
 	 
use constant {
			   Stencil_LAYER        => "ds",  
			   Stencil_LAYERDRILL        => "fs"
			   	   
}; 	 

# Stencil technology
use constant {
			   Technology_LASER        => "laser",  
			   Technology_DRILL        => "drill", 
			    Technology_ETCH        => "etch"
			   	   
}; 
 	 

1;
