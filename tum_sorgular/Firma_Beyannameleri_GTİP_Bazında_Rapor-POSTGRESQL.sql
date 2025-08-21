--EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
--EXPLAIN (ANALYZE, BUFFERS)
WITH _yetkili_firmalar_cte AS (
    SELECT c_sub.firma        --> Bı kısım için DISTINCT'e gerek olmamalı. UP
    FROM slz05.gumfirma       AS c_sub
    JOIN ortak.mfyhesapai     AS mha_sub ON mha_sub.eskihesap  = c_sub.kartno       AND mha_sub.merkezid = 'CMP-SOLGUM-IST'::VARCHAR
    JOIN ortak.mfykartext     AS mke_sub ON mke_sub.hesap      = mha_sub.yenihesap  AND mke_sub.externalid = '$firma'::VARCHAR
)
SELECT
    a.evrno                                                                         AS solmaz_referans_no
  , a.referans                                                                      AS firma_referans
  , CASE a.durumtip
      WHEN 'K' THEN 'Kapalı'
      WHEN 'A' THEN 'Açık'
      ELSE NULL
    END                                                                             AS durum_tip
  , TO_CHAR(a.trhtescil, 'YYYY-MM-DD')                                              AS tescil_tarihi
  , TO_CHAR(a.trhtescil, 'HH24:MI')                                                 AS tescil_saati
  , a.tescilno                                                                      AS tescil_no
  , a.dosyaturu                                                                     AS dosya_turu
  , _statu.statu                                                                    AS statu
  , _gum_beyanfat.fatura_no                                                         AS fatura_no    --  , SUBSTRING(slz05.gum_beyanfatno(a.evrcinsi::INTEGER, a.evrseri::VARCHAR, a.evrno::NUMERIC)::VARCHAR FROM 1 FOR 80) AS fatura_no
  , _gum_beyanfat.fatura_bilgi                                                      AS fatura_bilgi --  , TRIM(SUBSTRING(slz05.fn_gum_beyanfat(a.evrcinsi, a.evrseri, a.evrno) FROM 1 FOR 80))   AS fatura_bilgi
  , a.beyan1
  , a.beyan2
  , CASE COALESCE(a.arc_id, 0) WHEN 0 THEN 'HAYIR' ELSE 'EVET' END                  AS arsivlenmis
  , a.teslimsek                                                                     AS teslim_sekli
  , m.sirano                                                                        AS kalem_sira_no
  , m.gtip                                                                          AS GTIP
  , _stok.stok_no_agg                                                               AS stok_no
  , TRIM(SUBSTRING(m.ekbilgi FROM 81 FOR 210))                                      AS ticari_ad      --> Anladıysam arap olayım: Mutlaka mantıklı bir açıklaması vardır ama böyle bir yönteme gerek varmıydı, işte asıl soru o... UP
  , m.rejim1
  , m.rejim2
  , _kdv.kdv
  , _kdv.matrah                                                                     AS kdvmatrah
  , _arac.max_tasit                                                                 AS tasit
  , _kons.max_ozetbeyanno                                                           AS ozet_beyan_no
  , _kons.max_tarih                                                                 AS konsimento_tarih
  , a.tutar                                                                         AS beyanname_toplam_tutar
  , m.tutar                                                                         AS kalem_tutar
  , CASE a.dovizkod WHEN 'YTL' THEN 'TL' ELSE a.dovizkod END                        AS doviz_kodu
  , a.kapsayi                                                                       AS kap_sayi
  , m.kapa_miktar                                                                   AS miktar
  , m.st_birim                                                                      AS adet
  , m.brutag                                                                        AS brut_agirlik
  , m.netag                                                                         AS net_agirlik
