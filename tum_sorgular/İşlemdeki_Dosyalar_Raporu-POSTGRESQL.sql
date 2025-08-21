--EXPLAIN (ANALYZE, BUFFERS)
SELECT        b.evrno                                                                 AS solmazrefno
            , b.referans
            , _fatbas.faturano                                                        AS faturano
            , b.beyan1
            , b.tescilno
            , TO_CHAR(b.trhtescil, 'YYYY-MM-DD')                                      AS tescil_tarihi
            , TO_CHAR(b.trhtescil, 'HH24:MI')                                         AS tescil_saati
            , b.dosyaturu                                                             AS dosya_turu
            , _statu.statu                                                            AS statu
            , CASE b.arc_id WHEN 0 THEN 'HAYIR' ELSE 'EVET' END                       AS arsivlenmis
            , CASE COALESCE(b.kod1, '') WHEN 'ECZSEL' THEN _genkod.dosya_ref_aciklama ELSE NULL END AS dosya
            , kf.unvan                                                                AS satici           -- UYARI: fn_gum_getfirmakarsiunvan çağrısı LEFT JOIN ile değiştirildi.
            , _genkod.gumruk_aciklama                                                 AS gumruk
            , _ozet.ozet_beyan_no                                                     AS ozet_beyan_no
            , b.kapsayi
            , b.topnetag
            , b.topbrutag
            , b.tutar
            , CASE b.dovizkod WHEN 'YTL' THEN 'TL' ELSE b.dovizkod END                AS dovizkod
            , _genkod.banka_aciklama                                                  AS banka
            , b.nakliyeci
            , CASE COALESCE(b.arakons_no, '')
                WHEN '' THEN _tasima.tasimasenet
                ELSE b.arakons_no
              END                                                                     AS kosimento
            , COALESCE( TO_CHAR(_tasima.tarih, 'DD/MM/YYYY HH24:MI')
                      , TO_CHAR(b.kons_trh   , 'DD/MM/YYYY HH24:MI')
                      )                                                               AS konsimentotar
            , _tarih.etatarih                                                         AS etatarih
            , CASE
                WHEN ( b.tesciltarih    IS NULL     ) THEN 'Varış Bekler'
                WHEN ( b.trhfaturakesim IS NOT NULL )
                  OR ( b.durumtip = 'K'             ) THEN 'Fatura Kesildi'
                WHEN ( b.trhsevk        IS NOT NULL ) THEN 'Eşya Sevk Edildi'
                ELSE 'İşlemde'
              END                                                                     AS dosyadurum
            , b.trhfaturakesim
            , CASE
                WHEN _tasima.tarih IS NULL THEN b.trhsevk::DATE - b.kons_trh::DATE
                ELSE b.trhsevk::DATE - _tasima.tarih::DATE
              END                                                                     AS islemtarih
            , CASE
                WHEN b.trhsevk    IS NULL AND b.trhveznede IS NOT NULL  THEN b.trhveznede
                WHEN b.trhveznede IS NULL AND b.trhkapandi IS NOT NULL
                 AND b.trhkapandi <> '1899-12-30'::TIMESTAMP(0)         THEN b.trhkapandi
                ELSE b.trhsevk
              END                                                                     AS trhsevk
            , _tarih.ekaciklama
            , _tarih.tarihsr
            , _fatbas.faturatarih                                                     AS faturatarih
FROM          slz05.gumfirma        AS c
INNER JOIN    ortak.mfyhesapai      AS mha  ON mha.eskihesap  = c.kartno
INNER JOIN    ortak.mfykartext      AS mht  ON mht.hesap      = mha.yenihesap
INNER JOIN    slz05.gumbeyanbaslik  AS b    ON b.firma        = c.firma
LEFT JOIN     slz05.gumfirmakarsi   AS kf   ON kf.firma       = b.firma AND kf.karsifirma  = b.karsifirma

