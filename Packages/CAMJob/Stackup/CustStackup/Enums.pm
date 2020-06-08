
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';

package Packages::CAMJob::Stackup::CustStackup::Enums;

use constant {
			   Sec_BEGIN       => "section_begin",          # Begining of table with material text
			   Sec_A_MAIN      => "section_A_Main",         # Main stackup section with layer names and drilling
			   Sec_B_FLEX      => "section_B_Flex",         # Flex part of RigidFlex pcb
			   Sec_C_RIGIDFLEX => "section_C_RigidFlex",    # Second Rigid part of RigidFLex
			   Sec_D_FLEXTAIL  => "section_D_FlexTail",     # Flexible tail of rigid flex section
			   Sec_E_STIFFENER => "section_E_STIFFENER",    # Flex with stiffeners top
			   Sec_F_STIFFENER => "section_F_STIFFENER",    # Flex with stiffeners bot
			   Sec_END         => "section_end"             # End of table
};

 
 

1;
