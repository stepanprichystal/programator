
package Packages::CAMJob::Stackup::CustStackup::Enums;

use constant {
			   Section_BEGIN       => "section_begin",          # Begining of table with material text
			   Section_A_MAIN      => "section_A_Main",         # Main stackup section with layer names and drilling
			   Section_B_FLEX      => "section_B_Flex",         # Flex part of RigidFlex pcb
			   Section_C_RIGIDFLEX => "section_C_RigidFlex",    # Second Rigid part of RigidFLex
			   Section_D_FLEXTAIL  => "section_D_FlexTail",     # Flexible tail of rigid flex section
			   Section_E_STIFFENER => "section_E_STIFFENER",    # Flex with stiffeners
			   Section_END         => "section_end"             # End of table
};

1;