--  , ROUND(slz05.fn_calckur(a.dovizkod, '1', a.tesciltarih, a.tutar, 'USD'),4)             AS toplam_istat_kiymet_usd_deger
  , m.istatdeger                                                                    AS istatiki_kiymet_tl
  , a.hd_topcif                                                                     AS top_cif_tl
  , a.hd_yui                                                                        AS yurtici_gider
  , a.hd_iskonto                                                                    AS iskonto
  , a.hd_faiz                                                                       AS faiz
  , a.hd_diger                                                                      AS diger
  , a.hd_navlun                                                                     AS navlun
  , a.hd_sigorta                                                                    AS sigorta
  , _finfisbas.solmaz_kom_fat_tarihi                                                AS solmaz_kom_fat_tarihi  --, slz05.fn_refevrtar(290, a.evrcinsi, a.evrseri, a.evrno, a.firma)                      AS solmaz_kom_fat_tarihi
  , _finfisbas.solmaz_kom_fat_no                                                    AS solmaz_kom_fat_no      --, slz05.fn_refevrno(290, a.evrcinsi, a.evrseri, a.evrno, a.firma)                       AS solmaz_kom_fat_no
  , _finfismad.solmaz_kom_fat_kalem_bazinda_kdvsiz_dosya_adi                        as solmaz_kom_fat_kalem_bazinda_kdvsiz_dosya_adi  --  , ROUND(slz05.fn_toprefevrdettl(290, a.evrcinsi, a.evrseri, a.evrno, 10)) AS solmaz_kom_fat_kalem_bazinda_kdvsiz_dosya_adi
  , _finfismad.fatura_masraf_tl                                                     as fatura_masraf_tl                               --  , slz05.fn_toprefevrdettl(290, a.evrcinsi, a.evrseri, a.evrno, 20) AS fatura_masraf_tl
  , _finfisbas.dekont_tarihi                                                        AS dekont_tarihi          --, slz05.fn_refevrtar(263, a.evrcinsi, a.evrseri, a.evrno, a.firma)                      AS dekont_tarihi
  , _finfisbas.dekont_no                                                            AS dekont_no              --, slz05.fn_refevrno(263, a.evrcinsi, a.evrseri, a.evrno, a.firma)                       AS dekont_no
  , _finfismad.dekont_tl                                                            AS dekont_tl              --, slz05.fn_toprefevrtl(263::integer, a.evrcinsi::integer, a.evrseri::varchar, a.evrno::numeric AS dekont_tl
  , _top_masraflar.mesai_kod_15                                                     AS mesai              -- UYARI: fn_toprefmasrafdet çağrısı LATERAL JOIN ile optimize edildi.
  , _masraf_dekontlu.ardiye_tutari                                                  AS ardiye
  , _masraf_dekontlu.ordino_tutari                                                  AS ordino
  , _gum_dosdekdet.YI_nakliye                                                       AS YI_nakliye         --  , slz05.fn_gum_dosyadekdet(a.evrcinsi, a.evrseri, a.evrno, 11) AS YI_nakliye
  , _gum_dosdekdet.tse_masraf                                                       AS tse_masraf         --  , slz05.fn_gum_dosyadekdet(a.evrcinsi, a.evrseri, a.evrno, 18) AS tse_masraf
  --, _gum_beyvergi.teminat_tutari                                                    AS teminat            --  , slz05.fn_gum_beyvergi('L', a.evrcinsi, a.evrseri, a.evrno)   AS teminat ÇOK YAVAŞ ! UP
  , COALESCE(_lat_edi_vergi.tutar, _lat_beyan_vergi.tutar, 0)                       AS teminat              --  , slz05.fn_gum_beyvergi('L', a.evrcinsi, a.evrseri, a.evrno)   AS teminat... Bunu iki ayrı lateral joine bölüp select kısmında dolu olanı seçerek gösterdik. UP

  , a.tem_tur                                                                       AS tem_tur
  , a.kalemsayi                                                                     AS kalem_sayi
  , a.trhdosyaac                                                                    AS tarih_dosya_ac1
  , TRIM(kf.unvan)                                                                  AS karsi_firma_unvan
  , TRIM(k.aciklama)                                                                AS gumruk
  , _ulkeler.ticari_ulke
  , _ulkeler.sevk_ulke
  , _ulkeler.mense
  , _ulkeler.gidecegi_ulke
  , a.trhmalgelis                                                                   AS mal_gelis_tarih
  , a.trhfiiliithal                                                                 AS vezne_tarih
  , a.trhsevk                                                                       AS sevk_tarih
  , (a.trhsevk::DATE - a.tesciltarih::DATE) + 1                                     AS esya_sevk_sure
  , a.trhisemir                                                                     AS is_emri_tarihi
  , a.manifestotrh                                                                  AS ozet_beyan_tarih
  , a.antrepokod                                                                    AS antrepo_kod
  , TRIM(b.ad) || ' ' || TRIM(b.il) || ' ' || TRIM(b.bankasube)                     AS banka_adi
  , o.aciklama                                                                      AS odeme_sekli
  , _top_masraflar.ic_bosaltma_kod_5                                                AS ic_bosaltma
  , _top_masraflar.Faiz_6_kod_6                                                     AS Faiz_6
  , _top_masraflar.Tahmil_Tahliye_kod_7                                             AS Tahmil_Tahliye
  , _top_masraflar.Gumruk_Vergisi_kod_9                                             AS Gumruk_Vergisi
  , _top_masraflar.Ardiye_ucreti_110_kod_110                                        AS Ardiye_ucreti_110
  , _top_masraflar.Yurtdisi_Nakliye_112_kod_112                                     AS Yurtdisi_Nakliye_112
  , _top_masraflar.Yurtdisi_Navlun_kod_12                                           AS Yurtdisi_Navlun
  , _top_masraflar.Ordino_13_kod_13                                                 AS Ordino_13
  , _top_masraflar.Kargo_ucreti_kod_14                                              AS Kargo_ucreti
  , _top_masraflar.Mesai_15_kod_15                                                  AS Mesai_15
  , _top_masraflar.HARC_kod_16                                                      AS HARC
  , _top_masraflar.Sigorta_17_kod_17                                                AS Sigorta_17
  , _top_masraflar.TSE_kod_18                                                       AS TSE
  , _top_masraflar.Fotokopi_kod_19                                                  AS Fotokopi
  , _top_masraflar.Noter_kod_20                                                     AS Noter
  , _top_masraflar.ihracatcilar_Birligi_kod_21                                      AS ihracatcilar_Birligi
  , _top_masraflar.Tarti_ucreti_kod_24                                              AS Tarti_ucreti
  , _top_masraflar.Gelir_Eksigi_kod_25                                              AS Gelir_Eksigi
  , _top_masraflar.Gozetim_Raporu_kod_26                                            AS Gozetim_Raporu
  , _top_masraflar.demuraj_kod_28                                                   AS demuraj
  , _top_masraflar.Serbest_Bolge_kod_29                                             AS Serbest_Bolge
  , _top_masraflar.analiz_kod_30                                                    AS analiz
  , _top_masraflar.Ceza_kod_31                                                      AS Ceza
  , _top_masraflar.Tercume_kod_32                                                   AS Tercume
  , _top_masraflar.Havale_Masrafi_kod_33                                            AS Havale_Masrafi
  , _top_masraflar.Konsimento_kod_34                                                AS Konsimento
  , _top_masraflar.isgum_kod_38                                                     AS isgum
  , _top_masraflar.Yemek_Bedeli_kod_39                                              AS Yemek_Bedeli
  , _top_masraflar.damga_vergisi_kod_40                                             AS damga_vergisi
  , _top_masraflar.Ordino_Depozitosu_kod_23                                         AS Ordino_Depozitosu
  , _top_masraflar.olcu_Ayar_kod_53                                                 AS olcu_Ayar
  , _top_masraflar.Tahmil_Tahliye_Gecici_kod_999                                    AS Tahmil_Tahliye_Gecici
  , _top_masraflar.Gumruk_Depo_Teminat_kod_22                                       AS Gumruk_Depo_Teminat
  , _top_masraflar.Pul_iase_28_kod_56                                               AS Pul_iase_28
  , _top_masraflar.Konteyner_Farki_kod_41                                           AS Konteyner_Farki
  , _top_masraflar.Tahmil_Tahliye_42_kod_42                                         AS Tahmil_Tahliye_42
  , _top_masraflar.Antrepo_Depo_kod_57                                              AS Antrepo_Depo
  , _top_masraflar.Belloti_kod_44                                                   AS Belloti
  , _top_masraflar.Ekp_kod_35                                                       AS Ekp
  , _top_masraflar.Zirai_karantina_kod_58                                           AS Zirai_karantina
  , _top_masraflar.Borsa_kod_59                                                     AS Borsa
  , _top_masraflar.Ufuk_Nakliye_kod_63                                              AS Ufuk_Nakliye
  , _top_masraflar.Tahmil_Tahliye_Ufuk_kod_61                                       AS Tahmil_Tahliye_Ufuk
  , _top_masraflar.ic_Nakliye_Ufuk_kod_62                                           AS ic_Nakliye_Ufuk
  , _top_masraflar.Damga_Pulu_Ufuk_kod_45                                           AS Damga_Pulu_Ufuk
  , _top_masraflar.Fotokopi_Ak_Kirt_kod_64                                          AS Fotokopi_Ak_Kirt
  , _top_masraflar.ic_Tasima65_kod_65                                               AS ic_Tasima65
  , _top_masraflar.Kusat_Masrafi_kod_1                                              AS Kusat_Masrafi
  , _top_masraflar.Hammaliye_kod_2                                                  AS Hammaliye
  , _top_masraflar.Taksi_Yol_kod_3                                                  AS Taksi_Yol
  , _top_masraflar.Esya_Tasimasi_kod_4                                              AS Esya_Tasimasi
  , _top_masraflar.Devam_Formu_kod_66                                               AS Devam_Formu
  , _top_masraflar.Hammaliye37_kod_67                                               AS Hammaliye37
  , _top_masraflar.TEV_kod_76                                                       AS TEV
  , _top_masraflar.Ordino_113_kod_113                                               AS Ordino_113
  , _top_masraflar.Ordino_Terminal_Hizmeti_kod_132                                  AS Ordino_Terminal_Hizmeti
  , _top_masraflar.Noter_120_kod_120                                                AS Noter_120
  , _top_masraflar.Kargo_ucreti_114_kod_114                                         AS Kargo_ucreti_114
  , _top_masraflar.ic_Tasima_70_kod_70                                              AS ic_Tasima_70
  , _top_masraflar.KDV_99_kod_99                                                    AS KDV_99
  , _top_masraflar.otv_kod_98                                                       AS otv
  , _top_masraflar.ic_tasima_77_kod_77                                              AS ic_tasima_77
  , _top_masraflar.Aylik_Mesai_kod_78                                               AS Aylik_Mesai
  , _top_masraflar.Konsolosluk_kod_48                                               AS Konsolosluk
  , _top_masraflar.KKDF_kod_49                                                      AS KKDF
  , _top_masraflar.Fon_kod_50                                                       AS Fon
  , _top_masraflar.Nakliye_88_kod_88                                                AS Nakliye_88
  , _top_masraflar.Dampinge_Karsi_Vergi_kod_54                                      AS Dampinge_Karsi_Vergi
  , _top_masraflar.Aktarma_Tem_Bedeli_kod_71                                        AS Aktarma_Tem_Bedeli
  , _top_masraflar.Kirtasiye_kod_72                                                 AS Kirtasiye
  , _top_masraflar.Etiketleme_kod_101                                               AS Etiketleme
  , _top_masraflar.Muayene_kod_102                                                  AS Muayene
  , _top_masraflar.Tam_Tespit_kod_1011                                              AS Tam_Tespit
  , _top_masraflar.Terminal_kod_103                                                 AS Terminal
  , _top_masraflar.Strec_ucreti_kod_1012                                            AS Strec_ucreti
  , _top_masraflar.Ellecleme_kod_105                                                AS Ellecleme
  , _top_masraflar.Beyanname_Bedeli_kod_106                                         AS Beyanname_Bedeli
  , _top_masraflar.Liman_ici_Akt_kod_107                                            AS Liman_ici_Akt
  , _top_masraflar.Giris_cikis_ucreti_kod_108                                       AS Giris_cikis_ucreti
  , _top_masraflar.Fuzuli_isgal_ucreti_kod_109                                      AS Fuzuli_isgal_ucreti
  , _top_masraflar.Dokumantasyon_ucreti_kod_1010                                    AS Dokumantasyon_ucreti
  , _top_masraflar.Forklift_ucreti_kod_1013                                         AS Forklift_ucreti
  , _top_masraflar.Kayit_Tescil_kod_104                                             AS Kayit_Tescil
  , _top_masraflar.Arac_Bekleme_kod_111                                             AS Arac_Bekleme
  , _top_masraflar.Ordino_Gecici_Kabul_kod_131                                      AS Ordino_Gecici_Kabul
  , _top_masraflar.Ordino_Guvenlik_kod_136                                          AS Ordino_Guvenlik
  , _top_masraflar.Ordino_Liman_Hizmet_kod_133                                      AS Ordino_Liman_Hizmet
  , _top_masraflar.Ordino_Ordino_kod_134                                            AS Ordino_Ordino
  , _top_masraflar.Ordino_Tahliye_kod_135                                           AS Ordino_Tahliye
  , _top_masraflar.memur_yollugu_kod_151                                            AS memur_yollugu
  , _top_masraflar.Sanayi_Odasi_kod_161                                             AS Sanayi_Odasi
  , _top_masraflar.Tarim_il_kod_162                                                 AS Tarim_il
  , _top_masraflar.PTT_kod_201                                                      AS PTT
  , _top_masraflar.ihracat_uyelik_Aidati_kod_211                                    AS ihracat_uyelik_Aidati
  , _top_masraflar.Dis_Ticaret_Belge_Harci_kod_212                                  AS Dis_Ticaret_Belge_Harci
  , _top_masraflar.Taahhut_Pulu_kod_401                                             AS Taahhut_Pulu
  , _top_masraflar.Degerli_Kagit_Bedeli_kod_402                                     AS Degerli_Kagit_Bedeli
  , _top_masraflar.Hizmet_Bedeli_kod_213                                            AS Hizmet_Bedeli
  , _top_masraflar.ozet_Beyan_kod_404                                               AS ozet_Beyan
  , _top_masraflar.Yanici_kod_164                                                   AS Yanici
  , _top_masraflar.EMY_kod_97                                                       AS EMY
  , _top_masraflar.Gumruk_Formalite_kod_1014                                        AS Gumruk_Formalite
  , _top_masraflar.Mesai_Ardiye_kod_1015                                            AS Mesai_Ardiye
  , _top_masraflar.Harc_Noter_kod_202                                               AS Harc_Noter
  , _top_masraflar.irad_kod_214                                                     AS irad
  , _top_masraflar.Tse_Ardiye_kod_1016                                              AS Tse_Ardiye
  , _top_masraflar.Maniplasyon_ucreti_kod_1017                                      AS Maniplasyon_ucreti
  , _top_masraflar.Palet_Kirasi_kod_1018                                            AS Palet_Kirasi
  , _top_masraflar.Posta_Havale_Masrafi_kod_203                                     AS Posta_Havale_Masrafi
  , _top_masraflar.Kapi_Giris_cikis_kod_137                                         AS Kapi_Giris_cikis
  , _top_masraflar.ISPS_Guvenlik_Bedeli_kod_138                                     AS ISPS_Guvenlik_Bedeli
  , _top_masraflar.Yurtdisi_ISPS_ucreti_kod_139                                     AS Yurtdisi_ISPS_ucreti
  , _top_masraflar.ihracatcilar_Birligi_60_kod_60                                   AS ihracatcilar_Birligi_60
  , _top_masraflar.ilan_kod_165                                                     AS ilan
  , _top_masraflar.Dts_kod_116                                                      AS Dts
  , _top_masraflar.motor_servisi_kod_180                                            AS motor_servisi
  , _top_masraflar.Antrepo_Ardiye_kod_1091                                          AS Antrepo_Ardiye
  , _top_masraflar.Yurtdisi_Ardiye_kod_1019                                         AS Yurtdisi_Ardiye
  , _top_masraflar.Yurtdisi_Nakliye_kod_112_alt                                     AS Yurtdisi_Nakliye -- Yurtdisi_Nakliye_112 ile aynı kod (112) için farklı alias
  , _top_masraflar.IGV_kod_91                                                       AS IGV
  , _top_masraflar.Kimyahane_kod_301                                                AS Kimyahane
  , _top_masraflar.XRAY_Masrafi_kod_1020                                            AS XRAY_Masrafi
  , _top_masraflar.Saha_Disi_Aktarma_kod_1021                                       AS Saha_Disi_Aktarma
  , _top_masraflar.ADV_V_Depo_kod_92                                                AS ADV_V_Depo
  , _top_masraflar.ADV_KDV_V_Depo_kod_93                                            AS ADV_KDV_V_Depo
  , _top_masraflar.TRT_bandrol_kod_85                                               AS TRT_bandrol
  , _top_masraflar.Radyasyon_olcumu_kon_kod_1022                                    AS Radyasyon_olcumu_kon
  , _top_masraflar.Nakit_Teminat_kod_100                                            AS Nakit_Teminat
  , _top_masraflar.Kismi_Muafiyet_kod_94                                            AS Kismi_Muafiyet
  , _top_masraflar.CKP_kod_86                                                       AS CKP
  , _top_masraflar.T_K_F_kod_87                                                     AS T_K_F
  , _top_masraflar.Tutun_Fonu_kod_89                                                AS Tutun_Fonu
  , _top_masraflar.Gecici_Zammi_kod_90                                              AS Gecici_Zammi
  , _top_masraflar.Dts_Analiz_kod_1160                                              AS Dts_Analiz
  , _top_masraflar.Konteyner_Tamir_Bedeli_kod_410                                   AS Konteyner_Tamir_Bedeli
  , _top_masraflar.Ticaret_Odasi_kod_166                                            AS Ticaret_Odasi
  , _top_masraflar.KDGV_kod_96                                                      AS KDGV
  , _top_masraflar.Liman_ucretleri_kod_1023                                         AS Liman_ucretleri
  , _top_masraflar.Dolasim_Belgesi_ucreti_kod_74                                    AS Dolasim_Belgesi_ucreti
  , _top_masraflar.Lashing_kod_79                                                   AS Lashing
  , _top_masraflar.Kur_Farki_kod_80                                                 AS Kur_Farki
-- FROM'dan sonraki joinlerin SIRALAMASI doğrudan PERFORMANSI ETKİLİYOR... O nedenle "gumbeyanmadde" tablosunu alt tarafa taşıdım 
-- çünkü o tablo, üstündekilerin detayı niteliğinde, o nedenle en son kullanılmalıydı. 10 master 100 detay yerine 100 detay sonra on master yapmak işi uzatır... UP
FROM          slz05.gumbeyanbaslik  as  a
INNER JOIN    _yetkili_firmalar_cte AS  yf  ON (a.firma       = yf.firma        OR  a.faturafirma   = yf.firma) --> get_firmalar fonksiyonunun yerine kullanılıyor.
INNER JOIN    slz05.gumbanka        as  b   ON b.kod          = a.bankakod
INNER JOIN    slz05.genkod          as  o   ON o.tip          = 310             AND o.kod           = a.bankaodsek
INNER JOIN    slz05.genkod          as  k   ON k.tip          = 314             AND k.kod           = a.gcgumidare
INNER JOIN    slz05.gumfirmakarsi   as  kf  ON kf.firma       = a.firma         AND kf.karsifirma   = a.karsifirma
-- INNER JOIN    slz05.gumbeyanmadde   as  m   ON m.beyid        = a.beyid    BU SATIR AŞAĞIYA TAŞINDI, BİLGİ OLSUN DİYE NOT OLARAK BU SATIRDA BIRAKTIM... ELLEME ! UP

LEFT JOIN LATERAL ( -- LATERAL JOIN 1: gumedibeyver için (sadece koşul sağlanırsa değer döner)
    SELECT COALESCE(SUM(gv.tutar), 0) AS tutar
    FROM slz05.gumedibeyver gv
    WHERE (EXISTS (SELECT 1 FROM slz05.gumedibaslik gb WHERE gb.evrcinsi = a.evrcinsi AND gb.evrseri = a.evrseri AND gb.evrno = a.evrno AND gb.status >= '8')
            OR
            EXISTS (SELECT 1 FROM slz05.gumBEYXMLBAS gx WHERE gx.evrcinsi = a.evrcinsi AND gx.evrseri = a.evrseri AND gx.evrno = a.evrno AND gx.durum >= '8')
           )
      AND gv.evrcinsi = a.evrcinsi
      AND gv.evrseri  = a.evrseri
      AND gv.evrno    = a.evrno
      AND gv.sirano   = 0
      AND gv.kod      = '99'
      AND gv.odesek   = 'T'::VARCHAR -- p_odemesekli='L' için
) AS _lat_edi_vergi ON TRUE

LEFT JOIN LATERAL ( -- LATERAL JOIN 2: gumbeyanvergi için (sadece ilk koşul sağlanmazsa değer döner)
    SELECT COALESCE(SUM(gv.tutar), 0) AS tutar
    FROM slz05.gumbeyanvergi gv
    WHERE NOT ( -- İlk koşulun tersi
            EXISTS (SELECT 1 FROM slz05.gumedibaslik gb WHERE gb.evrcinsi = a.evrcinsi AND gb.evrseri = a.evrseri AND gb.evrno = a.evrno AND gb.status >= '8')
            OR
            EXISTS (SELECT 1 FROM slz05.gumBEYXMLBAS gx WHERE gx.evrcinsi = a.evrcinsi AND gx.evrseri = a.evrseri AND gx.evrno = a.evrno AND gx.durum >= '8')
           )
      AND gv.evrcinsi   = a.evrcinsi
      AND gv.evrseri    = a.evrseri
      AND gv.evrno      = a.evrno
      AND gv.odemesekli = 'L'::VARCHAR -- p_odemesekli='L'
) AS _lat_beyan_vergi ON TRUE

LEFT JOIN LATERAL -- fn_gum_dosyadekdet fonksiyon çağrılarını (masrafkod 11 ve 18 için) birleştirir (FILTER ile)
( SELECT    COALESCE(SUM( CASE    -- masrafkod 11 (YI_nakliye) için iç hesaplama
                             WHEN mas.dekont = 'X' AND NOT (mas.depo = 'X' AND mas.depo_coztrh IS NOT NULL)
                             THEN CASE WHEN mas.dovizkod = 'TL' THEN ROUND(mas.tutar / 1000000.0, 2)      ELSE mas.tutar END
                             WHEN mas.depo = 'X' AND mas.depo_coztrh IS NOT NULL 
                             THEN CASE WHEN mas.dovizkod = 'TL' THEN ROUND(mas.depo_tutar / 1000000.0, 2) ELSE mas.depo_tutar END
                             ELSE 0
                          END
                        ) FILTER (WHERE mas.masrafkod = 11)
                    , 0.00)::NUMERIC                                                       AS YI_nakliye
          , COALESCE(SUM( CASE    -- masrafkod 18 (tse_masraf) için iç hesaplama
                             WHEN mas.dekont = 'X' AND NOT (mas.depo = 'X' AND mas.depo_coztrh IS NOT NULL)
                             THEN CASE WHEN mas.dovizkod = 'TL' THEN ROUND(mas.tutar / 1000000.0, 2) ELSE mas.tutar END
                             WHEN mas.depo = 'X' AND mas.depo_coztrh IS NOT NULL
                             THEN CASE WHEN mas.dovizkod = 'TL' THEN ROUND(mas.depo_tutar / 1000000.0, 2) ELSE mas.depo_tutar END
                             ELSE 0
                          END
                        ) FILTER (WHERE mas.masrafkod = 18)
                    , 0.00)::NUMERIC                                                       AS tse_masraf
  FROM      slz05.gumbeyanmasraf AS mas
  WHERE     mas.evrcinsi    = a.evrcinsi
    AND     mas.evrseri     = a.evrseri
    AND     mas.evrno       = a.evrno
    AND     mas.masrafkod   IN (11, 18) -- Sadece ilgili masraf kodlarını başta filtrele
) AS _gum_dosdekdet ON 1 = 1

LEFT JOIN LATERAL  -- fn_refevrtar ve fn_refevrno fonksiyonlarının (evrcinsi 290 ve 263 için) birleştirilmiş hali
(
    SELECT  COALESCE( MIN(CASE WHEN ff.evrcinsi = 290 THEN ff.Tarih END), DATE_TRUNC('day', CURRENT_TIMESTAMP)::TIMESTAMP(0) ) AS solmaz_kom_fat_tarihi
          , COALESCE( STRING_AGG( CASE WHEN ff.evrcinsi = 290 THEN CASE WHEN COALESCE(ff.documentnumber, '') = '' THEN TRIM(ff.evrseri) || ff.evrno::VARCHAR ELSE ff.documentnumber END END, ',' ORDER BY ff.Tarih ASC, ff.evrseri ASC, ff.evrno ASC ), ' ' ) AS solmaz_kom_fat_no
          , COALESCE( MIN(CASE WHEN ff.evrcinsi = 263 THEN ff.Tarih END), DATE_TRUNC('day', CURRENT_TIMESTAMP)::TIMESTAMP(0) ) AS dekont_tarihi
          , COALESCE( STRING_AGG( CASE WHEN ff.evrcinsi = 263 THEN CASE WHEN COALESCE(ff.documentnumber, '') = '' THEN TRIM(ff.evrseri) || ff.evrno::VARCHAR ELSE ff.documentnumber END END, ',' ORDER BY ff.Tarih ASC, ff.evrseri ASC, ff.evrno ASC ), ' ' ) AS dekont_no
    FROM    slz05.finfisbaslik ff
    WHERE   ff.ref_evrcinsi = a.evrcinsi
      AND   ff.ref_evrseri = a.evrseri
      AND   ff.ref_evrno = a.evrno
      AND   ff.evrcinsi IN (290, 263)
      AND   ff.onay = 'X'
      AND   TRIM(ff.karttip) = 'AC'
      AND   SUBSTRING(ff.kartno FROM 1 FOR 17) = SUBSTRING(a.firma FROM 1 FOR 17)
) _finfisbas ON 1 = 1

LEFT JOIN LATERAL -- fn_toprefevrdettl (290/10, 290/20) ve fn_toprefevrtl (263) fonksiyonlarının birleştirilmiş hali... fn_fismadde_yasal fonksiyonunu da buna yedirmek daha karmaşık hale gelmesine sebep olurdu, bu kadarı yeter, ben de insanım... UP
( SELECT    -- fn_toprefevrdettl(290, ..., 10) -> p_kod='KOM'
            COALESCE(SUM(CASE WHEN fm.evrcinsi = 290 AND (( (fm.sirano = 10 AND COALESCE(fm.kod, '') = '') OR fm.kod = 'KOM' ) AND (10 IN (10, 20)))
                              THEN slz05.fn_fismadde_yasal('A'::VARCHAR, fm.b_tutar, fm.a_tutar, fm.kdvtutar, fm.yasaltutar)
                              ELSE 0 END
                        ), 0) AS solmaz_kom_fat_kalem_bazinda_kdvsiz_dosya_adi
      
            -- fn_toprefevrdettl(290, ..., 20) -> p_kod='MAS'
          , COALESCE(SUM(CASE WHEN fm.evrcinsi = 290 AND (( (fm.sirano = 20 AND COALESCE(fm.kod, '') = '') OR fm.kod = 'MAS' ) OR ( fm.sirano > 20 AND COALESCE(fm.kod, '') = '' AND 20 = 20 )) AND (20 IN (10, 20))
                              THEN slz05.fn_fismadde_yasal('A'::VARCHAR, fm.b_tutar, fm.a_tutar, fm.kdvtutar, fm.yasaltutar)
                              ELSE 0 END
                        ), 0) AS fatura_masraf_tl
      
            -- fn_toprefevrtl(263, ...)
          , COALESCE(SUM(CASE WHEN fm.evrcinsi = 263 -- p_sirano filtresi yok, tüm sıralar toplanır
                              THEN slz05.fn_fismadde_yasal('A'::VARCHAR, fm.b_tutar, fm.a_tutar, fm.kdvtutar, fm.yasaltutar)
                              ELSE 0 END
                        ), 0) AS dekont_tl
  FROM      slz05.finfismadde AS fm
  WHERE     fm.ref_evrcinsi = a.evrcinsi
    AND     fm.ref_evrseri  = a.evrseri
    AND     fm.ref_evrno    = a.evrno
    AND     fm.status       = 'X'
    AND     fm.evrcinsi     IN (290, 263) -- Sadece ilgili evrak cinslerini başta filtrele
--) AS _finfismad ON 1 = 1  -- veya ON (a.evrcinsi != 0 AND a.evrno != 0)
) AS _finfismad ON (a.evrcinsi <> 0 AND a.evrno <> 0) -- Fonksiyonlardaki IF (p_refcinsi = 0 OR p_refno = 0) THEN RETURN 0; koşulu için:

