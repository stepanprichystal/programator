
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::HeliosConnector::HegMethods;

#STATIC class

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;

#local library
#use lib qw(.. c:\Perl\site\lib\Programs\Test);
#use LoadLibrary;

use aliased 'Connectors::HeliosConnector::Helper';
use aliased 'Connectors::SqlParameter';
use aliased 'Connectors::HeliosConnector::Enums';
use aliased 'Enums::EnumsIS';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::SystemCall::SystemCall';
use aliased 'Connectors::EnumsErrors';
use aliased 'Packages::Exceptions::HeliosException';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetAllByPcbId {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.nazev_subjektu board_name,
				 c.nazev_subjektu customer,
				 d.maska_c_1 c_mask_colour,
				 d.maska_s_1 s_mask_colour,
				 d.potisk_c_1 c_silk_screen_colour,
				 d.potisk_s_1 s_silk_screen_colour,
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
				 d.poznamka_tpv,
				 d.tloustka,
				 d.tenting,
				 d.datacode,
				 d.konstr_trida,
				 d.zakaznicke_cislo,
				 d.zlaceni,
				 d.lak_typ,
				 d.stiffener,
				 dn.kus_x n_kus_x,
				 dn.kus_y n_kus_y,
				 dn.panel_x n_mpanel_x,
				 dn.panel_y n_mpanel_y,
				 dn.nasobnost n_nasobnost,
				 dn.konstr_trida n_construction_class,
				 dn.rozmer_x n_x_panel,
				 dn.rozmer_y n_y_panel,
				 prijal.nazev_subjektu n_prijal,
				 dn.maska_c_1 n_c_mask_colour,
				 dn.maska_s_1 n_s_mask_colour,
				 dn.potisk_c_1 n_c_silk_screen_colour,
				 dn.potisk_s_1 n_s_silk_screen_colour,
				 mn.nazev_subjektu n_material,
				 dn.strihani n_cutting,
				 dn.drazkovani n_slotting,
				 dn.frezovani_pred n_milling_before,
				 dn.frezovani_po n_milling_after,
				 dn.poznamka n_poznamka_dps,
				 dn.poznamka_zakaznik n_poznamka_web,
				 d.material,
				 m.nazev_subjektu material_nazev,
				 m.reference_subjektu material_reference_subjektu,
				 d.material_coverlay,
				 d.material_stiffener,
				 d.poznamka_zakaznik poznamka_web,
				 n.poznamka n_poznamka_zak,
				 z.kusy_pozadavek pocet,
				 z.pooling,
				 z.poznamka poznamka_zakazka,
				 z.odsouhlasovat,
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
				 d.archiv + d.reference_subjektu archiv,
				 d.sablona_typ
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.kmenova_karta_skladu m with (nolock) on m.cislo_subjektu=d.material
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
				 left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
				 left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
				 left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
				 left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if (@result) {
		return @result;
	}
	else {
		return undef;
	}
}

sub GetExternalDoc {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
	stuff ((select ',' +  'heliosgreen://v1/nrs/Gatema/Classes(145)/Folders(11019)/RunFunction?FunctionName=spusteni&RecordNumbers=[' + cast(vs.cislo_vztaz_subjektu as varchar(30)) + ']' from lcs.vztahysubjektu vs where vs.cislo_vztahu = 17810 and vs.cislo_subjektu = n.cislo_subjektu for xml path (''), TYPE).value('.', 'varchar(max)'), 1, 1 , '' ) externi_dokumenty
	from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.kmenova_karta_skladu m with (nolock) on m.cislo_subjektu=d.material
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
				 left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
				 left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
				 left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
				 left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if (@result) {
		return @result;
	}
	else {
		return undef;
	}
}

# Return hash ref with information about order
# parameter is pcbid with order id: eg: f12345-01
sub GetInfoAfterStartProduce {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
			 	 z.kusy_pozadavek,
				 z.pocet_prirezu,
				 z.prirezu_navic
				 
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where z.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if (@result) {
		return $result[0];
	}
	else {
		return undef;
	}
}

# Return info abou pcb dimensions
sub GetInfoDimensions {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.nasobnost_panelu,
				 d.nasobnost,
				 d.kus_x,
				 d.kus_y,
				 d.panel_x,
				 d.panel_y
				 
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if (@result) {
		return $result[0];
	}
	else {
		die "no record for $pcbId";
	}
}

sub GetPcbName {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.nazev_subjektu board_name
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	return Helper->ExecuteScalar( $cmd, \@params );
}

sub GetEmployyInfo {
	my $self     = shift;
	my $userName = shift;
	my $userId   = shift;

	die "Only one option (user name or user id) is enabled " if ( $userName && $userId );
	die "No option (user name or user id) is defined" if ( !defined $userName && !defined $userId );

	my @params = ();
	if ( defined $userName ) {

		@params = ( SqlParameter->new( "_UserName", Enums->SqlDbType_VARCHAR, $userName ) );
	}
	elsif ( defined $userId ) {

		@params = ( SqlParameter->new( "_UserId", Enums->SqlDbType_VARCHAR, $userId ) );
	}

	my $cmd = "SELECT cislo_subjektu,
			e_mail,
			jmeno,
			prijmeni,
			telefon_prace
			
			FROM lcs.zamestnanci ";

	if ( defined $userName ) {

		$cmd .= "WHERE login_id = _UserName";

	}
	elsif ( defined $userId ) {

		$cmd .= "WHERE cislo_subjektu = _UserId";
	}

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@result) == 1 ) {
		return $result[0];
	}
	else {
		return undef;
	}
}

sub GetBasePcbInfo {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.pocet_vrstev,
				 d.rozmer_x x_size,
				 d.rozmer_y y_size,
				 d.drazkovani slotting,
				 d.frezovani_pred milling_before,
				 d.frezovani_po milling_after,
				 d.freza_pred_leptanim milling_before_etch,
				 d.hal surface_finishing,
				 d.material_tloustka,
				 d.material_tloustka_medi,
				 d.material_typ_materialu,
				 d.merit_presfitt,
				 d.mereni_tolerance_vrtani,
				 d.srazeni_hran,
				 d.zlaceni,
				 d.zaplneni_otvoru,
				 z.pooling,
				 d.stav
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
				 left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
				 left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
				 left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
				 left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@result) == 1 ) {
		return $result[0];
	}
	else {
		return undef;
	}
}

# Return material kind like FR4, S400, etc..
sub GetMaterialKind {
	my $self      = shift;
	my $pcbId     = shift;
	my $editStyle = shift;    # if checked ,return value will be edited FR4 => FR4 tg150

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $column = "d.material_druh";

	if ($editStyle) {
		$column = "lcs.nf_edit_style('ddlb_22_material_druh', d.material_druh) mat";
	}

	my $cmd = "select top 1
				 " . $column . "
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	return Helper->ExecuteScalar( $cmd, \@params );

}

