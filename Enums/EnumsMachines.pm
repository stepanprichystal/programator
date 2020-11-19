
package Enums::EnumsMachines;

#hodnota napr.: machine_a je shodna s nazvem slozky ve:
# \\incam\incam_server\site_data\hooks\ncd\config\machines\

use constant {
			   MACHINE_A   => "machine_a",         # A .   - Lenz
			   MACHINE_B   => "machine_b",         # B ..  - Schmoll 200
			   MACHINE_C   => "machine_c",         # C ... - Schmoll 300
			   MACHINE_D   => "machine_d",         # D ....- Schmoll 300
			   MACHINE_I   => "machine_i",         # I ....- Schmoll 300
			   MACHINE_J   => "machine_j",         # J ....- Schmoll 300
			   MACHINE_E   => "machine_e",         # D ....- Freza schmoll
			   MACHINE_G   => "machine_g",         # G ....- Schmoll
			   MACHINE_DEF => "machine_default"    # Virtual machine, which has defined default drill/rout parameters for other machines
};

1;
