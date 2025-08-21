import pandas as pd
from db_utils import DatabaseConnection, read_sql_file

def null_if_empty(val):
    return val if val else "NULL"

def run_report(sql_path, params):
    sql = read_sql_file(sql_path)
    for key, value in params.items():
        sql = sql.replace(key, value)
    db = DatabaseConnection()
    db.connect()
    try:
        df = db.execute_query(sql)
    finally:
        db.close()
    return df

# --- Sorgu Fonksiyonları ---

def run_arsiv_verileri(firma, tarih1, tarih2, solmazrefno="", refnofirma="", tescilno="", sql_path="tum_sorgular/Arşiv_Verileri-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$tarih1": tarih1,
        "$tarih2": tarih2,
        "$solmazrefno": null_if_empty(solmazrefno),
        "$refnofirma": null_if_empty(refnofirma),
        "$tescilno": null_if_empty(tescilno)
    }
    return run_report(sql_path, params)

def run_ayrintili_depo_hareket_raporu(firma, lojistikdepo, tarih1, tarih2, harekettur="H", onaytip="H", sql_path="tum_sorgular/Ayrıntılı_Depo_Hareket_Raporu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$lojistikdepo": lojistikdepo,
        "$tarih1": tarih1,
        "$tarih2": tarih2,
        "$harekettur": harekettur,
        "$onaytip": onaytip
    }
    return run_report(sql_path, params)

def run_beyanname_bazinda_maliyet_raporu(firma, tarih1, tarih2, solmazrefno="", refnofirma="", tescilno="", sql_path="tum_sorgular/Beyanname_Bazinda_Maliyet_Raporu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$tarih1": tarih1,
        "$tarih2": tarih2,
        "$solmazrefno": null_if_empty(solmazrefno),
        "$refnofirma": null_if_empty(refnofirma),
        "$tescilno": null_if_empty(tescilno)
    }
    return run_report(sql_path, params)


def run_beyanname_islem_sureleri_raporu(firma, tarih1, tarih2, solmazrefno="", refnofirma="", tescilno="", sql_path="tum_sorgular/Beyanname_İşlem_Süreleri_Raporu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$tarih1": tarih1,
        "$tarih2": tarih2,
        "$solmazrefno": null_if_empty(solmazrefno),
        "$refnofirma": null_if_empty(refnofirma),
        "$tescilno": null_if_empty(tescilno)
    }
    return run_report(sql_path, params)

def run_depo_stok_miktarlari_raporu(firma, lojistikdepo, paletno="", sql_path="tum_sorgular/Depo_Stok_Miktarları-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$lojistikdepo": lojistikdepo,
        "$paletno": null_if_empty(paletno)
    }
    return run_report(sql_path, params)

def run_firma_beyannameleri_gtip_bazinda_rapor(firma, tarih1, tarih2, solmazrefno="", refnofirma="", tescilno="", sql_path="tum_sorgular/Firma_Beyannameleri_GTİP_Bazında_Rapor-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$tarih1": tarih1,
        "$tarih2": tarih2,
        "$solmazrefno": null_if_empty(solmazrefno),
        "$refnofirma": null_if_empty(refnofirma),
        "$tescilno": null_if_empty(tescilno)
    }
    return run_report(sql_path, params)

def run_genel_master_rapor(firma, tarih1, tarih2, solmazrefno="", refnofirma="", tescilno="", faturano="", sql_path="tum_sorgular/Genel_Master_Rapor-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$tarih1": tarih1,
        "$tarih2": tarih2,
        "$solmazrefno": null_if_empty(solmazrefno),
        "$refnofirma": null_if_empty(refnofirma),
        "$tescilno": null_if_empty(tescilno),
        "$faturano": null_if_empty(faturano)
    }
    return run_report(sql_path, params)

def run_gonderi_sorgulama_lokasyon_raporu(firma, tarih1, tarih2, sql_path="tum_sorgular/Gönderi_Sorgulama_Lokasyon_Raporu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$tarih1": tarih1,
        "$tarih2": tarih2
    }
    return run_report(sql_path, params)

def run_gun_bazli_antrepo_stok_durumu(firma, lojistikdepo, tarih1, sql_path="tum_sorgular/Gün_Bazlı_Antrepo_Stok_Durumu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$lojistikdepo": lojistikdepo,
        "$tarih1": tarih1
    }
    return run_report(sql_path, params)

def run_is_emri_listesi(firma, tasktip, durum, lojistikdepo, tarih1, tarih2, sql_path="tum_sorgular/İş_Emri_Listesi-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$tasktip": tasktip,
        "$durum": durum,
        "$lojistikdepo": lojistikdepo,
        "$tarih1": tarih1,
        "$tarih2": tarih2
    }
    return run_report(sql_path, params)

def run_islemdeki_dosyalar_raporu(firma, solmazrefno="", tescilno="", faturano="", refnofirma="", sql_path="tum_sorgular/İşlemdeki_Dosyalar_Raporu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$solmazrefno": null_if_empty(solmazrefno),
        "$tescilno": null_if_empty(tescilno),
        "$faturano": null_if_empty(faturano),
        "$refnofirma": null_if_empty(refnofirma)
    }
    return run_report(sql_path, params)