# Return if electrical test if required
sub GetElTest {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.eltest
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my $val = Helper->ExecuteScalar( $cmd, \@params );

	if ( defined $val && $val =~ /^f$/i ) {
		return 1;
	}
	else {
		return 0;
	}

}

#Return scalar value of pcb type without diacritics
# - Vicevrstvy, oboustranny, ...
sub GetTypeOfPcb {
	my $self        = shift;
	my $pcbId       = shift;
	my $noEditStyle = shift // 0;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $editStyle = "lcs.nf_edit_style('typ_desky_22', d.material_typ) typ_desky";
	if ($noEditStyle) {
		$editStyle = "d.material_typ typ_desky";
	}

	my $cmd = "select top 1
				 $editStyle
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	return Helper->ExecuteScalar( $cmd, \@params, 1 );

}

#Return

sub GetPcbSurface {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.hal surface_finishing
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	return Helper->ExecuteScalar( $cmd, \@params, 1 );

}

# Return type of coverlay
sub GetFlexSolderMask {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.flexi_maska 
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my %flex = ( "top" => 0, "bot" => 0 );

	my $val = Helper->ExecuteScalar( $cmd, \@params );

	if ($val) {

		$flex{"top"} = ( $val eq "C" || $val eq "2" ) ? 1 : 0;
		$flex{"bot"} = ( $val eq "S" || $val eq "2" ) ? 1 : 0;
	}

	return %flex;
}

# Return color of mask in hash for top and bot side
sub GetSolderMaskColor {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.maska_c_1 c_mask_colour,
				 d.maska_s_1 s_mask_colour
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my %mask = ();

	my @rows = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@rows) ) {

		$mask{"top"} = $rows[0]->{"c_mask_colour"};
		$mask{"bot"} = $rows[0]->{"s_mask_colour"};
		return %mask;

	}
	else {

		return 0;
	}
}

# Return second color of mask in hash for top and bot side
sub GetSolderMaskColor2 {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.maska_c_2 c_mask_colour2,
				 d.maska_s_2 s_mask_colour2
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my %mask = ();

	my @rows = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@rows) ) {

		$mask{"top"} = $rows[0]->{"c_mask_colour2"};
		$mask{"bot"} = $rows[0]->{"s_mask_colour2"};

		return %mask;
	}
	else {

		return 0;
	}
}

#Return color of silk screen in hash for top and bot side
sub GetSilkScreenColor {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.potisk_c_1 c_silk_screen_colour,
				 d.potisk_s_1 s_silk_screen_colour
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my %silk = ();

	my @rows = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@rows) ) {

		$silk{"top"} = $rows[0]->{"c_silk_screen_colour"};
		$silk{"bot"} = $rows[0]->{"s_silk_screen_colour"};

		return %silk;
	}
	else {

		return 0;
	}
}

#Return color of silk screen in hash for top and bot side
sub GetSilkScreenColor2 {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.potisk_c_2 c_silk_screen_colour2,
				 d.potisk_s_2 s_silk_screen_colour2
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my %silk = ();

	my @rows = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@rows) ) {

		$silk{"top"} = $rows[0]->{"c_silk_screen_colour2"};
		$silk{"bot"} = $rows[0]->{"s_silk_screen_colour2"};

		return %silk;
	}
	else {

		return 0;
	}
}

# Return type of coverlay
sub GetCoverlayType {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.coverlay
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my %coverlay = ( "top" => undef, "bot" => undef );

	my $val = Helper->ExecuteScalar( $cmd, \@params );

	if ($val) {

		$coverlay{"top"} = ( $val eq "C" || $val eq "2" ) ? 1 : 0;
		$coverlay{"bot"} = ( $val eq "S" || $val eq "2" ) ? 1 : 0;
	}

	return %coverlay;
}

#Return scalar value of pcb thick in helios
sub GetPcbMaterialThick {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.material_tloustka
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	return Helper->ExecuteScalar( $cmd, \@params );

}

#Return scalar value of base outer cu thick
sub GetOuterCuThick {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.material_tloustka_medi
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	return Helper->ExecuteScalar( $cmd, \@params );

}

#sqlNoris->getValueNoris($pcbId, 'typ_desky')

sub GetReorderPoolPcb {
	my $self = shift;

	my @params = ();

	my $cmd = "select TOP 100 z.reference_subjektu 
				
				from lcs.zakazky_dps_22_hlavicka z 
				join lcs.desky_22 d on d.cislo_subjektu=z.deska;";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@result) > 1 ) {
		return @result;
	}
	else {
		return undef;
	}
}

# Return string notes by pcbId for customer (Helios tab UDA)
sub GetTpvCustomerNote {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "SELECT uda.poznamka_tpv 
				FROM lcs.uda_organizace uda
				JOIN lcs.desky_22 d ON d.zakaznik = uda.cislo_subjektu
				WHERE d.reference_subjektu = _PcbId;";

	return Helper->ExecuteScalar( $cmd, \@params );
}

# return all information for pcb offer by pcbId
sub GetAllByPcbIdOffer {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
 				 dn.kus_x Rozmer_kus_X,
 				 dn.kus_y Rozmer_kus_Y,
 				 dn.panel_x Rozmer_mpanel_X,
 				 dn.panel_y Rozmer_mpanel_Y,
 				 dn.nasobnost Nasobnost,
 				 dn.konstr_trida Konstrukcni_trida,
 				 dn.rozmer_x Rozmer_panel_X,
 				 dn.rozmer_y Rozmer_panel_Y,
 				 prijal.nazev_subjektu Nabidku_zpracoval,
 				 mn.nazev_subjektu Material,
 				 lcs.nf_edit_style('ddlb_22_vysledne_formatovani', dn.strihani) Vysledne_formatovani,
 				 dn.drazkovani Drazkovani,
 				 dn.frezovani_pred Frezovani_pred,
 				 dn.frezovani_po Frezovani_po,
 				 dn.material_druh Material_druh,
 				 lcs.nf_edit_style('ddlb_22_hal', dn.hal) Povrchova_uprava,
 				 lcs.nf_edit_style('typ_desky_22', dn.material_typ) Typ_desky
 				 from lcs.desky_22 d with (nolock)
 				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
 				 left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
 				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
 				 left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
 				 left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
 				 left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
 				 left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
 				 left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
 				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
 				 order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my @result = Helper->ExecuteDataSet( $cmd, \@params, 1 );

	if ( scalar(@result) == 1 ) {
		return $result[0];
	}
	else {
		return undef;
	}
}