LEFT JOIN LATERAL -- Beyan statüsü için
( SELECT    s.statu
  FROM      slz05.gumbeyanbilge AS s
  WHERE     s.evrcinsi          = a.evrcinsi
    AND     s.evrseri           = a.evrseri
    AND     s.evrno             = a.evrno
    AND     s.beyannameno       = a.tescilno
  LIMIT 1
) AS _statu ON 1 = 1

LEFT JOIN LATERAL -- Taşıt bilgisi için
( SELECT    MAX(k.tasit) AS max_tasit
  FROM      slz05.gumbeyanarac AS k
  WHERE     k.evrcinsi          = a.evrcinsi
    AND     k.evrseri           = a.evrseri
    AND     k.evrno             = a.evrno
) AS _arac ON 1 = 1

LEFT JOIN LATERAL -- Özet beyan ve konşimento tarihi için
( SELECT    MAX(x.ozetbeyanno)  AS max_ozetbeyanno
          , MAX(x.tarih)        AS max_tarih
  FROM      slz05.gumbeykonsbas AS x
  WHERE     x.evrcinsi          = a.evrcinsi
    AND     x.evrseri           = a.evrseri
    AND     x.evrno             = a.evrno
) AS _kons ON 1 = 1

LEFT JOIN LATERAL -- Ardiye ve Ordino masrafları için (dekont='X' olanlar)
( SELECT      SUM(CASE WHEN gm.dekaciklama LIKE 'Ardiye%' THEN mas.masraftutar ELSE 0 END)::NUMERIC AS ardiye_tutari
            , SUM(CASE WHEN gm.dekaciklama LIKE 'Ordin%'  THEN mas.masraftutar ELSE 0 END)::NUMERIC AS ordino_tutari
  FROM        slz05.gumbeyanmasraf  AS mas
  INNER JOIN  slz05.gummasraf       AS gm   ON    mas.masrafkod = gm.masrafkod
                                           AND    gm.dekont = 'X'
                                           AND  ( gm.dekaciklama LIKE 'Ardiye%'   --> Kümül Performans için eklendi
                                              OR  gm.dekaciklama LIKE 'Ordin%'    --> Kümül Performans için eklendi
                                                )
  WHERE       mas.evrcinsi        = a.evrcinsi
    AND       mas.evrseri         = a.evrseri
    AND       mas.evrno           = a.evrno
    AND       mas.dekont          = 'X'
    AND  ( gm.dekaciklama LIKE 'Ardiye%'   --> Kümül Performans için eklendi
       OR  gm.dekaciklama LIKE 'Ordin%'    --> Kümül Performans için eklendi
         )
) AS _masraf_dekontlu ON 1 = 1

