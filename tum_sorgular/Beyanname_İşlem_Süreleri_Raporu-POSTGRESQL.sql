--EXPLAIN (ANALYZE, BUFFERS)
SELECT        b.evrno                                                               AS solmaz_referans
            , b.referans                                                            AS firma_referans
            , b.beyan1                                                              AS beyan_1
            , b.beyan2                                                              AS beyan_2
            , b.tescilno                                                            AS tescil_no
            , TO_CHAR(b.trhtescil, 'YYYY-MM-DD')                                    AS tescil_tarihi
            , TO_CHAR(b.trhtescil, 'HH24:MI')                                       AS tescil_saati
            , b.dosyaturu                                                           AS dosya_turu
            , b.trhisemir                                                           AS is_emir_tarihi
            , CASE WHEN b.arc_id = 0 THEN 'HAYIR' ELSE 'EVET' END::VARCHAR          AS arsivlenmis             -- Sonuç tipi VARCHAR olarak belirtildi.
            , _fatura.fatura_no_list                                                AS fatura_no
            , _fatura.fatura_tarih_list                                             AS fatura_tarih
            , _fatura.fatura_tutar_list                                             AS fatura_tutar
            , _fatura.fatura_doviz_list                                             AS fatura_doviz
            , _bilge.statu                                                          AS statu
            , _tesgum.ACIKLAMA                                                      AS gumruk_idaresi           -- fn_getkodalan(314, b.tescilgum) AS gumruk_idaresi
            , CASE
                WHEN b.trhkirmizihat  IS NOT NULL THEN 'Kırmızı'
                WHEN b.trhsarihat     IS NOT NULL THEN 'Sarı'
                WHEN b.trhmavihat     IS NOT NULL THEN 'Mavi'
                WHEN b.trhyesilhat    IS NOT NULL THEN 'Yeşil'
                ELSE 'Belirsiz'
              END::VARCHAR                                                          AS hatdurumu
            -- Bu, fonksiyonun optimize edilmiş versiyonu, bu haliyle bile karmaşık aslında, kurtulamadık bir türlü! UP
            -- Fonksiyon içindeki genkod tablosunda performansı kurtaracak indeksler de eklenmiştir, bu haliyle darboğaz oluşturmaz. UP
            , slz05.fn_getdurumaciklamasi(b.durum, '')                              AS ekaciklama
            , b.trhkapandi                                                          AS beyanname_kapama_tarihi
            , b.trhveznede                                                          AS veznede_tarih
            , b.trhsevk                                                             AS sevk_tarihi
            , (b.trhsevk::DATE - b.trhtescil::DATE) + 1                             AS esya_sevk_sure
            , b.trhfaturakesim                                                      AS fatura_kesim_tarihi

FROM          slz05.gumfirma        AS c                                        --  Burada gumfirma tablosunu tepeye aldık çünkü  
INNER JOIN    ortak.mfyhesapai      AS mha  ON mha.eskihesap  = c.kartno        --  get_firmalar fonksiyonundan kurtulmak performansı kurtulmak gerekiyordu
INNER JOIN    ortak.mfykartext      AS mht  ON mht.hesap      = mha.yenihesap   --  eğer bunu yapmasaydık 0.25 ms süren sorgu 5 saniyelere kadar çıkacak idi
INNER JOIN    slz05.gumbeyanbaslik  AS b    ON b.firma        = c.firma         --  bu da 1731 satır için 5 saniyelik bir gecikmenin kabul edilemez olduğunu gösterir. UP

LEFT JOIN LATERAL -- gumbeyanfatbas tablosundan fatura ile ilgili bilgileri toplar
( SELECT      STRING_AGG(DISTINCT s.fatevrno::VARCHAR, ',')                                       AS fatura_no_list         -- Fatura numaraları, virgülle ayrılmış.
            , STRING_AGG(DISTINCT TO_CHAR(s.tarih, 'DD/MM/YYYY HH24:MI'), ',')                    AS fatura_tarih_list      -- Fatura tarihleri, virgülle ayrılmış.
            , STRING_AGG(s.tutar::VARCHAR, ',')                                                   AS fatura_tutar_list      -- Fatura tutarları, virgülle ayrılmış (orijinalde DISTINCT yoktu).
            , STRING_AGG(DISTINCT CASE s.tutardov WHEN 'YTL' THEN 'TL' ELSE s.tutardov END, ',')  AS fatura_doviz_list      -- Fatura döviz türleri, virgülle ayrılmış.
  FROM        slz05.gumbeyanfatbas AS s
  WHERE       s.evrcinsi          = b.evrcinsi
    AND       s.evrseri           = b.evrseri
    AND       s.evrno             = b.evrno
) AS _fatura ON 1 = 1

LEFT JOIN LATERAL -- gumbeyanbilge tablosundan statü bilgisini alır
( SELECT      sgb.statu
  FROM        slz05.gumbeyanbilge AS sgb
  WHERE       sgb.evrcinsi        = b.evrcinsi
    AND       sgb.evrseri         = b.evrseri
    AND       sgb.evrno           = b.evrno
    AND       sgb.beyannameno     = b.tescilno -- Orijinal sorgudaki eşleşme koşulu.
  LIMIT 1
) AS _bilge ON 1 = 1

LEFT JOIN LATERAL -- fn_getkodalan(314, b.tescilgum) AS gumruk_idaresi
( SELECT  X.ACIKLAMA
  FROM    slz05.genkod    AS X
  WHERE   X.tip         = 314 
    AND   X.kod         = b.tescilgum       
  LIMIT 1
) AS _tesgum ON 1 = 1

WHERE   ( mha.merkezid    = CAST('CMP-SOLGUM-IST'AS VARCHAR)         )
  AND   ( mht.externalid  = '$firma' )
  AND   ( $tarih1 IS NOT NULL                                                                     -- Ben ekledim, tarih parametresi yoksa kayıt da dönmesin... UP
      AND $tarih2 IS NOT NULL                                                                     -- Ben ekledim, tarih parametresi yoksa kayıt da dönmesin... UP
      AND b.trhtescil BETWEEN '$tarih1' AND '$tarih2'             )
  AND   ( $solmazrefno IS NULL OR b.evrno     = $solmazrefno  )                                   -- Opsiyonel parametre, eğer null ise koşul ekleme demek... UP
  AND   ( $tescilno    IS NULL OR b.tescilno  = $tescilno     )                                   -- Opsiyonel parametre, eğer null ise koşul ekleme demek... UP
  AND   ( $refnofirma  IS NULL OR b.referans LIKE '%' || cast($refnofirma as VARCHAR) || '%' )            -- Opsiyonel parametre, eğer null ise koşul ekleme demek... UP
;
/*
:firma          = 'CMP59BHUBJ1126'
:tarih1         = 2025-05-01
:tarih2         = 2025-05-09
:solmazrefno    = 3037288
:tescilno       = 25330100EX00082098
:refnofirma     = '1 KONT'
*/

