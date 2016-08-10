#!/usr/bin/perl-w

package sqlNoris;
use Win32::OLE;
use Win32::OLE::Variant;
use Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw (getValueNoris);



sub getValueNoris {
		#avoid when package name is as first parameter
		if(@_[0] eq __PACKAGE__) {shift;}; 

		my $jobNameNoris = shift;
		my $getValue = shift;
		
my $dbConnection = Win32::OLE->new("ADODB.Connection");
$dbConnection->Open("DSN=dps;uid=genesis;pwd=genesis");

$sqlStatement = "select top 1
 d.nazev_subjektu board_name,
 c.nazev_subjektu customer,
 m.nazev_subjektu material,
 d.maska_barva_1 c_mask_colour,
 d.maska_barva_2 s_mask_colour,
 d.potisk c_silk_screen_colour,
 d.potisk_typ s_silk_screen_colour,
 d.zlaceni golding,
 d.konstr_trida construction_class,
 d.pocet_vrstev,
 d.rozmer_x x_size,
 d.rozmer_y y_size,
 d.strihani cutting,
 d.drazkovani slotting,
 d.frezovani_pred milling_before,
 d.frezovani_po milling_after,
 d.freza_pred_leptanim milling_before_etch,
 d.hal surface_finishing,
 d.material_tloustka,
 d.min_vrtak,
 d.flash,
 d.material_tloustka_medi,
 d.material_typ_materialu,
 d.poznamka,
 d.tloustka,
 d.tenting,
 d.datacode,
 d.konstr_trida,
 d.zakaznicke_cislo,
 dn.kus_x n_kus_x,
 dn.kus_y n_kus_y,
 dn.panel_x n_mpanel_x,
 dn.panel_y n_mpanel_y,
 dn.nasobnost n_nasobnost,
 dn.konstr_trida n_construction_class,
 dn.rozmer_x n_x_panel,
 dn.rozmer_y n_y_panel,
 prijal.nazev_subjektu n_prijal,
 dn.maska_barva_1 n_c_mask_colour,
 dn.maska_barva_2 n_s_mask_colour,
 dn.potisk n_c_silk_screen_colour,
 dn.potisk_typ n_s_silk_screen_colour,
 mn.nazev_subjektu n_material,
 dn.strihani n_cutting,
 dn.drazkovani n_slotting,
 dn.frezovani_pred n_milling_before,
 dn.frezovani_po n_milling_after,
 dn.poznamka n_poznamka_dps,
 dn.poznamka_zakaznik n_poznamka_web,
 n.poznamka n_poznamka_zak,
 z.kusy_pozadavek pocet,
 z.pooling,
 z.stav,
 d.material_druh,
 lcs.nf_edit_style('ddlb_22_hal', dn.hal) n_surface,
 lcs.nf_edit_style('typ_desky_22', d.material_typ) typ_desky,
 z.pocet_prirezu,
 z.prirezu_navic,
 z.termin,
 z.aktualni_krok,
 lcs.nf_edit_style('typ_el_test_22', d.eltest) testing,
 z.reference_subjektu reference_zakazky,
 d.archiv + d.reference_subjektu archiv
 from lcs.desky_22 d with (nolock)
 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
 left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
 left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
 left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
 left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
 left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
 left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
 where d.reference_subjektu='$jobNameNoris' and  z.cislo_poradace = 22050
 order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc
";
	$sqlExecute = $dbConnection->Execute("$sqlStatement");

		$resultValue = convert_from_czech ($sqlExecute->Fields("$getValue")->Value);
		$dbConnection->Close();

return ($resultValue);
}
sub convert_from_czech {
	my $lineToConvert = shift;
	my $char;
	my $ret;
	my @str = split(//,$lineToConvert);

	foreach my $char (@str) {
		$char =~ tr/\xE1\xC1\xE8\xC8\xEF\xCF\xE9\xC9\xEC\xCC\xED\xCD\xF3\xD3\xF8\xD8\xB9\xA9\xBB\xAB\xFA\xDA\xF9\xD9\xFD\xDD\xBE\xAE\xF2\xD2/\x61\x41\x63\x43\x64\x44\x65\x45\x65\x45\x69\x49\x6F\x4F\x72\x52\x73\x53\x74\x54\x75\x55\x75\x55\x79\x59\x7A\x5A\x6E\x4E/;
		$ret .= $char;
	}
	return ($ret);
		
}
# return all job with status "ve vyrobe" (at POOL jobs: without slave jobs, only Master)
sub getJobsInProduction {
	my @tmpJobs =();
 			 my $dbConnection = Win32::OLE->new("ADODB.Connection");
 				$dbConnection->Open("DSN=dps;uid=genesis;pwd=genesis");
 		
 			 my $sqlStatement =	"select distinct d.reference_subjektu from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska left outer join lcs.vztahysubjektu vs on vs.cislo_vztahu = 23054 and vs.cislo_subjektu = z.cislo_subjektu where vs.cislo_vztaz_subjektu is null and z.stav='4'";
 			 my $sqlExecute = $dbConnection->Execute("$sqlStatement");
 		
 			 my $rec   = Win32::OLE->new("ADODB.Recordset");
 				$rec->Open($sqlStatement, $dbConnection);
 		
 			until ($rec->EOF) {
 		 		 my $value = $rec->Fields("reference_subjektu")->value;
 		 		 	unless ($value =~ /-[Jj][\d]/) {
 		 		 			if(sqlNoris->getValueNoris ($value,'typ_desky') eq "Vicevrstvy" or sqlNoris->getValueNoris ($value,'typ_desky') eq "Oboustranny" or sqlNoris->getValueNoris ($value,'typ_desky') eq "Jednostranny"){
 		 		 				push(@tmpJobs,$value);
 		 		 			}
 		 		 	}
 		  	     $rec->MoveNext();
 			}
 			$rec->Close();
 			$dbConnection->Close();
	return(@tmpJobs);
}




1;