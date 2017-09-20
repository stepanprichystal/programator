
package Programs::StencilCreator::Enums;

use constant {
			   Spacing_PROF2PROF        => "Prof to prof",  
			   Spacing_DATA2DATA        => "Data to data"     
};

use constant {
			   HCenter_BYPROF        => "By profile",  
			   HCenter_BYDATA        => "By paste data" 	   
};


use constant {
			   StencilSize_300x480        => "300mm x 480mm", 
			   StencilSize_300x520        => "300mm x 520mm", 
			   StencilSize_CUSTOM        => "custom"
		 
};

use constant {
			   StencilType_TOP        => "Top", 
			   StencilType_BOT        => "Bot", 
			   StencilType_TOPBOT        => "Top + Bot"
};

use constant {
			   Schema_STANDARD        => "Standard",  
			   Schema_FRAME        => "Vlepeni do ramu",
			    Schema_INCLUDED        => "Included in data",
			   	   
};
 	 

1;