LEFT JOIN LATERAL  --  slz05.fn_gum_beyanfat ve slz05.gum_beyanfatno'nun optimize hali.
( SELECT  SUBSTRING( STRING_AGG( TRIM(COALESCE(gfbo.fatevrno, '')) || '(' || COALESCE(gfbo.tutar, 0)::VARCHAR || ')', '/' ORDER BY gfbo.fatevrno ) FROM 1 FOR 220) AS fatura_bilgi
        , SUBSTRING( STRING_AGG( TRIM(COALESCE(gfbo.fatevrno, ''))                                                  , '/' ORDER BY gfbo.fatevrno ) FROM 1 FOR 220) AS fatura_no
  FROM 
        ( SELECT  x.fatevrno
                , x.tutar
                , SUM(LENGTH(TRIM(COALESCE(x.fatevrno, '')) || '(' || COALESCE(x.tutar, 0)::VARCHAR || ')') + 1) OVER (ORDER BY x.fatevrno ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS uzunluk  -- '/' için +1 
          FROM    slz05.gumbeyanfatbas AS x
          WHERE   x.evrcinsi = a.evrcinsi
            AND   x.evrseri  = a.evrseri
            AND   x.evrno    = a.evrno
        ) as gfbo
  WHERE gfbo.uzunluk - LENGTH(TRIM(COALESCE(gfbo.fatevrno, '')) || '(' || COALESCE(gfbo.tutar, 0)::VARCHAR || ')') <= 220 -- Bir sonraki elemanı eklemeden önce kontrol
) AS _gum_beyanfat ON 1 = 1

LEFT JOIN LATERAL -- fn_toprefmasrafdet fonksiyonunun yaptığı işi yapan optimize edilmiş masraf toplama
( SELECT
      -- UYARI: Aşağıdaki her bir satır, orijinal sorgudaki fn_toprefmasrafdet çağrısına karşılık gelir.
      -- Hesaplama mantığı: COALESCE(SUM( (CASE WHEN (depo<>'X' OR depo_coztrh IS NULL) THEN COALESCE(masraftutar,0)+COALESCE(ekmaliyet,0) ELSE 0 END) + (CASE WHEN (depo='X' AND depo_coztrh IS NOT NULL) THEN COALESCE(depo_tutar,0) ELSE 0 END) ) FILTER (WHERE masrafkod = KOD), 0)
      COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 15), 0)::NUMERIC   AS mesai_kod_15
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 5), 0)::NUMERIC    AS ic_bosaltma_kod_5
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 6), 0)::NUMERIC    AS Faiz_6_kod_6
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 7), 0)::NUMERIC    AS Tahmil_Tahliye_kod_7
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 9), 0)::NUMERIC    AS Gumruk_Vergisi_kod_9
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 110), 0)::NUMERIC AS Ardiye_ucreti_110_kod_110
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 112), 0)::NUMERIC AS Yurtdisi_Nakliye_112_kod_112
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 12), 0)::NUMERIC  AS Yurtdisi_Navlun_kod_12
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 13), 0)::NUMERIC  AS Ordino_13_kod_13
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 14), 0)::NUMERIC  AS Kargo_ucreti_kod_14
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 15), 0)::NUMERIC  AS Mesai_15_kod_15 -- Bu zaten mesai_kod_15 ile aynı sonucu verecek
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 16), 0)::NUMERIC  AS HARC_kod_16
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 17), 0)::NUMERIC  AS Sigorta_17_kod_17
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 18), 0)::NUMERIC  AS TSE_kod_18
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 19), 0)::NUMERIC  AS Fotokopi_kod_19
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 20), 0)::NUMERIC  AS Noter_kod_20
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 21), 0)::NUMERIC  AS ihracatcilar_Birligi_kod_21
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 24), 0)::NUMERIC  AS Tarti_ucreti_kod_24
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 25), 0)::NUMERIC  AS Gelir_Eksigi_kod_25
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 26), 0)::NUMERIC  AS Gozetim_Raporu_kod_26
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 28), 0)::NUMERIC  AS demuraj_kod_28
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 29), 0)::NUMERIC  AS Serbest_Bolge_kod_29
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 30), 0)::NUMERIC  AS analiz_kod_30
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 31), 0)::NUMERIC  AS Ceza_kod_31
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 32), 0)::NUMERIC  AS Tercume_kod_32
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 33), 0)::NUMERIC  AS Havale_Masrafi_kod_33
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 34), 0)::NUMERIC  AS Konsimento_kod_34
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 38), 0)::NUMERIC  AS isgum_kod_38
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 39), 0)::NUMERIC  AS Yemek_Bedeli_kod_39
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 40), 0)::NUMERIC  AS damga_vergisi_kod_40
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 23), 0)::NUMERIC  AS Ordino_Depozitosu_kod_23
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 53), 0)::NUMERIC  AS olcu_Ayar_kod_53
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 999), 0)::NUMERIC AS Tahmil_Tahliye_Gecici_kod_999
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 22), 0)::NUMERIC  AS Gumruk_Depo_Teminat_kod_22
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 56), 0)::NUMERIC  AS Pul_iase_28_kod_56
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 41), 0)::NUMERIC  AS Konteyner_Farki_kod_41
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 42), 0)::NUMERIC  AS Tahmil_Tahliye_42_kod_42
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 57), 0)::NUMERIC  AS Antrepo_Depo_kod_57
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 44), 0)::NUMERIC  AS Belloti_kod_44
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 35), 0)::NUMERIC  AS Ekp_kod_35
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 58), 0)::NUMERIC  AS Zirai_karantina_kod_58
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 59), 0)::NUMERIC  AS Borsa_kod_59
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 63), 0)::NUMERIC  AS Ufuk_Nakliye_kod_63
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 61), 0)::NUMERIC  AS Tahmil_Tahliye_Ufuk_kod_61
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 62), 0)::NUMERIC  AS ic_Nakliye_Ufuk_kod_62
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 45), 0)::NUMERIC  AS Damga_Pulu_Ufuk_kod_45
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 64), 0)::NUMERIC  AS Fotokopi_Ak_Kirt_kod_64
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 65), 0)::NUMERIC  AS ic_Tasima65_kod_65
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1), 0)::NUMERIC    AS Kusat_Masrafi_kod_1
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 2), 0)::NUMERIC    AS Hammaliye_kod_2
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 3), 0)::NUMERIC    AS Taksi_Yol_kod_3
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 4), 0)::NUMERIC    AS Esya_Tasimasi_kod_4
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 66), 0)::NUMERIC  AS Devam_Formu_kod_66
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 67), 0)::NUMERIC  AS Hammaliye37_kod_67
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 76), 0)::NUMERIC  AS TEV_kod_76
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 113), 0)::NUMERIC AS Ordino_113_kod_113
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 132), 0)::NUMERIC AS Ordino_Terminal_Hizmeti_kod_132
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 120), 0)::NUMERIC AS Noter_120_kod_120
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 114), 0)::NUMERIC AS Kargo_ucreti_114_kod_114
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 70), 0)::NUMERIC  AS ic_Tasima_70_kod_70
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 99), 0)::NUMERIC  AS KDV_99_kod_99
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 98), 0)::NUMERIC  AS otv_kod_98
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 77), 0)::NUMERIC  AS ic_tasima_77_kod_77
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 78), 0)::NUMERIC  AS Aylik_Mesai_kod_78
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 48), 0)::NUMERIC  AS Konsolosluk_kod_48
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 49), 0)::NUMERIC  AS KKDF_kod_49
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 50), 0)::NUMERIC  AS Fon_kod_50
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 88), 0)::NUMERIC  AS Nakliye_88_kod_88
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 54), 0)::NUMERIC  AS Dampinge_Karsi_Vergi_kod_54
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 71), 0)::NUMERIC  AS Aktarma_Tem_Bedeli_kod_71
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 72), 0)::NUMERIC  AS Kirtasiye_kod_72
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 101), 0)::NUMERIC AS Etiketleme_kod_101
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 102), 0)::NUMERIC AS Muayene_kod_102
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1011), 0)::NUMERIC AS Tam_Tespit_kod_1011
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 103), 0)::NUMERIC AS Terminal_kod_103
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1012), 0)::NUMERIC AS Strec_ucreti_kod_1012
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 105), 0)::NUMERIC AS Ellecleme_kod_105
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 106), 0)::NUMERIC AS Beyanname_Bedeli_kod_106
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 107), 0)::NUMERIC AS Liman_ici_Akt_kod_107
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 108), 0)::NUMERIC AS Giris_cikis_ucreti_kod_108
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 109), 0)::NUMERIC AS Fuzuli_isgal_ucreti_kod_109
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1010), 0)::NUMERIC AS Dokumantasyon_ucreti_kod_1010
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1013), 0)::NUMERIC AS Forklift_ucreti_kod_1013
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 104), 0)::NUMERIC AS Kayit_Tescil_kod_104
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 111), 0)::NUMERIC AS Arac_Bekleme_kod_111
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 131), 0)::NUMERIC AS Ordino_Gecici_Kabul_kod_131
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 136), 0)::NUMERIC AS Ordino_Guvenlik_kod_136
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 133), 0)::NUMERIC AS Ordino_Liman_Hizmet_kod_133
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 134), 0)::NUMERIC AS Ordino_Ordino_kod_134
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 135), 0)::NUMERIC AS Ordino_Tahliye_kod_135
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 151), 0)::NUMERIC AS memur_yollugu_kod_151
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 161), 0)::NUMERIC AS Sanayi_Odasi_kod_161
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 162), 0)::NUMERIC AS Tarim_il_kod_162
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 201), 0)::NUMERIC AS PTT_kod_201
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 211), 0)::NUMERIC AS ihracat_uyelik_Aidati_kod_211
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 212), 0)::NUMERIC AS Dis_Ticaret_Belge_Harci_kod_212
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 401), 0)::NUMERIC AS Taahhut_Pulu_kod_401
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 402), 0)::NUMERIC AS Degerli_Kagit_Bedeli_kod_402
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 213), 0)::NUMERIC AS Hizmet_Bedeli_kod_213
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 404), 0)::NUMERIC AS ozet_Beyan_kod_404
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 164), 0)::NUMERIC AS Yanici_kod_164
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 97), 0)::NUMERIC  AS EMY_kod_97
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1014), 0)::NUMERIC AS Gumruk_Formalite_kod_1014
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1015), 0)::NUMERIC AS Mesai_Ardiye_kod_1015
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 202), 0)::NUMERIC AS Harc_Noter_kod_202
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 214), 0)::NUMERIC AS irad_kod_214
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1016), 0)::NUMERIC AS Tse_Ardiye_kod_1016
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1017), 0)::NUMERIC AS Maniplasyon_ucreti_kod_1017
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1018), 0)::NUMERIC AS Palet_Kirasi_kod_1018
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 203), 0)::NUMERIC AS Posta_Havale_Masrafi_kod_203
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 137), 0)::NUMERIC AS Kapi_Giris_cikis_kod_137
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 138), 0)::NUMERIC AS ISPS_Guvenlik_Bedeli_kod_138
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 139), 0)::NUMERIC AS Yurtdisi_ISPS_ucreti_kod_139
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 60), 0)::NUMERIC  AS ihracatcilar_Birligi_60_kod_60
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 165), 0)::NUMERIC AS ilan_kod_165
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 116), 0)::NUMERIC AS Dts_kod_116
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 180), 0)::NUMERIC AS motor_servisi_kod_180
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1091), 0)::NUMERIC AS Antrepo_Ardiye_kod_1091
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1019), 0)::NUMERIC AS Yurtdisi_Ardiye_kod_1019
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 112), 0)::NUMERIC AS Yurtdisi_Nakliye_kod_112_alt -- Yurtdisi_Nakliye_112_kod_112 ile aynı sonucu verecek
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 91), 0)::NUMERIC  AS IGV_kod_91
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 301), 0)::NUMERIC AS Kimyahane_kod_301
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1020), 0)::NUMERIC AS XRAY_Masrafi_kod_1020
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1021), 0)::NUMERIC AS Saha_Disi_Aktarma_kod_1021
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 92), 0)::NUMERIC  AS ADV_V_Depo_kod_92
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 93), 0)::NUMERIC  AS ADV_KDV_V_Depo_kod_93
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 85), 0)::NUMERIC  AS TRT_bandrol_kod_85
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1022), 0)::NUMERIC AS Radyasyon_olcumu_kon_kod_1022
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 100), 0)::NUMERIC AS Nakit_Teminat_kod_100
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 94), 0)::NUMERIC  AS Kismi_Muafiyet_kod_94
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 86), 0)::NUMERIC  AS CKP_kod_86
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 87), 0)::NUMERIC  AS T_K_F_kod_87
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 89), 0)::NUMERIC  AS Tutun_Fonu_kod_89
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 90), 0)::NUMERIC  AS Gecici_Zammi_kod_90
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1160), 0)::NUMERIC AS Dts_Analiz_kod_1160
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 410), 0)::NUMERIC AS Konteyner_Tamir_Bedeli_kod_410
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 166), 0)::NUMERIC AS Ticaret_Odasi_kod_166
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 96), 0)::NUMERIC  AS KDGV_kod_96
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 1023), 0)::NUMERIC AS Liman_ucretleri_kod_1023
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 74), 0)::NUMERIC  AS Dolasim_Belgesi_ucreti_kod_74
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 79), 0)::NUMERIC  AS Lashing_kod_79
    , COALESCE(SUM( (CASE WHEN (sbm.depo <> 'X' OR sbm.depo_coztrh IS NULL) THEN COALESCE(sbm.masraftutar,0) + COALESCE(sbm.ekmaliyet,0) ELSE 0 END) + (CASE WHEN (sbm.depo = 'X' AND sbm.depo_coztrh IS NOT NULL) THEN COALESCE(sbm.depo_tutar,0) ELSE 0 END) ) FILTER (WHERE sbm.masrafkod = 80), 0)::NUMERIC  AS Kur_Farki_kod_80
  FROM      slz05.gumbeyanmasraf AS sbm
  WHERE     sbm.evrcinsi        = a.evrcinsi
    AND     sbm.evrseri         = a.evrseri
    AND     sbm.evrno           = a.evrno
    AND     sbm.masrafkod IN  ( 15, 5, 6, 7, 9, 110, 112, 12, 13, 14, 16, 17, 18, 19, 20, 21, 24, 25, 26, 28, 29, 30
                              , 31, 32, 33, 34, 38, 39, 40, 23, 53, 999, 22, 56, 41, 42, 57, 44, 35, 58, 59, 63, 61
                              , 62, 45, 64, 65, 1, 2, 3, 4, 66, 67, 76, 113, 132, 120, 114, 70, 99, 98, 77, 78, 48
                              , 49, 50, 88, 54, 71, 72, 101, 102, 1011, 103, 1012, 105, 106, 107, 108, 109, 1010
                              , 1013, 104, 111, 131, 136, 133, 134, 135, 151, 161, 162, 201, 211, 212, 401, 402
                              , 213, 404, 164, 97, 1014, 1015, 202, 214, 1016, 1017, 1018, 203, 137, 138, 139, 60
                              , 165, 116, 180, 1091, 1019, 91, 301, 1020, 1021, 92, 93, 85, 1022, 100, 94, 86, 87
                              , 89, 90, 1160, 410, 166, 96, 1023, 74, 79, 80
                              ) -- Optimize etmek için ilgili tüm masraf kodları
) AS _top_masraflar ON 1 = 1

