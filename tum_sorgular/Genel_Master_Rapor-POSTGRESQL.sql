--SET enable_nestloop = on;
--EXPLAIN ANALYZE
--EXPLAIN (ANALYZE, BUFFERS)
WITH cte_t1 AS  (
  SELECT
              CASE WHEN a.arc_id = 0 THEN 'HAYIR' ELSE 'EVET' END                       AS arsivlenmis
            , a.evrno                                                                   AS evrno
            , a.referans                                                                AS firma_referans
            , a.tescilno                                                                AS tescilno
            , a.tesciltarih                                                             AS tesciltarih        -- Veri tipi DATE ise TIMESTAMP(0) olarak maplendi.
            , REPLACE(COALESCE(_dogrulama_url.dogrulamaurl, ''), 'http://', 'https://') AS dogrulamaurl
            , a.trhintac                                                                AS trhintac           -- Veri tipi DATE ise TIMESTAMP(0) olarak maplendi.
            , TO_CHAR(a.trhtescil, 'YYYY-MM-DD')                                        AS tescil_tarihi
            , TO_CHAR(a.trhtescil, 'HH24:MI')                                           AS tescil_saati
            , a.dosyaturu                                                               AS dosya_turu
            , _statu.statu                                                              AS statu
            , kf.unvan                                                                  AS karsi_firma    --  , slz05.fn_gum_getfirmakarsiunvan(a.firma, a.karsifirma) AS karsi_firma
            , _genkod.gumruk                                                            AS gumruk         --  , slz05.fn_getkodalan(314, a.gcgumidare)  AS gumruk
            , COALESCE(gbm.rejim1, '??') || COALESCE(gbm.rejim2, '??')                  AS rejim_kodu     --  , slz05.gumrejim12(m.evrcinsi, m.evrseri, m.evrno) AS rejim_kodu
            , a.teslimsek                                                               AS teslimsek
            , _arac_lat.tasit_agg                                                       AS tasit
            , b.fatevrno                                                                AS faturano
            , a.tutar                                                                   AS beyanname_toplam_tutar
            , CASE a.dovizkod WHEN 'YTL' THEN 'TL' ELSE a.dovizkod END                  AS doviz_cinsi
            , a.dovizkur                                                                AS doviz_kuru
            , _ist_tutarlar_lat.ist_usd                                                 AS istatistik_tutar_usd
            , _ist_tutarlar_lat.ist_tl                                                  AS istatistik_tutar_tl
            , m.kapsayi                                                                 AS kap_sayi
            , m.kapbirim                                                                AS kap_cinsi
            , m.beyan_sirano                                                            AS kalem_no
            , m.gtip                                                                    AS gtip
            , _stok.stokno                                                              as stokno              --  , slz05.fn_gum_getstokno(a.firma, m.itemid)       AS stokno
            , _stok.aciklama                                                            as ticari_ad           --  , slz05.fn_gum_getstokaciklama(a.firma, m.itemid) AS ticari_ad
            , m.tutar                                                                   AS kalem_tutar
            , m.miktar                                                                  AS miktar
            , m.birim                                                                   AS birim
            , m.brutag                                                                  AS brut_agirlik
            , m.netag                                                                   AS net_agirlik
            , a.hd_iskonto                                                              AS iskonto
            , a.hd_faiz                                                                 AS hd_faiz             -- Bu alan t4'te kullanılmıyor, ancak orijinal sorguda var.
            , a.hd_diger                                                                AS diger_toplam        -- Bu alan t4'te kullanılmıyor, ancak orijinal sorguda var.
            , a.hd_navlun                                                               AS navlun              -- Bu, başlık seviyesindeki navlun. Kalemlere dağıtılacak.
            , a.hd_sigorta                                                              AS sigorta             -- Bu, başlık seviyesindeki sigorta. Kalemlere dağıtılacak.
            , a.tem_tem                                                                 AS teminat
            , a.tem_tur                                                                 AS teminat_turu
            , _ulke.ticaret_ulke                                                        AS ticaret_ulke   --  , slz05.fn_ulke(a.ticulke)    AS ticaret_ulke
            , _ulke.sevk_ulke                                                           AS sevk_ulke      --  , slz05.fn_ulke(a.sevkulke)   AS sevk_ulke
            , _ulke.mense_ulke                                                          AS mense_ulke     --  , slz05.fn_ulke(m.menseulke)  AS mense_ulke
            , _ulke.gidecegi_ulke                                                       AS gidecegi_ulke  --  , slz05.fn_ulke(a.gidulke)    AS gidecegi_ulke
            , _ulke.cikis_ulke                                                          AS cikis_ulke     --  , slz05.fn_ulke(a.cikisulke)  AS cikis_ulke
            , _ulke.gidecegi_ulke                                                       AS varis_ulke     --  , slz05.fn_ulke(a.gidulke)    AS varis_ulke          -- gidulke zaten gidecegi_ulke olarak alındı, tekrarı olabilir.
            , gb.BANKASUBE || ' ' || gb.il || ' ' || gb.ad                              AS bankadi        --  , slz05.gum_kuryeadres('B', a.bankakod) AS bankadi
            , _genkod.odeme_sekli                                                       AS odeme_sekli      --, slz05.fn_getkodalan(310, a.bankaodsek)  AS odeme_sekli
            , a.esyayer                                                                 AS esya_yer
            , a.antrepokod                                                              AS antrepo_kodu
            , m.st_miktar                                                               AS olcu_miktari
            , m.st_birim                                                                AS olcu_birimi
            , m.fiyat                                                                   AS fiyat
            , m.ciftutartl                                                              AS istatistik_tutar_tl_kalem
            , m.iskonto                                                                 AS komisyon             -- Bu, kalem seviyesindeki iskonto/komisyon.
            , COALESCE(_gbfatdig.demuraj_tutar, 0)                                      AS demuraj
            , m.royaltytl                                                               AS royalty              -- Bu, kalem seviyesindeki royalty.
            , m.faiz                                                                    AS faiz                 -- Bu, kalem seviyesindeki faiz.
            , b.diger                                                                   AS diger                -- Bu, fatura başlık seviyesindeki diger. Kalemlere dağıtılacak.
            , COALESCE(_gbfatdig.ardiye_tutar, 0)                                       AS ardiye               --  , slz05.fn_gum_beyfatdig(a.evrcinsi, a.evrseri, a.evrno, 'D') AS ardiye -- Bu, başlık seviyesindeki ardiye. Kalemlere dağıtılacak.
            , COALESCE(_gbfatdig.banka_tutar, 0)                                        AS banka                --  , slz05.fn_gum_beyfatdig(a.evrcinsi, a.evrseri, a.evrno, 'B') AS banka  -- Bu, başlık seviyesindeki banka masrafı. Kalemlere dağıtılacak.
            , COALESCE(_gbfatdig.yurtici_tutar, 0)                                      AS yurtici              --  , slz05.fn_gum_beyanyurtici(a.evrcinsi, a.evrseri, a.evrno) AS yurtici -- Bu, başlık seviyesindeki yurtiçi masraf. Kalemlere dağıtılacak.
            , _genkod.satici_iliski                                                     AS satici_iliski        --  , slz05.fn_getkodalan(326, a.iliski)      AS satici_iliski
            , _genkod.islem_nitelik                                                     AS islem_nitelik        --  , slz05.fn_getkodalan(304, a.sozlesme1)   AS islem_nitelik
            , _genkod.dahili_tasima                                                     AS dahili_tasima        --  , slz05.fn_getkodalan(306, a.stasimasek)  AS dahili_tasima
            , _genkod.sinir_tasima                                                      AS sinir_tasima         --  , slz05.fn_getkodalan(306, a.dtasimasek)  AS sinir_tasima
            , m.muaf_1                                                                  AS muaf_1
            , m.muaf_2                                                                  AS muaf_2
            , m.muaf_3                                                                  AS muaf_3
            , m.anlasma                                                                 AS atr
            , a.flgsupalan                                                              AS supalan
            , a.basitusul                                                               AS basit_usul
  FROM        slz05.gumbeyanbaslik  AS a
  CROSS JOIN LATERAL -- get_firmalar fonksiyonunu sadece 1 kere çağırsın diye bu şekilde yapıldı. Aşağıda EXISTS geçen yerler için kullanılıyor.
  ( SELECT  slz05.get_firmalar('CMP-SOLGUM-IST'::VARCHAR, '$firma'::VARCHAR) AS firma                 -- Array tipinde bir dizi dönüyor, aşağıdaki EXISTS'da UNNEST ile işleniyor. UP
  ) AS _firmalar
  LEFT JOIN   slz05.gumbanka        AS gb   ON gb.kod           = a.bankakod --> slz05.gum_kuryeadres('B', a.bankakod)
  INNER JOIN  slz05.gumfirma        AS c    ON a.firma          = c.firma --  inner olduğu için silmedim ama gumfirma, selectin diğer hiç bir yerinde kullanılmıyor... UP
  INNER JOIN  slz05.gumfirmakarsi   AS kf   ON kf.firma         = a.firma    AND kf.karsifirma  = a.karsifirma --  , slz05.fn_gum_getfirmakarsiunvan(a.firma, a.karsifirma) AS karsi_firma
  INNER JOIN  slz05.gumbeyanfatbas  AS b    ON a.evrno          = b.evrno
                                           AND a.evrseri        = b.evrseri
                                           AND a.evrcinsi       = b.evrcinsi
  INNER JOIN  slz05.gumbeyanfatmad  AS m    ON a.evrno          = m.evrno
                                           AND a.evrseri        = m.evrseri
                                           AND a.evrcinsi       = m.evrcinsi
                                           AND b.fatevrseri     = m.fatevrseri
                                           AND b.fatevrno       = m.fatevrno
                                           AND b.fatevrcinsi    = m.fatevrcinsi
  LEFT JOIN   slz05.gumbeyanmadde   AS gbm  ON gbm.evrcinsi     = m.evrcinsi
                                           AND gbm.evrseri      = m.evrseri
                                           AND gbm.evrno        = m.evrno
                                           AND gbm.sirano       = 1 -- SIRANO = 1 koşulu ON cümlesine dahil edilir.
  
  LEFT JOIN LATERAL -- slz05.fn_ulke ve genel.genulke tablosundan birden fazla ulke bilgisini tek seferde almak için
  ( SELECT    MAX(CASE WHEN gu.ulkekod = a.ticulke   THEN gu.adi END) AS ticaret_ulke
            , MAX(CASE WHEN gu.ulkekod = a.sevkulke  THEN gu.adi END) AS sevk_ulke
            , MAX(CASE WHEN gu.ulkekod = m.menseulke THEN gu.adi END) AS mense_ulke   -- m.menseulke kullanılıyor, dikkat!
            , MAX(CASE WHEN gu.ulkekod = a.gidulke   THEN gu.adi END) AS gidecegi_ulke      -- slz05.fn_ulke(a.gidulke) as gidecegi_ulke + slz05.fn_ulke(a.gidulke) as varis_ulke... ORJİNALİ BÖYLE ARKADAŞIM ! UP
            , MAX(CASE WHEN gu.ulkekod = a.cikisulke THEN gu.adi END) AS cikis_ulke
    FROM      genel.genulke AS gu
    WHERE     gu.ulkekod IN (a.ticulke, a.sevkulke, m.menseulke, a.gidulke, a.cikisulke)
  ) AS _ulke ON 1 = 1

  LEFT JOIN LATERAL -- slz05.genkod tablosundan birden fazla kod aciklamasini tek seferde almak için. UP
  ( WITH      _ARANANLAR      (tur, tip, kod)   AS
    ( VALUES  ('odeme_sekli',   310, a.bankaodsek)
            , ('gumruk',        314, a.gcgumidare)
            , ('satici_iliski', 326, a.iliski    )
            , ('islem_nitelik', 304, a.sozlesme1 )
            , ('dahili_tasima', 306, a.stasimasek) -- Aynı tip (306) iki farklı kod için
            , ('sinir_tasima',  306, a.dtasimasek) -- Aynı tip (306) iki farklı kod için
    )
    SELECT    MAX(CASE WHEN ak.tur = 'gumruk'        THEN gk.aciklama  END) AS gumruk
            , MAX(CASE WHEN ak.tur = 'odeme_sekli'   THEN gk.aciklama  END) AS odeme_sekli
            , MAX(CASE WHEN ak.tur = 'satici_iliski' THEN gk.aciklama  END) AS satici_iliski
            , MAX(CASE WHEN ak.tur = 'islem_nitelik' THEN gk.aciklama  END) AS islem_nitelik
            , MAX(CASE WHEN ak.tur = 'dahili_tasima' THEN gk.aciklama  END) AS dahili_tasima
            , MAX(CASE WHEN ak.tur = 'sinir_tasima'  THEN gk.aciklama  END) AS sinir_tasima
    FROM      _ARANANLAR    AS ak
    LEFT JOIN slz05.genkod  AS gk ON gk.tip = ak.tip AND gk.kod = ak.kod -- ÖNEMLİ: Burası LEFT JOIN olmalı ki a tablosundaki kodlardan biri genkod'da olmasa bile NULL gelsin. UP
  ) AS _genkod ON 1 = 1
  
  LEFT JOIN LATERAL --  slz05.fn_gum_getstokno ve slz05.fn_gum_getstokaciklama
  ( SELECT    x.stokno
            , x.aciklama
    FROM      slz05.gumfirmagtip    AS x
    WHERE     x.firma               = a.firma
      AND     x.itemid              = m.itemid
    LIMIT     1
  ) AS _stok ON 1 = 1
  
  LEFT JOIN LATERAL -- dogrulamaurl alanını almak için
  ( SELECT    q.dogrulamaurl
    FROM      slz05.gumbeyanbilge AS q
    WHERE     q.evrcinsi          = a.evrcinsi
      AND     q.evrseri           = a.evrseri
      AND     q.evrno             = a.evrno
    LIMIT 1   -- Birden fazla eşleşme durumunda ilkini alır, orijinal sorguda tekil sonuç bekleniyor.
  ) AS _dogrulama_url ON 1 = 1
  
  LEFT JOIN LATERAL -- statu alanını almak için
  ( SELECT    s.statu
    FROM      slz05.gumbeyanbilge AS s
    WHERE     s.evrcinsi          = a.evrcinsi
      AND     s.evrseri           = a.evrseri
      AND     s.evrno             = a.evrno
      AND     s.beyannameno       = a.tescilno -- Orijinal sorgudaki ek koşul
    LIMIT 1 -- Birden fazla eşleşme durumunda ilkini alır.
  ) AS _statu ON 1 = 1
  
  LEFT JOIN LATERAL -- tasit bilgilerini birleştirmek için
  ( SELECT    STRING_AGG(s.tasit, ',') AS tasit_agg -- Informix group_concat yerine PostgreSQL STRING_AGG
    FROM      slz05.gumbeyanarac       AS s
    WHERE     s.evrcinsi               = a.evrcinsi
      AND     s.evrseri                = a.evrseri
      AND     s.evrno                  = a.evrno
      AND     s.tur                    = '2'
  ) AS _arac_lat ON 1 = 1
  
  LEFT JOIN LATERAL -- istatistik tutar usd ve tl hesaplamaları için
  ( SELECT    SUM(ROUND(s.CIFTUTARTL * a.HD_TOPCIF_USD / NULLIF(a.HD_TOPCIF, 0), 2))::NUMERIC AS ist_usd -- Sıfıra bölme NULLIF ile engellendi.
            , SUM(s.ciftutartl)::NUMERIC                                                     AS ist_tl
    FROM      slz05.gumbeyanfatmad     AS s
    WHERE     s.evrno                  = a.evrno
      AND     s.evrseri                = a.evrseri
      AND     s.evrcinsi               = a.evrcinsi
  ) AS _ist_tutarlar_lat ON 1 = 1
  
  LEFT JOIN LATERAL -- slz05.fn_gum_beyfatdig, slz05.fn_gum_beyanyurtici optimizasyonu; demuraj, ardiye ve banka masraflarını gumbeyanfatdig tablosundan tek seferde hesaplamak için
  ( SELECT    SUM(CASE WHEN s.tur = 'E'         THEN s.tutar ELSE 0 END)  AS demuraj_tutar -- Demuraj için
            , SUM(CASE WHEN s.tur = 'D'         THEN s.tutar ELSE 0 END)  AS ardiye_tutar  -- Ardiye için (eski fn_gum_beyfatdig(..., 'D'))
            , SUM(CASE WHEN s.tur = 'B'         THEN s.tutar ELSE 0 END)  AS banka_tutar   -- Banka masrafı için (eski fn_gum_beyfatdig(..., 'B'))
            , SUM(CASE WHEN s.matrahtur = 'KDV' THEN s.tutar ELSE 0 END)  AS yurtici_tutar -- Yurtiçi KDV matrahı için (eski fn_gum_beyanyurtici)
    FROM      slz05.gumbeyanfatdig  AS s
    WHERE     s.evrcinsi            = a.evrcinsi
      AND     s.evrseri             = a.evrseri
      AND     s.evrno               = a.evrno
      AND   ( s.tur IN ('E', 'D', 'B') OR s.matrahtur = 'KDV' )
  ) AS _gbfatdig ON 1 = 1
  
--  CROSS JOIN LATERAL -- get_firmalar fonksiyonunu sadece 1 kere çağırsın diye bu şekilde yapıldı. Aşağıda EXISTS geçen yerler için kullanılıyor.
--  ( SELECT  slz05.get_firmalar('CMP-SOLGUM-IST'::VARCHAR, $firma::VARCHAR) AS firma                 -- Array tipinde bir dizi dönüyor, aşağıdaki EXISTS'da UNNEST ile işleniyor. UP
--  ) AS _firmalar
  
  WHERE   EXISTS (SELECT 1 FROM unnest(_firmalar.firma) as f WHERE f = a.firma or f = a.faturafirma) -- _firmalar adlı joine bak ! UP
    AND   a.tesciltarih BETWEEN '$tarih1' AND '$tarih2'           -- Parametreler @tarih1, @tarih2 -> $tarih1, $tarih2. Tip dönüşümü eklendi.
    AND   a.durum       <> '*[Ø]*' -- Informix != yerine standart <> kullanıldı.
    AND   m.beyan_sirano <> 0
    AND ( $solmazrefno IS NULL OR ( a.evrno       = $solmazrefno) )     -- Parametre @solmazrefno -> $solmazrefno
    AND ( $tescilno    IS NULL OR ( a.tescilno    = $tescilno   ) )     -- Parametre @tescilno    -> $tescilno
    AND ( $faturano    IS NULL OR ( b.fatevrno    = $faturano   ) )     -- Parametre @faturano    -> $faturano
    AND ( $refnofirma  IS NULL OR ( a.referans LIKE '%' || cast($refnofirma as VARCHAR) || '%' ) )  -- Opsiyonel parametre, eğer null ise bu koşulu ekleme demek... UP

),
cte_t2 AS (
  SELECT  ROW_NUMBER() OVER(PARTITION BY t1.kalem_no, t1.evrno ORDER BY t1.kalem_no, t1.evrno)  AS kalemsayi -- ORDER BY eklendi, deterministik olması için. UP
        , SUM(t1.kalem_tutar) OVER(PARTITION BY t1.kalem_no, t1.evrno)                          AS toplamkalem
        , SUM(t1.kalem_tutar) OVER(PARTITION BY t1.evrno)                                       AS geneltoplam
        , t1.*
  FROM    cte_t1 AS t1
),
cte_t3 AS (
  SELECT  COALESCE((COALESCE(t2.diger, 0)   / NULLIF(t2.geneltoplam, 0)) * t2.kalem_tutar, 0) AS digerkalem    -- Sıfıra bölme kontrolü ve COALESCE eklendi
        , COALESCE((COALESCE(t2.ardiye, 0)  / NULLIF(t2.geneltoplam, 0)) * t2.kalem_tutar, 0) AS ardiyekalem   -- Sıfıra bölme kontrolü ve COALESCE eklendi
        , COALESCE((COALESCE(t2.banka, 0)   / NULLIF(t2.geneltoplam, 0)) * t2.kalem_tutar, 0) AS bankakalem    -- Sıfıra bölme kontrolü ve COALESCE eklendi
        , COALESCE((COALESCE(t2.navlun, 0)  / NULLIF(t2.geneltoplam, 0)) * t2.kalem_tutar, 0) AS navlunkalem   -- Sıfıra bölme kontrolü ve COALESCE eklendi
        , COALESCE((COALESCE(t2.sigorta, 0) / NULLIF(t2.geneltoplam, 0)) * t2.kalem_tutar, 0) AS sigortakalem  -- Sıfıra bölme kontrolü ve COALESCE eklendi
        , COALESCE((COALESCE(t2.royalty, 0) / NULLIF(t2.toplamkalem, 0)) * t2.kalem_tutar, 0) AS kalem_royal   -- Sıfıra bölme kontrolü ve COALESCE eklendi
        , COALESCE((COALESCE(t2.yurtici, 0) / NULLIF(t2.geneltoplam, 0)) * t2.kalem_tutar, 0) AS yurticitop    -- Sıfıra bölme kontrolü ve COALESCE eklendi
        , t2.*
  FROM    cte_t2 AS t2
)
SELECT
          t3.evrno                                                                    AS solmaz_referans
        , t3.firma_referans
        , t3.tescilno
        , t3.tescil_tarihi
        , t3.tescil_saati
        , t3.dogrulamaurl
        , t3.trhintac
        , t3.arsivlenmis
        , t3.dosya_turu
        , t3.statu
        , t3.karsi_firma
        , t3.gumruk
        , t3.rejim_kodu
        , t3.teslimsek
        , t3.tasit
        , t3.faturano
        , t3.beyanname_toplam_tutar
        , t3.doviz_cinsi
        , t3.doviz_kuru
        , t3.istatistik_tutar_usd
        , t3.istatistik_tutar_tl
        , t3.kap_sayi
        , t3.kap_cinsi
        , t3.kalem_no
        , t3.gtip
        , t3.stokno
        , t3.ticari_ad
        , t3.kalem_tutar
        , t3.miktar
        , t3.birim
        , t3.brut_agirlik
        , t3.net_agirlik
        , t3.iskonto                                                                    -- Başlık iskontosu
        , t3.hd_faiz                                                                    -- Başlık faizi (cte_t1'den geliyor)
        , t3.diger_toplam                                                               -- Başlık diğer toplam (cte_t1'den geliyor)
        , CASE t3.kalemsayi
              WHEN 1
              THEN TRUNC(t3.navlunkalem, 2) + (SUM(ROUND(t3.navlunkalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno)) - (SUM(TRUNC(t3.navlunkalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno))
              ELSE TRUNC(t3.navlunkalem, 2)
          END                                                                           AS navlun            -- Kaleme dağıtılmış navlun
        , CASE t3.kalemsayi
              WHEN 1
              THEN TRUNC(t3.sigortakalem, 2) + (SUM(ROUND(t3.sigortakalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno)) - (SUM(TRUNC(t3.sigortakalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno))
              ELSE TRUNC(t3.sigortakalem, 2)
          END                                                                           AS sigorta           -- Kaleme dağıtılmış sigorta
        , t3.teminat
        , t3.teminat_turu
        , t3.ticaret_ulke
        , t3.sevk_ulke
        , t3.mense_ulke
        , t3.gidecegi_ulke
        , t3.cikis_ulke
        , t3.varis_ulke
        , t3.bankadi
        , t3.odeme_sekli
        , t3.esya_yer
        , t3.antrepo_kodu
        , t3.olcu_miktari
        , t3.olcu_birimi
        , t3.fiyat
        , t3.istatistik_tutar_tl_kalem
        , t3.komisyon                                                                   -- Kalem komisyonu
        , t3.demuraj
        , CASE t3.kalemsayi
              WHEN 1
              THEN TRUNC(t3.kalem_royal, 2) + (SUM(ROUND(t3.kalem_royal, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno)) - (SUM(TRUNC(t3.kalem_royal, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno))
              ELSE TRUNC(t3.kalem_royal, 2)
          END                                                                           AS royalty           -- Kaleme dağıtılmış royalty
        , t3.faiz                                                                       -- Kalem faizi
        , CASE t3.kalemsayi
              WHEN 1
              THEN TRUNC(t3.digerkalem, 2) + (SUM(ROUND(t3.digerkalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno)) - (SUM(TRUNC(t3.digerkalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno))
              ELSE TRUNC(t3.digerkalem, 2)
          END                                                                           AS diger             -- Kaleme dağıtılmış diğer (fatura başlık seviyesinden)
        , CASE t3.kalemsayi
              WHEN 1
              THEN TRUNC(t3.ardiyekalem, 2) + (SUM(ROUND(t3.ardiyekalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno)) - (SUM(TRUNC(t3.ardiyekalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno))
              ELSE TRUNC(t3.ardiyekalem, 2)
          END                                                                           AS depolama          -- Kaleme dağıtılmış ardiye
        , CASE t3.kalemsayi
              WHEN 1
              THEN TRUNC(t3.bankakalem, 2) + (SUM(ROUND(t3.bankakalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno)) - (SUM(TRUNC(t3.bankakalem, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno))
              ELSE TRUNC(t3.bankakalem, 2)
          END                                                                           AS bankamasrafi      -- Kaleme dağıtılmış banka masrafı
        , CASE t3.kalemsayi
              WHEN 1
              THEN TRUNC(t3.yurticitop, 2) + (SUM(ROUND(t3.yurticitop, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno)) - (SUM(TRUNC(t3.yurticitop, 2)) OVER(PARTITION BY t3.kalem_no, t3.evrno))
              ELSE TRUNC(t3.yurticitop, 2)
          END                                                                           AS yurtici           -- Kaleme dağıtılmış yurtiçi masraf
        , t3.satici_iliski
        , t3.islem_nitelik
        , t3.sinir_tasima
        , t3.dahili_tasima
        , t3.muaf_1
        , t3.muaf_2
        , t3.muaf_3
        , t3.atr
        , t3.supalan
        , t3.basit_usul
FROM      cte_t3 AS t3
ORDER BY  t3.tescilno
        , t3.tescil_tarihi
;

/*
==========================================================================================================================================================================
SORGU OPTİMİZASYON NOTLARI VE YAPILAN DEĞİŞİKLİKLER (PostgreSQL Dönüşümü)
==========================================================================================================================================================================
Hedef: Informix SQL sorgusunun PostgreSQL'e verimli ve doğru bir şekilde çevrilmesi, performansın maksimize edilmesi.

Yapılan Optimizasyon Adımları ve Değişiklikler:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1.  KAPSAMLI FONKSİYON ELİMİNASYONU VE SET TABANLI YAKLAŞIM:
    Sorgu içerisinde satır bazlı çalışan çok sayıda Informix UDF (Kullanıcı Tanımlı Fonksiyon) çağrısı tespit edildi.
    Bu fonksiyonların tamamına yakını, PostgreSQL'in set tabanlı işlem yeteneklerinden faydalanmak amacıyla standart SQL
    JOIN (INNER JOIN, LEFT JOIN) ve LATERAL JOIN yapılarına dönüştürüldü. Bu, PostgreSQL sorgu planlayıcısının
    JOIN sıralamaları, erişim metotları ve genel strateji üzerinde daha fazla kontrol sahibi olmasını sağlayarak
    satır başına fonksiyon çağırma (context switching) yükünü ortadan kaldırdı.

2.  LOOKUP TABLO ERİŞİMLERİNİN KONSOLİDE EDİLMESİ (LATERAL JOIN İLE BİRLEŞTİRME):
    Aynı lookup tablolarına birden fazla kez yapılan ayrı JOIN erişimleri, performans ve okunabilirlik açısından
    tek bir LATERAL JOIN altında birleştirildi:
    a.  `genel.genulke` Erişimi (Ülke Adları):
        -   Önceki Durum: `fn_ulke` fonksiyonuna yapılan çok sayıda çağrı (ticaret ülkesi, sevk ülkesi, menşe ülkesi vb. için),
            başlangıçta `genel.genulke` tablosuna yapılan birden fazla ayrı `LEFT JOIN` olarak çevrilmişti.
        -   Optimizasyon: Bu çoklu `LEFT JOIN`'ler, `genel.genulke` tablosuna dış sorgudaki her satır için tek bir mantıksal
            erişim yapan tek bir `LEFT JOIN LATERAL` (`_ulke` alias'ı ile) yapısına dönüştürüldü. İlgili ülke adları,
            bu LATERAL JOIN içinde `MAX(CASE WHEN gu.ulkekod = ... THEN gu.adi END)` gibi koşullu agregasyon ifadeleriyle alındı.
            Bu, `genel.genulke` tablosu üzerindeki PK indeksinin (`u149_295`) `ulkekod = ANY (ARRAY[...])` koşuluyla verimli
            kullanılmasını sağladı.

    b.  `slz05.genkod` Erişimi (Kod Açıklamaları):
        -   Önceki Durum: `fn_getkodalan` fonksiyonuna yapılan çok sayıda çağrı (ödeme şekli, gümrük, satıcı ilişkisi, işlem niteliği vb. için),
            başlangıçta `slz05.genkod` tablosuna yapılan birden fazla ayrı `LEFT JOIN` olarak çevrilmişti.
        -   Optimizasyon: Bu çoklu `LEFT JOIN`'ler, `slz05.genkod` tablosuna tek bir `LEFT JOIN LATERAL` (`_genkod` alias'ı ile)
            yapısına dönüştürüldü. Bu LATERAL JOIN içinde bir `WITH _ARANANLAR (VALUES ...)` CTE'si kullanılarak aranacak
            `(tip, kod)` çiftleri dinamik olarak oluşturuldu ve `slz05.genkod` tablosuyla `LEFT JOIN` edilerek ilgili açıklamalar
            koşullu agregasyon (`MAX(CASE WHEN ak.tur = ... THEN gk.aciklama END)`) ile alındı. Bu, `slz05.genkod` tablosundaki
            `(tip, kod)` kompozit indeksinin (`idx_genkod_tip_kod`) verimli kullanılmasını sağladı.

3.  SPESİFİK FONKSİYONLARIN DOĞRUDAN SQL YAPILARINA ENTEGRASYONU:
    a.  `slz05.gumbeyanfatdig` Tablosu Erişimleri (`_gbfatdig` LATERAL):
        -   `fn_gum_beyfatdig` (demuraj, ardiye, banka masrafı gibi farklı `tur` kodları için) ve `fn_gum_beyanyurtici`
            (yurtiçi KDV matrahı için `matrahtur = 'KDV'`) fonksiyonları `slz05.gumbeyanfatdig` tablosuna erişiyordu.
        -   Bu fonksiyon çağrıları tamamen kaldırılarak, ilgili tüm tutar hesaplamaları tek bir `LEFT JOIN LATERAL`
            (`_gbfatdig` alias'ı ile) altında, `SUM(CASE WHEN s.tur = ... ELSE 0 END)` ve
            `SUM(CASE WHEN s.matrahtur = ... ELSE 0 END)` gibi koşullu agregasyonlarla birleştirildi.
            LATERAL JOIN içindeki `WHERE` koşulu (`s.tur IN (...) OR s.matrahtur = ...`) sadece ilgili satırların
            işlenmesini sağlayacak şekilde optimize edildi.

    b.  `slz05.gumrejim12` (Rejim Kodu): `slz05.gumbeyanmadde` tablosundan `sirano = 1` koşuluyla rejim bilgilerini alan
        fonksiyon, doğrudan bir `LEFT JOIN` ile sorguya dahil edildi. `COALESCE` kullanılarak `NULL` durumları yönetildi.

    c.  `slz05.gum_kuryeadres('B', ...)` (Banka Adı/Adresi): `slz05.GUMBANKA` tablosundan ilgili banka bilgilerini
        çeken fonksiyon çağrısı, `slz05.GUMBANKA` tablosuna yapılan basit bir `LEFT JOIN` ile değiştirildi.
        SELECT listesinde ilgili alanlar birleştirilerek `bankadi` alanı oluşturuldu.

    d.  `slz05.fn_gum_getfirmakarsiunvan` (Karşı Firma Unvanı): `slz05.gumfirmakarsi` tablosuna yapılan bir `INNER JOIN` ile
        fonksiyon çağrısı elimine edildi.

    e.  `slz05.fn_gum_getstokno` ve `slz05.fn_gum_getstokaciklama` (Stok No/Açıklama): `slz05.gumfirmagtip` tablosuna
        erişen bu iki fonksiyon, tek bir `LEFT JOIN LATERAL` (`_stok` alias'ı ile `LIMIT 1` kullanılarak) birleştirildi.

4.  TEKRARLI FONKSİYON ÇAĞRISININ ENGELLENMESİ (`slz05.get_firmalar`):
    `slz05.get_firmalar` fonksiyonu, WHERE koşulunda `OR` ile birden fazla kez çağrılma potansiyeline sahipti.
    Bu fonksiyon, `cte_t1`'in en başında bir `CROSS JOIN LATERAL` ile tek bir kez çağrılıp sonucu (`_firmalar`)
    `WHERE EXISTS (SELECT 1 FROM unnest(_firmalar.firma) ...)` yapısı içinde kullanılarak tekrarli çağrıların önüne geçildi.

5.  PARAMETRE VE FİLTRE OPTİMİZASYONLARI:
    `WHERE` yan tümcesindeki opsiyonel parametreler için `$param IS NULL OR field = $param` veya
    `$param IS NULL OR field LIKE '%' || $param || '%'` gibi SARGable (indeks kullanımına daha uygun) olmayan durumlar
    hariç, planlayıcının parametre `NULL` olduğunda koşulu daha iyi elemesini sağlayan yapılar tercih edildi.

6.  VERİ TİPİ UYUMLULUĞU VE GEREKSİZ İŞLEMLERİN KALDIRILMASI:
    Informix'teki `CHAR` veri tiplerinden PostgreSQL'deki `VARCHAR`'a geçiş sırasında, verilerin zaten boşluklardan
    arındırıldığı varsayılarak veya ETL sürecinde bu işlem yapıldığı kabul edilerek, sorgu içindeki gereksiz
    `TRIM` fonksiyon çağrıları (özellikle `_genkod` LATERAL'i içinden) kaldırıldı.
    `CAST` operasyonlarının (`::text` gibi) ise sunucu/client collation farkından kaynaklandığı ve kaçınılmaz olduğu kabul edildi.

7.  SORGULAMA PLANI ANALİZİ VE İSTATİSTİK GÜNCELLEME SÜRECİ:
    Tüm optimizasyon süreci boyunca, yapılan her önemli değişiklik sonrası `EXPLAIN (ANALYZE, BUFFERS)` komutuyla
    sorgu planları detaylıca incelendi. İndeks kullanımları, join metotları, satır sayıları, buffer hit oranları
    ve toplam yürütme süreleri analiz edildi.
    Gerekli görülen noktalarda, ilgili tablolar için `ANALYZE` komutu çalıştırılarak PostgreSQL sorgu planlayıcısının
    güncel ve doğru istatistiklere dayanarak karar vermesi sağlandı.
    `MATERIALIZED` CTE kullanımı denendi ancak sonrasında genel performansa katkısı olmadığı veya olumsuz etkilediği
    gözlemlenerek bu direktif kaldırıldı ve planlayıcının kendi kararlarına bırakıldı.

8.  KORUNAN YAPILAR VE KABULLER:
    - `_dogrulama_url` ve `_statu` için `slz05.gumbeyanbilge` tablosuna yapılan iki ayrı `LATERAL JOIN` yapısı,
      her birinin kendi spesifik koşulları ve verimli indeks kullanımları olduğu için bu haliyle korundu.
    - `slz05.gumfirma AS c` tablosuna yapılan `INNER JOIN`, `c` tablosundan doğrudan bir alan seçilmemesine rağmen,
      referans bütünlüğü veya dolaylı bir gereksinim olabileceği düşünülerek ve `EXPLAIN` planında
      çok düşük maliyetli olduğu görüldüğünden şimdilik korundu.

SONUÇ:
Bu kapsamlı optimizasyonlar sonucunda, sorgunun yürütme süresi önemli ölçüde iyileştirilmiş,
PostgreSQL'in modern özelliklerinden etkin bir şekilde faydalanılmış ve sorgu daha sürdürülebilir
bir yapıya kavuşturulmuştur.
==========================================================================================================================================================================
*/