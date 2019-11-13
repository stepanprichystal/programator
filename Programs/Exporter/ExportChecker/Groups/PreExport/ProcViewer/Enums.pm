
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums;


use Wx;

use constant {
			   Group_PRODUCTINPUT => "groupProductInput",
			   Group_PRODUCTPRESS => "groupProductPress"
};

use constant {
			   RowSeparator_CORE     => "rowSeparatorCore",
			   RowSeparator_PRPG     => "rowSeparatorPrpg",
			   RowSeparator_GAP      => "rowSeparatorGap",
			   RowSeparator_COVERLAY => "rowSeparatorCoverlay",
};

use constant {
			   Color_PRODUCTINPUT => Wx::Colour->new( 255, 192, 0 ),
			   Color_PRODUCTPRESS => Wx::Colour->new( 155, 194, 230 )
};

1;
