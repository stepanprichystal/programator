
package Enums::EnumsImp;


# Impedance microstrip types
use constant {
	Type_SE     => "se",
	Type_DIFF   => "diff",
	Type_COSE   => "coplanar_se",
	Type_CODIFF => "coplanar_diff",

};

# Impedance miscrostrip models
use constant {
	Model_COATED_MICROSTRIP          => "coated_microstrip",
	Model_COATED_MICROSTRIP_2B       => "coated_microstrip_2b",
	Model_UNCOATED_MICROSTRIP        => "uncoated_microstrip",
	Model_UNCOATED_MICROSTRIP_2B     => "uncoated_microstrip_2b",
	Model_STRIPLINE                  => "stripline",
	Model_STRIPLINE_2B               => "stripline_2b",
	Model_STRIPLINE_2T               => "stripline_2t",
	Model_COATED_EMBEDDED_2B         => "coated_embedded_2b",
	Model_COATED_UPPER_EMBEDDED      => "coated_upper_embedded",
	Model_COATED_UPPER_EMBEDDED_2B   => "coated_upper_embedded_2b",
	Model_COATED_UPPER_EMBEDDED_2T   => "coated_upper_embedded_2t",
	Model_COATED_LOWER_EMBEDDED      => "coated_lower_embedded",
	Model_COATED_LOWER_EMBEDDED_2B   => "coated_lower_embedded_2b",
	Model_UNCOATED_EMBEDDED_2B       => "uncoated_embedded_2b",
	Model_UNCOATED_UPPER_EMBEDDED    => "uncoated_upper_embedded",
	Model_UNCOATED_UPPER_EMBEDDED_2B => "uncoated_upper_embedded_2b",
	Model_UNCOATED_UPPER_EMBEDDED_2T => "uncoated_upper_embedded_2t",
	Model_UNCOATED_LOWER_EMBEDDED    => "uncoated_lower_embedded",
	Model_UNCOATED_LOWER_EMBEDDED_2B => "uncoated_lower_embedded_2b",

	# DIFF extra
	Model_BROADSIDE_OVER_CORE    => "broadside_over_core",
	Model_BROADSIDE_OVER_PREPREG => "broadside_over_prepreg",

	# Coplanar SE + Coplanar diff extra
	Model_COATED_MICROSTRIP_WITHOUT_GND   => "coated_microstrip_without_gnd",
	Model_UNCOATED_MICROSTRIP_WITHOUT_GND => "uncoated_microstrip_without_gnd",
	Model_COATED_EMBEDDED_WITHOUT_GND     => "coated_embedded_without_gnd",
	Model_UNCOATED_EMBEDDED_WITHOUT_GND   => "uncoated_embedded_without_gnd",

};

1;
 