# Specific select for kontrola.pl
sub GetUserInfoHelios {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 c.nazev_subjektu Zakaznik,
				 d.konstr_trida Kontr_trida,
				 lcs.nf_edit_style('ddlb_22_hal', d.hal) Povrchova_uprava,
				 d.material_tloustka Tloustka,
				 d.material_tloustka_medi Tloustka_medi,
				 d.poznamka Poznamka,
				 d.datacode Datacode,
				 z.kusy_pozadavek Pocet_kusu,
				 z.pooling POOLing,
				 d.material_druh Material,
				 lcs.nf_edit_style('typ_desky_22', d.material_typ) Typ_desky,
				 z.termin Termin,
				 lcs.nf_edit_style('ddlb_22_vysledne_formatovani', d.strihani) Vysledne_formatovani
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
				 left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
				 left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
				 left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
				 left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my @result = Helper->ExecuteDataSet( $cmd, \@params, 1 );

	if ( scalar(@result) == 1 ) {
		return $result[0];
	}
	else {
		return undef;
	}
}

# Return if pcb is type Pool
# Function take this information from last ordered pcb/order
sub GetPcbIsPool {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 z.pooling
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc";

	my $res = Helper->ExecuteScalar( $cmd, \@params );

	if ( $res && $res eq "A" ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return if specific order is type Pool
sub GetOrderIsPool {
	my $self    = shift;
	my $orderId = shift;

	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $cmd = "select
				 z.pooling
				 from  lcs.zakazky_dps_22_hlavicka z with (nolock) 
				 where z.reference_subjektu=_OrderId and z.cislo_poradace = 22050";

	my $res = Helper->ExecuteScalar( $cmd, \@params );

	if ( $res && $res eq "A" ) {
		return 1;
	}
	else {
		return 0;
	}
}

#Return name of layer, where datacode is present
sub GetDatacodeLayer {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.datacode
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my $res = Helper->ExecuteScalar( $cmd, \@params );

	if ($res) {
		$res = uc($res);
	}

	unless ( defined $res ) {
		$res = "";
	}

	return $res;
}

#Return name of layer, where UlLogo is present
sub GetUlLogoLayer {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.ul_logo
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my $res = Helper->ExecuteScalar( $cmd, \@params );

	if ($res) {
		$res = uc($res);
	}

	unless ( defined $res ) {
		$res = "";
	}

	return $res;
}

# Return order number of last "order"
# Understand this: f12345-01, in this case it return "01";
sub GetPcbOrderNumber {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select TOP 1
				  
				 z.reference_subjektu
				 
				 from lcs.desky_22 d with (nolock)
				 
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu

				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc";

	my $res = Helper->ExecuteScalar( $cmd, \@params );

	my ($num) = $res =~ m/[a-z]+[\d]+-(\d*)/i;

	return $num;
}

# Return all order numbers by job name
sub GetPcbOrderNumbers {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select 				  
				 z.reference_subjektu,
				 z.stav,
				 z.aktualni_krok
				 from lcs.desky_22 d with (nolock)
				 
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu

				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc";

	my @res = Helper->ExecuteDataSet( $cmd, \@params );

	return @res;
}

sub GetOrdersByState {
	my $self    = shift;
	my $orderId = shift;
	my $state   = shift;

	my @orders = $self->GetPcbOrderNumbers($orderId);

	@orders = grep { $_->{"stav"} == $state } @orders;

	return @orders;
}

sub GetNumberOrder {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 z.reference_subjektu reference_zakazky
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
				 left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
				 left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
				 left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
				 left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my $res = Helper->ExecuteScalar( $cmd, \@params );

	return $res;

}

##Return ID of customer
sub GetCustomerInfo {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $numberOrder = GetNumberOrder( '', $pcbId );

	my $cmd = "select top 1		
				org.reference_subjektu,
				org.nazev_subjektu customer,
				org.zeme
				FROM lcs.organizace org
				JOIN lcs.zakazky_dps_22_hlavicka z ON z.zakaznik = org.cislo_subjektu
				WHERE z.reference_subjektu = '$numberOrder'";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@result) == 1 ) {
		return $result[0];
	}
	else {
		return undef;
	}
}

##Return ID of customer
sub GetIdcustomer {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $numberOrder = GetNumberOrder( '', $pcbId );

	my $cmd = "select top 1		
				org.reference_subjektu
				FROM lcs.organizace org
				JOIN lcs.zakazky_dps_22_hlavicka z ON z.zakaznik = org.cislo_subjektu
				WHERE z.reference_subjektu = '$numberOrder'
				";

	my $res = Helper->ExecuteScalar( $cmd, \@params );

	return $res;
}

#sub UpdateConstructionClass {
#	my $self        = shift;
#	my $pcbId       = shift;
#	my $class       = shift;
#	my $childThread = shift;
#
#	if ($childThread) {
#
#		my $result = $self->__SystemCall( "UpdateConstructionClass", $pcbId, $class );
#
#		return $result;
#	}
#	else {
#
#		require Connectors::HeliosConnector::HelperWriter;
#
#		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( $pcbId, $class, "konstr_trida" );
#
#		return $res;
#	}
#
#
#
#}

# Update notes in the last order
sub UpdateOrderNotes {
	my $self  = shift;
	my $pcbId = shift;
	my $notes = shift;
	my $res   = 0;

	my $lastOrder = $self->GetPcbOrderNumber($pcbId);

	my @allItems = $self->GetAllByPcbId($pcbId);
	my $curNotes = $allItems[0]{'poznamka_zakazka'};

	unless ( $curNotes =~ /$notes/ ) {

		require Connectors::HeliosConnector::HelperWriter;

		my $allNotes = $notes . "\n" . $curNotes;
		$res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_order( "$pcbId" . "-" . $lastOrder, $allNotes, "poznamka" );
	}

	return $res;
}

# Update item Odsouhlasovat
sub UpdateOdsouhlasovat {
	my $self  = shift;
	my $pcbId = shift;
	my $state = shift;
	my $res   = 0;

	my $lastOrder = $self->GetPcbOrderNumber($pcbId);

	require Connectors::HeliosConnector::HelperWriter;

	$res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_order( "$pcbId" . "-" . $lastOrder, $state, "odsouhlasovat" );

	return $res;
}

# Update item multiplicity in last order
sub UpdateOrderMultiplicity {
	my $self  = shift;
	my $pcbId = shift;
	my $nas   = shift;
	my $res   = 0;

	my $lastOrder = $self->GetPcbOrderNumber($pcbId);

	require Connectors::HeliosConnector::HelperWriter;

	$res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_order( "$pcbId" . "-" . $lastOrder, $nas, "nasobnost" );

	return $res;
}

sub UpdateNCInfo {
	my $self        = shift;
	my $pcbId       = shift;
	my $ncInfo      = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdateNCInfo", $pcbId, $ncInfo );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $ncInfo, "nc_info" );

		return $res;
	}

}