INNER JOIN    slz05.gumbeyanmadde   as  m   ON m.beyid        = a.beyid
LEFT JOIN LATERAL -- Tüm ülke adlarını tek bir optimize edilmiş LATERAL JOIN ile almak için (UNNEST ve PIVOT kullanarak)
( SELECT        MAX(CASE WHEN uk.kod_tipi = 'ticari' THEN gu.adi ELSE NULL END) AS ticari_ulke         -- Ticari ülke adı (a.ticulke ile eşleşir)   --  , fn_getulkeadi(a.ticulke)    AS ticari_ulke
              , MAX(CASE WHEN uk.kod_tipi = 'sevk'   THEN gu.adi ELSE NULL END) AS sevk_ulke           -- Sevk ülke adı (a.sevkulke ile eşleşir)    --  , fn_getulkeadi(a.sevkulke)   AS sevk_ulke
              , MAX(CASE WHEN uk.kod_tipi = 'mense'  THEN gu.adi ELSE NULL END) AS mense               -- Menşe ülke adı (m.menseulke ile eşleşir)  --  , fn_getulkeadi(m.menseulke)  AS mense
              , MAX(CASE WHEN uk.kod_tipi = 'gid'    THEN gu.adi ELSE NULL END) AS gidecegi_ulke       -- Gideceği ülke adı (a.gidulke ile eşleşir) --  , fn_getulkeadi(a.gidulke)    AS gidecegi_ulke
  FROM  UNNEST( ARRAY[a.ticulke,   a.sevkulke,  m.menseulke, a.gidulke]     -- Eşleştirilecek ülke kodları
              , ARRAY['ticari',  'sevk',      'mense',     'gid']::VARCHAR[] -- Her koda karşılık gelen tip (VARCHAR dizisi olarak cast edildi)
              ) AS uk(kod, kod_tipi) -- UNNEST sonucu: kod (ilgili ülke kodu), kod_tipi (ülkenin türü)
  LEFT JOIN     genel.genulke AS gu ON gu.ulkekod = uk.kod -- Her bir (kod, kod_tipi) çifti için ülke adını al
) AS _ulkeler ON 1 = 1

