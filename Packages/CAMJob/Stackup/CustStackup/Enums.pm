
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';

package Packages::CAMJob::Stackup::CustStackup::Enums;

use constant {
			   Sec_BEGIN       => "section_begin",          # Begining of table with material text
			   Sec_A_MAIN      => "section_A_Main",         # Main stackup section with layer names and drilling
			   Sec_B_FLEX      => "section_B_Flex",         # Flex part of RigidFlex pcb
			   Sec_C_RIGIDFLEX => "section_C_RigidFlex",    # Second Rigid part of RigidFLex
			   Sec_D_FLEXTAIL  => "section_D_FlexTail",     # Flexible tail of rigid flex section
			   Sec_E_STIFFENER => "section_E_STIFFENER",    # Flex with stiffeners
			   Sec_END         => "section_end"             # End of table
};

use constant {
			   Clr_TITLEBACKG     => "192, 0, 0",
			   Clr_HEADMAINBACK   => "191, 191, 191",
			   Clr_HEADSUBBACK    => "217, 217, 217",
			   Clr_LEFTCLMNBACK   => "242, 242, 242",
			   Clr_SOLDERMASK     => "59, 113, 41",
			   Clr_SOLDERMASKFLEX => "112, 173, 71",
			   Clr_SILKSCREEN     => "200, 200, 200",
			   Clr_COPPER         => "174, 57, 47",
			   Clr_CORERIGID      => "248, 154, 28",
			   Clr_COREFLEX       => "244, 175, 128",
			   Clr_PREPREG        => "169, 161, 80",
			   Clr_COVERLAY       => "255, 211, 25",
			   Clr_ADHESIVE       => "189, 215, 238",
			   Clr_STIFFENER      => "174, 170, 170",
			   Clr_NCDRILL        => "64, 64, 64",
};

1;