sub UpdateMaterialKind {
	my $self        = shift;
	my $pcbId       = shift;
	my $mat         = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdateMaterialKind", $pcbId, $mat );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $mat, "material_druh" );

		return $res;
	}

}

# Update base cu thickness in PCB
sub UpdateBaseCu {
	my $self        = shift;
	my $pcbId       = shift;
	my $baseCu      = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdateBaseCu", $pcbId, $baseCu );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $baseCu, "material_tloustka_medi" );

		return $res;
	}

}

# Update single x dimension
sub UpdatePCBDim {
	my $self        = shift;
	my $pcbId       = shift;
	my $dimType     = shift;    # "kus_x"/"kus_y"/"panel_x"/"panel_y"
	my $dim         = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdateSingleDimension", $pcbId, $dim );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $dim, $dimType );

		return $res;
	}
}

# update column pooling in pcb order
sub UpdatePooling {
	my $self        = shift;
	my $order       = shift;
	my $isPool      = shift;
	my $childThread = shift;

	$isPool = $isPool ? "A" : "N";

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdatePooling", $order, $isPool );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_order( "$order", $isPool, "pooling" );

		return $res;
	}

}

# Opdate column aktualni_krok in pcb order
sub UpdatePcbOrderState {
	my $self        = shift;
	my $pcbId       = shift;
	my $state       = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdatePcbOrderState", $pcbId, $state );

		return $result;
	}
	else {

		require Connectors::HeliosConnector::HelperWriter;

		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_order( "$pcbId", $state, "aktualni_krok" );

		return $res;
	}

}

sub UpdateSilkScreen {
	my $self        = shift;
	my $pcbId       = shift;
	my $side        = shift;    # top/bot
	my $value       = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdateSilkScreen", $pcbId, $side, $value );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = undef;

		if ( $side eq "top" ) {

			$res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $value, "potisk_c_1" );
		}
		else {

			$res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $value, "potisk_s_1" );
		}

		return $res;
	}
}

sub UpdateSolderMask {
	my $self        = shift;
	my $pcbId       = shift;
	my $side        = shift;    # top/bot
	my $value       = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdateSolderMask", $pcbId, $side, $value );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = undef;

		if ( $side eq "top" ) {

			$res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $value, "maska_c_1" );
		}
		else {

			$res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_pcb( "$pcbId", $value, "maska_s_1" );
		}

		return $res;
	}
}

# update column pooling in pcb order
sub UpdateOrderTerm {
	my $self        = shift;
	my $order       = shift;
	my $term        = shift;
	my $childThread = shift;

	if ($childThread) {

		my $result = $self->__SystemCall( "UpdateOrderTerm", $order, $term );

		return $result;
	}
	else {

		#use Connectors::HeliosConnector::HelperWriter;
		require Connectors::HeliosConnector::HelperWriter;

		my $res = Connectors::HeliosConnector::HelperWriter->OnlineWrite_order( "$order", $term, "termin" );

		return $res;
	}

}

# Return value from clolumn "stav" for pcb order
#Poøízeno na eshopu (02)
#Zavedeno (0)
#Na pøíjmu (1)
#Pozastavena (12)
#Pøedvýrobní pøíprava (2)
#Na odsouhlasení (25)
#Schválena (35)
#Ve výrobì (4)
#Vykrytí ze skladu (42)
#V kooperaci (45)
#Stornována (5)
#Ukonèena (7)
sub GetStatusOfOrder {
	my $self      = shift;
	my $orderId   = shift;
	my $editStyle = shift;    # if checked ,return value will be edited by style

	my $column = "stav";

	if ($editStyle) {
		$column = "lcs.nf_edit_style('stav_zakazky_dps_22', stav) stav";
	}

	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $cmd = "SELECT top 1
				$column
				from lcs.zakazky_dps_22_hlavicka 
				WHERE reference_subjektu = _OrderId";

	my $res = Helper->ExecuteScalar( $cmd, \@params, 1 );

	return $res;
}

# Return value from clolumn "aktualni krok" for pcb order

sub GetCurStepOfOrder {
	my $self    = shift;
	my $orderId = shift;

	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $cmd = "select top 1
				 t1.aktualni_krok
				from lcs.zakazky_dps_22_hlavicka AS t1
				WHERE reference_subjektu = _OrderId";

	my $res = Helper->ExecuteScalar( $cmd, \@params, 1 );

	return $res;
}

# The select get back 3 values:
# M for master order
# S for slave order
# 0 > without poolservisu
sub GetInfMasterSlave {
	my $self    = shift;
	my $orderId = shift;

	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $cmd = "SELECT top 1
		case when vs1.cislo_vztaz_subjektu is not null then 'S' when vs2.cislo_subjektu is not null then 'M' else '0' end inftype
		FROM lcs.zakazky_dps_22_hlavicka z
		LEFT OUTER JOIN lcs.vztahysubjektu vs1 ON vs1.cislo_vztahu = 23054 and vs1.cislo_subjektu = z.cislo_subjektu
		LEFT OUTER JOIN lcs.vztahysubjektu vs2 ON vs2.cislo_vztahu = 23054 and vs2.cislo_vztaz_subjektu = z.cislo_subjektu
		WHERE z.reference_subjektu = _OrderId";

	my $res = Helper->ExecuteScalar( $cmd, \@params, 1 );

	return $res;
}

# Return value of term order
sub GetTermOfOrder {
	my $self    = shift;
	my $orderId = shift;

	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $cmd = "SELECT top 1
				termin
				from lcs.zakazky_dps_22_hlavicka 
				WHERE reference_subjektu = _OrderId";

	my $res = Helper->ExecuteScalar( $cmd, \@params, 1 );

	return $res;
}

# Return value of term order
sub GetAllByOrderId {
	my $self    = shift;
	my $orderId = shift;

	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $cmd = "SELECT top 1
				termin,
				datum_zahajeni,
				pocet_prirezu,
				prirezu_navic,
				kusy_pozadavek
				from lcs.zakazky_dps_22_hlavicka 
				WHERE reference_subjektu = _OrderId";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return %{ $result[0] };
}

# Return value of term order
sub GetStartTermOfOrder {
	my $self    = shift;
	my $orderId = shift;

	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $cmd = "SELECT top 1
				datum_zahajeni
				from lcs.zakazky_dps_22_hlavicka 
				WHERE reference_subjektu = _OrderId";

	my $res = Helper->ExecuteScalar( $cmd, \@params, 1 );

	return $res;
}

