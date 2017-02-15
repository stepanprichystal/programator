
package Enums::EnumsDrill;

# represent type of DTM vzsledne/vratne holes
use constant {
			   DTM_VRTANE   => "vrtane",
			   DTM_VYSLEDNE   => "vysledne"
};
 
 
# represent names of DTM user column
use constant {
			   DTMclmn_DEPTH   => "depth",
			   DTMclmn_MAGAZINE   => "magazine"
}; 


# represent names of DTM surface user attributes
use constant {
			   DTMatt_DEPTH   => "tool_depth",
			   DTMatt_MAGAZINE   => "tool_magazine"
}; 

1;

