
package Packages::Stackup::Enums;
 

use constant {
    MaterialType_COPPER => "copper",
    MaterialType_PREPREG => "prepreg",
    MaterialType_CORE => "core",
    MaterialType_COVERLAY => "coverlay",
	 
};


use constant {
    InStackMaterialType_ISOLATOR => "Isolator",
    InStackMaterialType_CORE => "Core",
    InStackMaterialType_FOIL => "Foil"
	 
};


use constant {
    SignalLayer_TOP => "top",
    SignalLayer_BOT => "bot"
};


use constant {
    CoreType_RIGID => "rigidCore",
    CoreType_FLEX => "flexCore"
};

use constant {
    NoFlowPrepreg_P1 => "noFLowP1",
    NoFlowPrepreg_P2 => "noFLowP2"
};

use constant {
    Coverlay_SELECTIVE => "coverlaySelective",
    Coverlay_FULL => "coverlayFull"
};

# source which stackup class read from
use constant {
    StackupSource_ML => "stackupSource_ml",
    StackupSource_INSTACK => "stackupSource_instack"
};

use constant {
    Product_INPUT => "productInput",
    Product_PRESS => "productPress"
};

use constant {
    ProductL_PRODUCT => "productLProduct",
    ProductL_MATERIAL => "productLMaterial"
};

use constant {
    Plating_STD => 25, # standard plating is 25µm
    
};


1;