# Return list of actual TPV workers
sub GetTPVEmployee {
	my $self = shift;

	my @params = ();

	my $cmd = "select katalog.nazev_subjektu,  z.prijmeni, z.jmeno, z.login_id, z.e_mail
		from lcs.zamestnanci z
		join lcs.vztahysubjektu vs on vs.cislo_vztahu = 6340 and vs.cislo_subjektu = z.cislo_subjektu
		join lcs.subjekty katalog on katalog.cislo_subjektu = vs.cislo_vztaz_subjektu
		where katalog.reference_subjektu in ('543000', '543100')
		and z.je_zamestnanec = 'A'
		order by 1, 2";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

# Get all ReOrders
# Pcb has order number begger than -01 + are on state 'Predvyrobni priprava'
sub GetReorders {
	my $self = shift;

	my @params = ();

	my $cmd = "select distinct z.reference_subjektu, 
								z.stav, 
								z.aktualni_krok, 
								d.stav AS dps_stav,
								d.reference_subjektu AS deska_reference_subjektu
				from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska
				where 
				z.cislo_poradace = 22050 
				and z.stav='2'";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	@result = grep { $_->{"reference_subjektu"} !~ /-01/ } @result;

	return @result;
}

# Return orders with ancestor in pcb
# Option  is status
sub GetOrdersWithAncestor {
	my $self     = shift;
	my $statuses = shift;

	my @params = ();

	my $cmd = "SELECT z.reference_subjektu, 
					  z.pooling,
					  z.aktualni_krok,
					  p.reference_subjektu as ancestor_pcb
					  
				FROM lcs.zakazky_dps_22_hlavicka z
				JOIN lcs.vztahysubjektu vs ON vs.cislo_vztahu = 23291 and vs.cislo_subjektu = z.deska
				JOIN lcs.desky_22 p ON p.cislo_subjektu = vs.cislo_vztaz_subjektu";

	if ( defined $statuses ) {

		my @statuses = map { "\'" . $_ . "\'" } @{$statuses};
		my $strStatus = join( ",", @statuses );

		$cmd .= " WHERE z.stav IN ($strStatus)";
	}

	my @res = Helper->ExecuteDataSet( $cmd, \@params );

	return @res;

}

# Return all reorders by pcb id
sub GetPcbReorders {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select 				  
				 z.reference_subjektu,
				 z.stav,
				 z.aktualni_krok
				 from lcs.desky_22 d with (nolock)
				 
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu

				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc";

	my @res = Helper->ExecuteDataSet( $cmd, \@params );
	@res = grep { $_->{"reference_subjektu"} !~ /-01/ } @res;

	return @res;
}

# Get all ReOrders
# Pcb has order number begger than -01 + are on state 'Predvyrobni priprava'
sub GetPcbsInProduc {
	my $self = shift;

	my @params = ();

	my $cmd = "select distinct 
				d.reference_subjektu,
				d.material_typ
				from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska 
				left outer join lcs.vztahysubjektu vs on vs.cislo_vztahu = 23054 and vs.cislo_subjektu = z.cislo_subjektu 
				where 
				vs.cislo_vztaz_subjektu is null 
				and z.cislo_poradace = 22050 
				and z.stav='4'";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

# Get pcb by status (return desky not zakazky)
# Statusy:
#Poøízeno na eshopu (02)
#Zavedeno (0)
#Na pøíjmu (1)
#Pozastavena (12)
#Pøedvýrobní pøíprava (2)
#Na odsouhlasení (25)
#Schválena (35)
#Ve výrobì (4)
#Vykrytí ze skladu (42)
#V kooperaci (45)
#Stornována (5)
#Ukonèena (7)
sub GetPcbsByStatus {
	my $self     = shift;
	my @statuses = @_;

	unless ( scalar(@statuses) ) {
		die "No status defined";
	}

	@statuses = map { "\'" . $_ . "\'" } @statuses;
	my $strStatus = join( ",", @statuses );

	# IN (value1, value2, ...);

	my @params = ();

	#  OLD SELECET nevracel dps ktere jsou ve vzrobe, prestoye byl pozadavek na stav = 4
	#	my $cmd = "select distinct
	#				d.reference_subjektu,
	#				d.material_typ,
	#				z.stav
	#				from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska
	#				left outer join lcs.vztahysubjektu vs on vs.cislo_vztahu = 23054 and vs.cislo_subjektu = z.cislo_subjektu
	#				where vs.cislo_vztaz_subjektu is null and z.stav ='4'";

	my $cmd = "select distinct 
				d.reference_subjektu,
				d.material_typ,
				z.stav
				from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska
				WHERE 
				z.cislo_poradace = 22050 
				and z.stav IN ($strStatus)";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

# Get orders by status (return zakazky, not desky)
# Statusy:
#Poøízeno na eshopu (02)
#Zavedeno (0)
#Na pøíjmu (1)
#Pozastavena (12)
#Pøedvýrobní pøíprava (2)
#Na odsouhlasení (25)
#Schválena (35)
#Ve výrobì (4)
#Vykrytí ze skladu (42)
#V kooperaci (45)
#Stornována (5)
#Ukonèena (7)
sub GetOrdersByStatus {
	my $self     = shift;
	my @statuses = @_;

	unless ( scalar(@statuses) ) {
		die "No status defined";
	}

	@statuses = map { "\'" . $_ . "\'" } @statuses;
	my $strStatus = join( ",", @statuses );

	# IN (value1, value2, ...);

	my @params = ();

	my $cmd = "select   
 				z.stav,
				z.deska,
				z.reference_subjektu,
				z.aktualni_krok
				from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska
				WHERE 
				z.cislo_poradace = 22050 
				and z.stav IN ($strStatus)";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

# Return all pcb "In produce" which contain silkscreen bot or top
sub GetPcbsInProduceSilk {
	my $self = shift;

	# IN (value1, value2, ...);

	my @params = ();

	my $cmd = "select distinct 
                        d.reference_subjektu,
                        d.potisk_c_1 c_silk_screen_colour,
                        d.potisk_s_1 s_silk_screen_colour,
                        d.material_typ,
                        z.stav
                        from lcs.zakazky_dps_22_hlavicka z
                                        join lcs.desky_22 d on d.cislo_subjektu=z.deska 
                        left outer join lcs.vztahysubjektu vs on vs.cislo_vztahu = 23054 and vs.cislo_subjektu = z.cislo_subjektu 
                        where 
                        vs.cislo_vztaz_subjektu is null and 
                        z.stav = 4 
                        and z.cislo_poradace = 22050 
                        and (d.potisk_c_1 IS NOT NULL OR d.potisk_s_1 IS NOT NULL)";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

# Return pcb, which MDI data has to be exported
sub GetPcbsInProduceMDI {
	my $self = shift;

	my @params = ();

	my $cmd = "select distinct d.reference_subjektu, d.material_typ
				from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska 
				left outer join lcs.vztahysubjektu vs on vs.cislo_vztahu = 23054 and vs.cislo_subjektu = z.cislo_subjektu 
				where 
				vs.cislo_vztaz_subjektu is null 
				and z.cislo_poradace = 22050 
				and z.stav='4'";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	@result = grep { $_->{"material_typ"} !~ /[t0s]/i } @result;

	return @result;
}

# Return store information about prepreg defined by multical ids
sub GetCopperStoreInfoByUDA {
	my $self = shift;
	my $id   = shift;    # prepreg thick id

	return $self->GetMatStoreInfoByUDA( EnumsIS->MatType_COPPER, undef, $id );

}

# Return store information about prepreg defined by multical ids
sub GetPrepregStoreInfoByUDA {
	my $self     = shift;
	my $qId      = shift;    # quality id (DR4, IS400, ..)
	my $id       = shift;
	my $matXsize = shift;    # in mm
	my $matYsize = shift;    # in mm
	my $flex     = shift;    # prepreg thick id

	my $type = EnumsIS->MatType_PREPREG;

	$type = EnumsIS->MatType_PREPREGFLEX if ($flex);

	return $self->GetMatStoreInfoByUDA( $type, $qId, $id, undef, undef, $matXsize, $matYsize );

}

# Return store information about core defined by multical ids
sub GetCoreStoreInfoByUDA {
	my $self     = shift;
	my $qId      = shift;    # quality id (DR4, IS400, ..)
	my $id       = shift;    # core thick id
	my $id2      = shift;    # copper thick id
	my $matXsize = shift;    # in mm
	my $matYsize = shift;    # in mm

	return $self->GetMatStoreInfoByUDA( EnumsIS->MatType_CORE, $qId, $id, $id2, undef, $matXsize, $matYsize );
}

# Return infro from actual store from CNC store about material (copper, core, prepreg types only)
# qId, Id, Id2 are from UDA table and are refer to Multicall file "ml.xml",
# where are defined materials and qid
sub GetMatStoreInfoByUDA {
	my $self      = shift;
	my $matType   = shift;
	my $qId       = shift;
	my $id        = shift;
	my $id2       = shift;
	my $matHeight = shift;    # in mm
	my $matWidth  = shift;    # in mm
	my $matDepth  = shift;    # in mm

	my @params = (
				   SqlParameter->new( "_matType", Enums->SqlDbType_VARCHAR, $matType ),
				   SqlParameter->new( "__qId",    Enums->SqlDbType_INT,     $qId ),
				   SqlParameter->new( "__id",     Enums->SqlDbType_INT,     $id ),
				   SqlParameter->new( "__id2",    Enums->SqlDbType_INT,     $id2 )
	);

	my $where = "";
	if ( $matType eq EnumsIS->MatType_PREPREG ) {

		$where .= "and uda.dps_qid = __qId"

	}
	elsif ( $matType eq EnumsIS->MatType_CORE ) {

		$where .= "and uda.dps_qid = __qId and uda.dps_id2 = __id2";
	}

	if ( defined $matHeight ) {
		push( @params, SqlParameter->new( "__matHeight", Enums->SqlDbType_INT, $matHeight / 1000 ) );
		$where .= "and kks.vyska = __matHeight";
	}

	if ( defined $matWidth ) {
		push( @params, SqlParameter->new( "__matWidth", Enums->SqlDbType_INT, $matWidth / 1000 ) );
		$where .= "and kks.sirka = __matWidth";
	}

	if ( defined $matDepth ) {
		push( @params, SqlParameter->new( "__matDepth", Enums->SqlDbType_INT, $matDepth / 1000 ) );
		$where .= "and kks.hloubka = __matDepth";
	}

	my $cmd = "SELECT kks.reference_subjektu, 
					
					kks.nazev_subjektu as nazev_mat,
					kks.vyska * 1000 AS vyska,
					kks.sirka * 1000 AS sirka,
					kks.hloubka * 1000 AS hloubka,
					sklad.reference_subjektu, 
					sklad.nazev_subjektu, 
					ss.pocet_disp as stav_skladu, 
					ss.pocet_poptavano_vyroba,
					uda.dps_id, 
					uda.dps_id2, 
					uda.dps_qid
					
				FROM lcs.kmenova_karta_skladu kks
					join lcs.stav_sk ss on ss.zdroj = kks.cislo_subjektu
					join lcs.subjekty sklad on sklad.cislo_subjektu= ss.sklad
					join lcs.uda_kmenova_karta_skladu uda on uda.cislo_subjektu= kks.cislo_subjektu
				WHERE kks.usporadaci_znak = 'DPS'
					and ss.pocet_disp >= 0
					and sklad.nazev_subjektu LIKE '%cnc%'
					and uda.dps_type = _matType
					and uda.dps_id = __id
					$where";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

#
#sub GetPrepregInfoByUDA {
#	my $self     = shift;
#	my $qId      = shift;    # quality id (DR4, IS400, ..)
#	my $id       = shift;
#	my $flex     = shift;    # prepreg thick id
#
#	my $type = EnumsIS->MatType_PREPREG;
#
#	$type = EnumsIS->MatType_PREPREGFLEX if ($flex);
#
#	return $self->GetMatInfoByUDA( $type, $qId, $id);
#}
#
#
#sub GetCoreInfoByUDA {
#	my $self     = shift;
#	my $qId      = shift;    # quality id (DR4, IS400, ..)
#	my $id       = shift;    # core thick id
#	my $id2      = shift;    # copper thick id
#	my $matXsize = shift;    # in mm
#	my $matYsize = shift;    # in mm
#
#	return $self->GetMatInfoByUDA( EnumsIS->MatType_CORE, $qId, $id, $id2);
#}

## Return material info by material reference
#sub GetMatInfoByUDA {
#	my $self = shift;
#	my $matType = shift; # EnumsIS->MatType_<CORE/PREPREG/COPPER/>
#	my $matType   = shift;
#	my $qId       = shift;
#	my $id        = shift;
#	my $id2       = shift;
#
#	my @params = ();
#	push( @params, SqlParameter->new( "_matType", Enums->SqlDbType_VARCHAR, $matType ) );
#	push( @params, SqlParameter->new( "__qId",    Enums->SqlDbType_INT,     $qId ) ) if ( defined $qId );
#	push( @params, SqlParameter->new( "__id",     Enums->SqlDbType_INT,     $id ) ) if ( defined $id );
#	push( @params, SqlParameter->new( "__id2",    Enums->SqlDbType_INT,     $id2 ) ) if ( defined $id2 );
#
#	my $where = "";
#	if ( defined $id ) {
#
#		$where .= " uda.dps_id = __id";
#	}
#
#	if ( defined $qId ) {
#
#		$where .= " and uda.dps_qid = __qId";
#	}
#
#	if ( defined $id2 ) {
#
#		$where .= " and uda.dps_id2 = __id2";
#	}
#
#	my $cmd = "SELECT
#				kks.reference_subjektu,
#				kks.nazev_subjektu,
#				kks.vyska,
#				 uda.dps_id,
#  				 uda.dps_id2,
# 				 uda.dps_qid,
# 				 uda.dps_druh
#				FROM lcs.kmenova_karta_skladu kks
#				join lcs.uda_kmenova_karta_skladu uda on uda.cislo_subjektu= kks.cislo_subjektu
#				WHERE " . $where;
#
#	my @result = Helper->ExecuteDataSet( $cmd, \@params );
#	if (@result) {
#		return $result[0];
#	}
#	else {
#		return 0;
#	}
#}

# Return material info by material reference
sub GetMatInfo {
	my $self         = shift;
	my $matReference = shift;

	my @params = ( SqlParameter->new( "__matReference", Enums->SqlDbType_VARCHAR, $matReference ) );

	my $cmd = "SELECT 
				kks.reference_subjektu,
				kks.nazev_subjektu,
				kks.vyska,
				kks.doplnkovy_rozmer,
				 uda.dps_id,
  				 uda.dps_id2,
 				 uda.dps_qid,
 				  uda.dps_type
				FROM lcs.kmenova_karta_skladu kks
				join lcs.uda_kmenova_karta_skladu uda on uda.cislo_subjektu= kks.cislo_subjektu
				WHERE kks.reference_subjektu = __matReference";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );
	if (@result) {
		return $result[0];
	}
	else {
		return 0;
	}
}

# Return infro from actual store from CNC store for material by material reference
sub GetMatStoreInfo {
	my $self         = shift;
	my $matReference = shift;

	my @params = ( SqlParameter->new( "__matReference", Enums->SqlDbType_VARCHAR, $matReference ) );

	my $cmd = "SELECT 
					kks.reference_subjektu,
					kks.nazev_subjektu as nazev_mat,
					ss.pocet_disp as stav_skladu, 
					ss.pocet_poptavano_vyroba 
			 
					
				FROM lcs.kmenova_karta_skladu kks
					join lcs.stav_sk ss on ss.zdroj = kks.cislo_subjektu
					join lcs.subjekty sklad on sklad.cislo_subjektu= ss.sklad
			 
				WHERE kks.reference_subjektu = __matReference AND sklad.reference_subjektu = 130 ";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );
	if (@result) {
		return $result[0];
	}
	else {
		return 0;
	}

}

# Return information of coverlay material in PCB
sub GetPcbMat {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
	
				 kks.reference_subjektu material_coverlay_reference
				
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.kmenova_karta_skladu kks (nolock) on kks.cislo_subjektu=d.material
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my $matReference = Helper->ExecuteScalar( $cmd, \@params );

	my $res = undef;

	if ( defined $matReference ) {
		$res = $self->GetMatInfo($matReference);
	}
}

# Return information of coverlay material in PCB
sub GetPcbCoverlayMat {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
	
				 kks.reference_subjektu material_coverlay_reference
				
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.kmenova_karta_skladu kks (nolock) on kks.cislo_subjektu=d.material_coverlay
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my $matReference = Helper->ExecuteScalar( $cmd, \@params );

	my $res = undef;

	if ( defined $matReference ) {
		$res = $self->GetMatInfo($matReference);
	}
}

# Return information of stiffener material in PCB
sub GetPcbStiffenerMat {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				
				kks.reference_subjektu
				 
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 left outer join lcs.kmenova_karta_skladu kks (nolock) on kks.cislo_subjektu=d.material_stiffener
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my $matReference = Helper->ExecuteScalar( $cmd, \@params );

	my $res = undef;

	if ( defined $matReference ) {
		$res = $self->GetMatInfo($matReference);
	}
}

# Return number of cores in pcb
sub GetCoreCnt {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.pocet_jader
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	return Helper->ExecuteScalar( $cmd, \@params );
}

# Return info about all cores
# Each hash has key "core_num", which is number of core 1..n
sub GetCoreInfo {
	my $self    = shift;
	my $pcbId   = shift;
	my $coreNum = shift;

	my $coresCnt = $self->GetCoreCnt($pcbId);

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				$coreNum core_num,
				 d.vrtani_$coreNum vrtani
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@result) ) {

		return $result[0];
	}

	return 0;
}

# Return info about all cores
# Each hash has key "core_num", which is number of core 1..n
sub GetAllCoresInfo {
	my $self  = shift;
	my $pcbId = shift;

	my $coresCnt = $self->GetCoreCnt($pcbId);

	my @coreInfo = ();

	foreach my $coreNum ( 1 .. $coresCnt ) {

		push( @coreInfo, $self->GetCoreInfo( $pcbId, $coreNum ) );
	}

	return @coreInfo;
}

# Return sales specification from HEG for viewer F6
sub GetSalesSpec {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
                                               lcs.nf_edit_style('typ_ano_ne', d.rizena_impedance) Rizena_impedance,
                                               lcs.nf_edit_style('typ_ano_ne', d.merit_presfitt) Merit_PRESSFIT,
                                               lcs.nf_edit_style('typ_vrstvy_22', d.lak_typ) Snimaci_Lak,
                                               lcs.nf_edit_style('typ_vrstvy_22', d.uhlik_typ) Grafitova_vrstva,
                                               lcs.nf_edit_style('typ_ano_ne', d.mereni_tolerance_vrtani) Merit_toleranci_vrtani,
                                               lcs.nf_edit_style('datacode_typ', d.datacode_typ) Typ_DataCodu,
                                               lcs.nf_edit_style('ul_logo_typ', d.ul_logo_typ) Typ_ULlogo,
                                               d.zaplneni_otvoru_text Zaplneni_otvoru,
                                               lcs.nf_edit_style('typ_ano_ne', d.pohrbene_otvory) Pohrbene_otvory,
                                               lcs.nf_edit_style('typ_vrstvy_22', d.slepe_otvory) Slepe_otvory
                                               from lcs.desky_22 d with (nolock)
                                               left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
                                               left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
                                               left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
                                               left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
                                               left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
                                               left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
                                               left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
                                               left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
                                               where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
                                               order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if (@result) {
		return @result;
	}
	else {
		return undef;
	}
}

sub GetSalesSpecPanel {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
                                              
                                               lcs.nf_edit_style('zpusob_vytvoreni_panelu_22', d.zpusob_vytvoreni_panelu) Zpusob_vytvoreni_panelu,
                                               lcs.nf_edit_style('typ_okoli_dps', d.typ_tech_okoli) Typ_tech_okoli,
                                               lcs.nf_edit_style('pool_format_dodanych_dat_22', d.pool_format_dodanych_dat) Pool_format_dodanych_dat,
                                               d.mezera_mezi_kusy Mezera_mezi_kusy,
                                               d.sirka_tech_okoli Sirka_tech_okoli,
                                               d.panel_x Rozmer_panelu_X,
                                               d.panel_y Rozmer_panelu_Y,
                                               d.nasobnost_pool_panelu_x Nasobnost_pool_panelu_x,
                                               d.nasobnost_pool_panelu_y Nasobnost_pool_panelu_y
                                               from lcs.desky_22 d with (nolock)
                                               left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
                                               left outer join lcs.subjekty m with (nolock) on m.cislo_subjektu=d.material
                                               left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
                                               left outer join lcs.vztahysubjektu vs with (nolock) on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175
                                               left outer join lcs.zakazky_dps_22_hlavicka n with (nolock) on vs.cislo_vztaz_subjektu=n.cislo_subjektu
                                               left outer join lcs.subjekty prijal with (nolock) on prijal.cislo_subjektu=n.prijal
                                               left outer join lcs.desky_22 dn with (nolock) on n.deska=dn.cislo_subjektu
                                               left outer join lcs.subjekty mn with (nolock) on mn.cislo_subjektu=dn.material
                                               where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
                                               order by z.reference_subjektu desc,n.cislo_subjektu desc,z.cislo_subjektu desc";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if (@result) {
		return @result;
	}
	else {
		return undef;
	}
}

sub GetPcbAncestor {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "__PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "SELECT p.reference_subjektu
				FROM lcs.desky_22 d
				JOIN lcs.vztahysubjektu vs ON vs.cislo_vztahu = 23291 and vs.cislo_subjektu = d.cislo_subjektu
				JOIN lcs.desky_22 p ON p.cislo_subjektu = vs.cislo_vztaz_subjektu
				WHERE d.reference_subjektu = __PcbId";

	my @res = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@res) ) {

		return $res[0];

	}
	else {

		return undef;
	}

}

# Get all ReOrders
# Pcb has order number begger than -01 + are on state 'Predvyrobni priprava'
sub GetAllMatKinds {
	my $self = shift;

	my @params = ();

	my $cmd = "SELECT
       			data_val,
       			disp_val
				FROM lcs.editstyles
				WHERE name = 'ddlb_22_material_druh'";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );
	my %mats = ();
	for ( my $i = 0 ; $i < scalar(@result) ; $i++ ) {

		my %inf = ();
		$mats{ $result[$i]{'data_val'} } = ( $result[$i]{'disp_val'} =~ /tg\s*(\d+)/i )[0];

	}

	# Add extra material DE104 = FR4
	$mats{"DE104"} = $mats{"FR4"};

	return %mats;
}

sub GetImpedancExist {
	my $self  = shift;
	my $pcbId = shift;
	my $res   = 0;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 d.rizena_impedance
				 from lcs.desky_22 d with (nolock)
				  left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	$res = Helper->ExecuteScalar( $cmd, \@params );

	if ( $res && $res eq "A" ) {
		return 1;
	}
	else {
		return 0;
	}

}

# Return information about all production order by order id
# Available statuses of product order
#Poøízený (P)
#Uvolnìný (N)
#Ukonèený (J)
#Uzavøený (Z)
#Ukonèený (A)
#Odloženo (O)
sub GetProducOrderByOederId {
	my $self            = shift;
	my $orderId         = shift;
	my $extraProducId = shift ;    # pouze prikazy s cislem dodelavky vetsi jak 0
	my $status          = shift;         #  status of Produc order

 
	my @params = ( SqlParameter->new( "_OrderId", Enums->SqlDbType_VARCHAR, $orderId ) );

	my $extraProducCMD = "";
	if(defined $extraProducId){
		
		$extraProducCMD = " and udapo.cislo_dodelavky = $extraProducId /* jedna se o dodelavku */";
	}

	my $statusCMD = "";
	if(defined $status){
		
		$statusCMD = " and po.status = '".uc($status)."'";
	}

	my $cmd = "select
      		 udapo.cislo_dodelavky,
      		 po.status,
      		 lcs.nf_edit_style('mfr_prod_order_status', po.status) status_text,
      		 po.status,
      		 po.nazev_subjektu,
      		 po.qty_source,
      		 po.cislo_subjektu,
      		 z.kusy_pozadavek,
			z.pocet_prirezu,
			z.prirezu_navic,
			z.datum_zahajeni,
			z.termin,
			d.nasobnost,
			CEILING(po.qty_source/d.nasobnost) AS prirezy_dodelavka
		from lcs.product_order po
      		 join lcs.uda_product_order udapo on udapo.cislo_subjektu = po.cislo_subjektu
      		 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.reference_subjektu=po.nazev_subjektu
      		 left outer join lcs.desky_22 d with (nolock) on d.cislo_subjektu=z.deska
		where po.nazev_subjektu = _OrderId /* cislo_subjektu zakazky dps */
      		 and po.nazev_subjektu not like '%-J%' /* odfiltrovani jader */
      		 $extraProducCMD
      		 $statusCMD";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

#-------------------------------------------------------------------------------------------#
#  Helper method
#-------------------------------------------------------------------------------------------#

sub __SystemCall {
	my $self       = shift;
	my $methodName = shift;
	my @params     = @_;

	my $script = GeneralHelper->Root() . "\\Connectors\\HeliosConnector\\UpdateScript.pl";

	my $systemCall = SystemCall->new( $script, $methodName, @params );
	my $result = $systemCall->Run();

	unless ($result) {

		my $out = $systemCall->GetOutput();
		die HeliosException->new( EnumsErrors->HELIOSDBREADERROR, "no details" );
	}

	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::HeliosConnector::HegMethods';
	use Data::Dump qw(dump);

	#	my @matTop = HegMethods->GetPrepregStoreInfoByUDA( 10, 1 , undef, undef, 1);
	#	dump(@matTop);

	my $mat = HegMethods->GetAllByPcbId( "X65285" );

	dump($mat);
	die;
}

1;