LEFT JOIN LATERAL -- Fatura numaraları ve fatura tarihlerini birleştirmek için
( SELECT      STRING_AGG(x.fatevrno::VARCHAR, ',')                            AS faturano     -- Fatura numaraları.
            , STRING_AGG(TO_CHAR(x.tarih, 'DD/MM/YYYY HH24:MI'), ',')         AS faturatarih  -- Formatlanmış fatura tarihleri.
  FROM        slz05.gumbeyanfatbas AS x
  WHERE       x.evrcinsi = b.evrcinsi
    AND       x.evrseri  = b.evrseri
    AND       x.evrno    = b.evrno
) AS _fatbas ON 1 = 1

LEFT JOIN LATERAL -- Beyanname statüsünü almak için
( SELECT      x.statu             AS statu
  FROM        slz05.gumbeyanbilge AS x
  WHERE       x.evrcinsi    = b.evrcinsi
    AND       x.evrseri     = b.evrseri
    AND       x.evrno       = b.evrno
    AND       x.beyannameno = b.tescilno
  LIMIT 1
) AS _statu ON 1 = 1

LEFT JOIN LATERAL -- Özet beyan numarasını almak için (slz05.gumbeykonsbas'tan)
( SELECT      MAX(x.ozetbeyanno)  AS ozet_beyan_no                            -- Maksimum özet beyan numarası.
  FROM        slz05.gumbeykonsbas AS x
  WHERE       x.evrcinsi = b.evrcinsi
    AND       x.evrseri  = b.evrseri
    AND       x.evrno    = b.evrno
) AS _ozet ON 1 = 1

LEFT JOIN LATERAL -- Taşıma senedi ve konşimento tarihi için (slz05.gumbeykonsbas'tan)
( SELECT      STRING_AGG(x.tasimasenet::VARCHAR, ',') AS tasimasenet          -- Birleştirilmiş taşıma senetleri.
            , x.tarih                                 AS tarih                -- Konşimento tarihi.
  FROM        slz05.gumbeykonsbas AS x
  WHERE       x.evrcinsi = b.evrcinsi
    AND       x.evrseri  = b.evrseri
    AND       x.evrno    = b.evrno
  GROUP BY    x.tarih
) AS _tasima ON 1 = 1

LEFT JOIN LATERAL -- ETA tarihi, ek açıklama ve ilgili tarihleri almak için (slz05.gumbeyantarih'ten)
( SELECT      MAX(CASE WHEN x.tip = 'ECZETA'    THEN x.tarih      ELSE NULL END) AS etatarih       -- ETA tarihi.
            , MAX(CASE WHEN x.tip = 'HATLIESYA' THEN x.ekaciklama ELSE NULL END) AS ekaciklama     -- Hatlı eşya ek açıklaması.
            , MAX(CASE WHEN x.tip = 'HATLIESYA' THEN x.tarih      ELSE NULL END) AS tarihsr        -- Hatlı eşya tarihi.
  FROM        slz05.gumbeyantarih   AS x
  WHERE       x.evrcinsi = b.evrcinsi
    AND       x.evrseri  = b.evrseri
    AND       x.evrno    = b.evrno
    AND       x.tip     IN ('ECZETA', 'HATLIESYA')
) AS _tarih ON 1 = 1

LEFT JOIN LATERAL -- slz05.genkod tablosundan birden fazla kod aciklamasini tek seferde almak için
( WITH      _ARANAN_KODLAR (tur, tip, kod)  AS
  ( VALUES    ('dosya_ref'    , 323, 'ECZSEL'::VARCHAR)
            , ('gumruk_idare' , 314, b.gcgumidare::VARCHAR)
            , ('odeme_sekli'  , 310, b.bankaodsek::VARCHAR)
  )
  SELECT      MAX(CASE WHEN ak.tur = 'dosya_ref'     THEN gk.aciklama  END) AS dosya_ref_aciklama
            , MAX(CASE WHEN ak.tur = 'gumruk_idare'  THEN gk.aciklama  END) AS gumruk_aciklama
            , MAX(CASE WHEN ak.tur = 'odeme_sekli'   THEN gk.aciklama  END) AS banka_aciklama
  FROM        _ARANAN_KODLAR  AS ak
  LEFT JOIN   slz05.genkod    AS gk ON gk.tip = ak.tip 
                                   AND gk.kod = ak.kod
) AS _genkod ON 1 = 1

-- Bu where koşullarının SIRALAMASI ÖNEMLİ ! UP
WHERE ( mha.merkezid    = 'CMP-SOLGUM-IST'::VARCHAR             )
  AND ( mht.externalid  = '$firma' )
  AND ( b.durumtip     <> 'K'                                   )
  AND ( $solmazrefno  IS NULL OR b.evrno          = $solmazrefno)
  AND ( $tescilno     IS NULL OR b.tescilno       = $tescilno   )
  AND ( $faturano     IS NULL
    OR  EXISTS( SELECT 1
                FROM    slz05.gumbeyanfatbas as x
                WHERE   x.evrcinsi = b.evrcinsi
                  AND   x.evrseri  = b.evrseri
                  AND   x.evrno    = b.evrno
                  AND   x.fatevrno = $faturano
              )
      )
  AND ( $refnofirma   IS NULL OR b.referans LIKE '%' || $refnofirma::VARCHAR || '%' )
;


/*
----------------------------------------------------------------------------------------------------
 PostgreSQL Sorgu Optimizasyon Adımları Özeti
----------------------------------------------------------------------------------------------------
* Veri tipleri (TEXT->VARCHAR, DATE->TIMESTAMP(0)) PostgreSQL'e uygun dönüştürüldü.
* Informix'e özgü fonksiyonlar (infx_decode, nvl, group_concat) standart SQL (CASE, COALESCE, STRING_AGG) ile değiştirildi.
* Informix join sözdizimi standart JOIN ... ON yapısına çevrildi.

* SELECT listesi ve WHERE koşulundaki korele alt sorgular LEFT JOIN LATERAL yapılarına dönüştürüldü.

* En dıştaki "result_" alt sorgu katmanı kaldırılarak WHERE koşulu ana sorguya entegre edildi.

* Opsiyonel parametre filtreleri "COALESCE($param, alan)" yerine "$param IS NULL OR alan = $param" olarak güncellendi.

* Aynı tablolara yönelik bazı LATERAL JOIN'ler performans için birleştirildi.
* Satır çoğaltma riskine karşı slz05.gumbeykonsbas için yapılan birleştirme geri alındı, iki ayrı LATERAL JOIN korundu.

* fn_getkodalan UDF çağrıları, slz05.genkod tablosuna tek bir LEFT JOIN LATERAL (içinde CTE ile) ile değiştirildi.
* fn_gum_getfirmakarsiunvan UDF çağrısı, slz05.gumfirmakarsi tablosuna doğrudan LEFT JOIN ile değiştirildi.

* get_firmalar UDF çağrısının verimsizliği EXPLAIN ANALYZE ile tespit edildi.
* Fonksiyonun SQL mantığı, ana sorgunun FROM/JOIN bölümüne entegre edildi:
  - Ana FROM kaynağı slz05.gumfirma (c) olarak ayarlandı.
  - Fonksiyon içindeki join'ler c tablosuna bağlandı.
  - slz05.gumbeyanbaslik (b) tablosu bu yapıya INNER JOIN ile eklendi.
  Bu değişiklik fonksiyon çağrısını ortadan kaldırarak performansı ~5 saniyeden ~35 milisaniyeye düşürdü.

* $faturano parametresi için filtreleme mantığı, "=" yerine ana WHERE koşuluna eklenen EXISTS alt sorgusu ile güncellendi.
  Bu, slz05.gumbeyanfatbas tablosunda doğrudan fatura numarası kontrolü sağladı ve _fatbas LATERAL'inin tüm faturaları göstermesini korudu.

* EXPLAIN ANALYZE çıktılarına göre ilgili tablolara (slz05.gumbeyanbaslik, ortak.mfyhesapai, ortak.mfykartext) BTREE indeksler eklendi.
* Mevcut HASH indeksler BTREE'ye dönüştürüldü.
* slz05.gumbeyanbilge'deki gereksiz (PK tarafından kapsanan) HASH indeksin kaldırılması sağlandı.

* slz05.gumbeyanbaslik tablosunun ana firma belirleme mantığına (INNER JOIN ... ON b.firma = c.firma) join koşulu netleştirilerek sorgunun doğruluğu artırıldı.
*/