def run_kullanilabilir_stok_raporu(firma, lojistikdepo, sql_path="tum_sorgular/Kullanılabilir_Stok_Raporu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$lojistikdepo": lojistikdepo
    }
    return run_report(sql_path, params)

def run_kumulatif_depo_hareket_raporu(firma, lojistikdepo, tarih1, tarih2, harekettur="H", sql_path="tum_sorgular/Kümülatif_Depo_Hareket_Raporu-POSTGRESQL.sql"):
    params = {
        "$firma": firma,
        "$lojistikdepo": lojistikdepo,
        "$tarih1": tarih1,
        "$tarih2": tarih2,
        "$harekettur": harekettur
    }
    return run_report(sql_path, params)

def run_stok_kalan_gun_report(firma, lojistikdepo, tarih1, sql_path="tum_sorgular/STK_Bazlı_Stok_Kalan_Gün_Raporu__PALET-POSTGRESQL.sql"):
    params = {
        "$firma": f"'{firma}'",
        "$lojistikdepo": f"'{lojistikdepo}'",
        "$tarih1": f"'{tarih1}'"
    }
    return run_report(sql_path, params)

if __name__ == "__main__":

    print("\nArşiv Verileri Raporu:")
    df1 = run_arsiv_verileri(
        firma="CMP59BHUBJ1126",
        tarih1="2024-01-01",
        tarih2="2024-06-01",
        solmazrefno="",
        refnofirma="",
        tescilno=""
    )
    print(df1)

    print("\nAyrıntılı Depo Hareket Raporu:")
    df2 = run_ayrintili_depo_hareket_raporu(
        firma="CMPBHLFKRMD205",
        lojistikdepo="DEP217",
        tarih1="2025-01-01",
        tarih2="2025-06-30",
        harekettur="H",
        onaytip="H"
    )
    print(df2)


    print("\nBeyanname Bazında Maliyet Raporu:")
    df3 = run_beyanname_bazinda_maliyet_raporu(
        firma="CMP59BHUBJ1126",
        tarih1="2025-01-01",
        tarih2="2025-06-30",
        solmazrefno="",
        refnofirma="",
        tescilno=""
    )
    print(df3)


    print("\nBeyanname İşlem Süreleri Raporu:")
    df4 = run_beyanname_islem_sureleri_raporu(
        firma="CMP59BHUBJ1126",
        tarih1="2025-01-01",
        tarih2="2025-06-30",
        solmazrefno="",
        refnofirma="",
        tescilno=""
    )
    print(df4)

    print("\nDepo Stok Miktarları Raporu:")
    df5 = run_depo_stok_miktarlari_raporu(
        firma="CMPBHLFKRMD205",
        lojistikdepo="DEP421",
        paletno=""
    )
    print(df5)

    print("\nFirma Beyannameleri GTİP Bazında Rapor:")
    df6 = run_firma_beyannameleri_gtip_bazinda_rapor(
        firma="CMP59BHUBJ1126",
        tarih1="2025-01-01",
        tarih2="2025-06-30",
        solmazrefno="",
        refnofirma="",
        tescilno=""
    )
    print(df6)

    print("\nGenel Master Rapor:")
    df7 = run_genel_master_rapor(
        firma="CMP59BHUBJ1126",
        tarih1="2025-01-01",
        tarih2="2025-06-30",
        solmazrefno="",
        refnofirma="",
        tescilno="",
        faturano=""
    )
    print(df7)

    print("\nGönderi Sorgulama Lokasyon Raporu:")
    df8 = run_gonderi_sorgulama_lokasyon_raporu(
        firma="CMP84HLHHS111W",
        tarih1="2025-01-01",
        tarih2="2025-06-30"
    )
    print(df8)

    print("\nGün Bazlı Antrepo Stok Durumu:")
    df9 = run_gun_bazli_antrepo_stok_durumu(
        firma="CMPBHLFKRMD205",
        lojistikdepo="DEP421",
        tarih1="2025-01-01"
    )
    print(df9)

    print("\nİş Emri Listesi:")
    df10 = run_is_emri_listesi(
        firma="CMPBHLFKRMD205",
        tasktip="GSF",
        durum="H",
        lojistikdepo="DEP421",
        tarih1="2025-01-01",
        tarih2="2025-06-30"
    )
    print(df10)

    print("\nİşlemdeki Dosyalar Raporu:")
    df11 = run_islemdeki_dosyalar_raporu(
        firma="CMP59BHUBJ1126",
        solmazrefno="",
        tescilno="",
        faturano="",
        refnofirma=""
    )
    print(df11)

    print("\nKullanılabilir Stok Raporu:")
    df12 = run_kullanilabilir_stok_raporu(
        firma="CMPBHLFKRMD205",
        lojistikdepo="DEP421"
    )
    print(df12)

    print("\nKümülatif Depo Hareket Raporu:")
    df13 = run_kumulatif_depo_hareket_raporu(
        firma="CMPBHLFKRMD205",
        lojistikdepo="DEP421",
        tarih1="2025-01-01",
        tarih2="2025-06-30",
        harekettur="H"
    )
    print(df13)

    print("\nSTK Bazlı Stok Kalan Gün Raporu:")
    df14 = run_stok_kalan_gun_report("CMPBHLFKRMD205", "DEP421", "2023-05-01")
    print(df14)