LEFT JOIN LATERAL -- Stok numaraları için
( SELECT    TRIM(STRING_AGG(DISTINCT gfg.stokno::VARCHAR, '')) AS stok_no_agg
  FROM      slz05.gumbeyanfatmad AS s
  JOIN      slz05.gumfirmagtip   AS gfg ON gfg.firma = a.firma AND gfg.itemid = s.itemid --> TRIM(STRING_AGG(DISTINCT fn_gum_getstokno(a.firma, s.itemid)::VARCHAR, '')) AS stok_no_agg
  WHERE     s.evrcinsi      = m.evrcinsi
    AND     s.evrseri       = m.evrseri
    AND     s.evrno         = m.evrno
    AND     s.beyan_sirano  = m.sirano
) AS _stok ON 1 = 1

LEFT JOIN LATERAL -- KDV Matraı ve -->, gum_getedibeyver(a.evrcinsi ,a.evrseri,a.evrno,m.sirano,'40') AS kdv fonksiyonu için...
( SELECT    SUM(x.tutar)          AS kdv
          , SUM(x.vergi_matrahi)  AS matrah
  FROM      slz05.gumedibeyver    AS x
  WHERE     x.evrno             = a.evrno
    AND     x.evrseri           = a.evrseri
    AND     x.evrcinsi          = a.evrcinsi
    AND     x.sirano            = m.sirano
    AND     x.kod::VARCHAR      = '40'::VARCHAR -- Orijinal fonksiyondaki LIKE mantığı pKOD='-40-' ise buna denk gelir. Verileri incedim, yazarken hepsini trimlemişiz... UP
) AS _kdv ON 1 = 1

WHERE ( 1 = 1 )
--AND ( a.tesciltarih BETWEEN $tarih1 AND $tarih2 ) -- bu kısım şimdilik kalsın, belki ileride bu haliyle tekrar kullanırız. UP
  AND ( '$tarih1'       is NOT null AND a.tesciltarih >= '$tarih1'      ) --> Bu parametreyi zorunlu hale getirdik. UP
  AND ( '$tarih2'       is NOT null AND a.tesciltarih <= '$tarih2'      ) --> Bu parametreyi zorunlu hale getirdik. UP
  AND ( $solmazrefno  is null     or  a.evrno       = $solmazrefno  ) --> Opsiyonel parametre. UP
  AND ( $tescilno     is null     or  a.tescilno    = $tescilno     ) --> Opsiyonel parametre. UP
  AND ( $refnofirma   is null     or  a.referans LIKE '%' || cast( $refnofirma AS VARCHAR) || '%' )  --> Opsiyonel parametre, eğer null ise koşul ekleme demek... UP
;


/*
====================================================================================================
 OPTİMİZASYON ÖZETİ
====================================================================================================

Mevcut rapor/sorgu performansını iyileştirmek, potansiyel darboğazları gidermek ve 
fonksiyon çağrılarından kaynaklanan maliyetleri azaltmak. Özellikle geniş tarih 
aralıklarında (örn: 1 yıl) kabul edilebilir yanıt sürelerine ulaşmak.

BAŞLANGIÇ DURUMU:
-----------------
* Sorgu, SELECT listesinde ve bazı JOIN koşullarında çok sayıda Kullanıcı Tanımlı Fonksiyon (UDF) içeriyordu.
* Geniş tarih aralıklarında yapılan ilk stres testlerinde sorgu yanıt süresi ~16 saniye civarındaydı. Bazı durumlarda dakikalarca...
* Sorgu planında çok sayıda iç içe döngü (Nested Loop) ve bazı tablolara verimsiz erişimler gözlemleniyordu.

YAPILAN TEMEL OPTİMİZASYON ADIMLARI VE ELDE EDİLEN SONUÇLAR:
-----------------------------------------------------------

1.  FONKSİYONLARIN LATERAL JOIN'LERE DÖNÜŞTÜRÜLMESİ:
    *   SELECT listesinde çağrılan ve her satır için tekrar tekrar çalışan maliyetli UDF'ler 
        (örn: fn_refevrtar, fn_refevrno, fn_toprefevrdettl, fn_toprefevrtl, fn_gum_dosyadekdet, fn_gum_beyvergi, gum_beyanfatno, fn_gum_beyanfat, fn_gum_getstokno, gum_getedibeyver) tespit edildi.
    *   Bu UDF'lerin içerdikleri SQL mantıkları, ana sorguya LEFT JOIN LATERAL blokları olarak entegre edildi. Bu sayede, fonksiyon çağrı overhead'i ortadan kaldırıldı ve PostgreSQL sorgu planlayıcısının bu işlemleri daha bütüncül optimize etmesi sağlandı.
    *   Özellikle birden fazla kez çağrılan veya aynı tabloya erişen fonksiyonların mantıkları, tek bir LATERAL JOIN içinde koşullu agregasyonlarla birleştirilerek tablo erişim sayısı azaltıldı.
        (Örnek: _finfisbas, _finfismad, _gum_dosdekdet, _lat_edi_vergi/_lat_beyan_vergi LATERAL'leri)

2.  ANA FİLTRELEME VE JOIN STRATEJİSİNİN İYİLEŞTİRİLMESİ:
    *   Sorgunun en başında, ana parametreye ($firma) bağlı olarak yetkili firmaların listesini  belirlemek için bir CTE (_yetkili_firmalar_cte) kullanıldı.
    *   Ana tablo olan `gumbeyanbaslik` (a), bu CTE ile ve tarih aralığıyla en başta filtrelenerek işlenecek ana satır sayısı önemli ölçüde azaltıldı.
    *   `gumbeyanbaslik` tablosunda `firma` ve `faturafirma` sütunları üzerinden yapılan `OR` koşullu firma filtrelemesi için `BitmapOr` ve ilgili kompozit indekslerin 
        (örn: idx_gumbeyanbaslik_firma_tesciltarih, idx_gumbeyanbaslik_faturafirma_tesciltarih) kullanımı sağlandı.

3.  KAPSAYICI İNDEKSLER (COVERING INDEXES) VE HEAP FETCH OPTİMİZASYONU:
    *   `slz05.gumbeyanmasraf` tablosuna sıkça erişen `_top_masraflar` ve `_masraf_dekontlu` LATERAL JOIN'leri için, ihtiyaç duyulan tüm sütunları içeren kapsayıcı indeksler 
        (idx_gumbeyanmasraf_covering_topmasraflar, idx_gumbeyanmasraf_covering_masrafdekontlu) oluşturuldu.
    *   Bu sayede, bu LATERAL JOIN'ler için tabloya yapılan gereksiz erişimler (Heap Fetches) tamamen ortadan kaldırıldı, bu da I/O ve CPU maliyetini düşürdü.

4.  LATERAL JOIN SIRALAMASININ OPTİMİZASYONU:
    *   Sadece ana tabloya (`gumbeyanbaslik a`) bağlı olan LATERAL JOIN'ler, `gumbeyanmadde m` tablosuyla yapılan `INNER JOIN`'den önceye alındı.
    *   Bu değişiklik, bu LATERAL JOIN'lerin daha az sayıda (ana tablodan gelen filtrelenmiş satır sayısı kadar) çalışmasını sağlayarak toplam sorgu süresini önemli ölçüde azalttı.

5.  DİĞER KÜÇÜK İYİLEŞTİRMELER:
    *   Gereksiz `TRIM` fonksiyonları (eğer veri zaten temizse) sorgudan kaldırıldı veya indeks kullanımını engellemeyecek şekilde düzenlendi (örn: `gumedibeyver.kod = '40'`).
    *   Veri tipleri ve fonksiyon imzaları kontrol edildi.

SONUÇ PERFORMANS:
-----------------
*   Yapılan optimizasyonlar sonucunda, 1 yıllık tarih aralığı için sorgu yanıt süresi 
    ~16 saniyelerden **~2.9 saniye** seviyesine düşürülmüştür. Bu, %80'in üzerindebir performans artışına tekabül etmektedir.
*   `gumbeyanmasraf` tablosu için Heap Fetch'ler sıfırlanmıştır.
*   LATERAL JOIN'lerin çalışma sayıları optimize edilmiştir.
*   Bu testler ve çalışmalar şirket merkezinde yer alan bilgisayar üzerinden gerçekleştirilmiştir. 
    Bu nedenle performans ölçümünde ağ maliyeti minimum düzeyde gözükmektedir.
    Raporu çalıştıran istemcinin şirket ağ kaynaklarına olan uzaklığı (Şirket dışı veya şehir dışında olması durumunda) daha uzun sürelere tekabül edecektir.


POTANSİYEL GELECEK İYİLEŞTİRMELER (Mevcut Performans Yeterli Görülürse Ertelenebilir):
------------------------------------------------------------------------------------
*   `gumbeyanbaslik` tablosu için `Bitmap Heap Scan` ile okunan blok sayısını (`Heap Blocks`) azaltmak amacıyla, `SELECT` listesinde ve diğer JOIN'lerde kullanılan `a.` sütunlarını  içeren daha kapsamlı "covering index"ler oluşturulabilir.
*   `_lat_edi_vergi` ve `_lat_beyan_vergi` LATERAL JOIN'leri içindeki `EXISTS` sorgularının kullandığı `gumedibaslik` ve `gumBEYXMLBAS` tablolarındaki `Heap Fetches` sayısı, daha agresif `VACUUM` stratejileri veya tablo yeniden yapılandırması ile azaltılabilir.
*   `_yetkili_firmalar_cte`'nin başlangıç çalışma süresi, içindeki JOIN'ler ve indeksler daha detaylı incelenerek bir miktar daha iyileştirilebilir.

MEVCUT DURUM:
-------------
Mevcut ~2.9 saniyelik performans, stres testi koşulları (1 yıllık veri) göz önüne alındığında 
önemli bir başarıdır. Daha fazla optimizasyonun getireceği marjinal kazanç, artan sorgu/indeks 
karmaşıklığı ve potansiyel yazma performansı etkileri dikkate alınarak, bu aşamada optimizasyon 
sürecinin sonlandırılması makul bir karardır. Sorgu, önemli ölçüde hızlandırılmış ve 
darboğazların birçoğu giderilmiştir.

====================================================================================================
*/