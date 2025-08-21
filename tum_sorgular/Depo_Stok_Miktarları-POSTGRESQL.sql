CREATE TEMP TABLE tmp_depostok AS
SELECT 
    b.lokkod,
    b.unvan,
    k.kapno,
    '<' || TRIM(k.depokapno) || '>' AS depokapno,
    i.stokno,
    i.aciklama,
    i.barcode,
    i.kstokno,
    CASE
        WHEN '$firma' = 'CMP5KZFDYD1112' THEN
            CASE 
                WHEN (k.expdate::DATE - CURRENT_DATE) < 0 THEN
                    'İmha, Son kullanma tarihi ' || (k.expdate::DATE - CURRENT_DATE) || ' gün geçmiştir.'
                WHEN (k.expdate::DATE - CURRENT_DATE) BETWEEN 0 AND 90 THEN
                    'İmha, Son kullanma tarihi ' || (k.expdate::DATE - CURRENT_DATE) || ' gün kalmıştır.'
                WHEN (k.expdate::DATE - CURRENT_DATE) BETWEEN 91 AND 180 THEN
                    'Bloke, Son kullanma tarihi ' || (k.expdate::DATE - CURRENT_DATE) || ' gün kalmıştır.'
                WHEN (k.expdate::DATE - CURRENT_DATE) BETWEEN 181 AND 365 THEN
                    '6 ay ile 12 ay arasında olanların, Son kullanma tarihine ' || (k.expdate::DATE - CURRENT_DATE) || ' gün kalmıştır.'
                ELSE ''
            END
        ELSE 
            REPLACE(REPLACE(SUBSTRING(i.bilgi FROM 1 FOR 2000), CHR(10), ''), CHR(13), '')
    END AS bilgi,
    CASE
        WHEN '$firma' = 'CMP5KZFDYD1112' THEN
            CASE 
                WHEN (k.expdate::DATE - CURRENT_DATE) < 0 THEN RIGHT('İmha', 20)
                WHEN (k.expdate::DATE - CURRENT_DATE) BETWEEN 0 AND 90 THEN RIGHT('İmha', 20)
                WHEN (k.expdate::DATE - CURRENT_DATE) BETWEEN 91 AND 180 THEN RIGHT('Bloke', 20)
                WHEN (k.expdate::DATE - CURRENT_DATE) BETWEEN 181 AND 365 THEN RIGHT('6 ay ile 12 ay arasında olanların', 34)
                ELSE ''
            END
        WHEN '$firma' = 'CMP84HLHHS111W' THEN
            CASE
                WHEN a.miktar <= 12 THEN 'Stoğumuzda ' || a.miktar::int::text || ' adet kalmıştır.'
                ELSE ''
            END
        ELSE 
            REPLACE(REPLACE(SUBSTRING(i.bilgi FROM 1 FOR 2000), CHR(10), ''), CHR(13), '')
    END AS kisabilgi,
    j.level,
    a.packmik,
    j.packcode,
    a.miktar::numeric(15,3)::int AS miktar,
    i.birim,
    (i.netag * a.miktar) AS stokag,
    z.unvan AS zonekod,
    ortak.getortkodaciklama(873, b.stoknitelik) AS stoknitelik,
    k.emanetno,
    k.siparisno,
    TRIM(p.paletkod) AS paletkod,
    k.uretimyeri,
    CASE 
        WHEN '$firma' = 'CMP5KZFDYD1112' THEN TO_CHAR(k.proddate, 'DD.MM.YYYY')
        WHEN '$firma' = 'CMP7WRJMMT313X' THEN TO_CHAR(p.proddate, 'DD-MM-YYYY')
        ELSE TO_CHAR(k.proddate, 'YYYY-MM-DD')
    END AS proddate,
    CASE 
        WHEN '$firma' = 'CMP5KZFDYD1112' THEN TO_CHAR(k.expdate, 'DD.MM.YYYY')
        WHEN '$firma' = 'CMP7WRJMMT313X' THEN TO_CHAR(p.expdate, 'DD-MM-YYYY')
        ELSE TO_CHAR(k.expdate, 'YYYY-MM-DD')
    END AS expdate,
    CASE 
        WHEN '$firma' = 'CMP5KZFDYD1112' THEN '<' || TRIM(k.madalan2) || '>'
        ELSE k.lotno
    END AS klotno,
    CASE WHEN '$firma' = 'CMP9SEGN07J1T5' THEN k.madalan1 ELSE NULL END AS kserino,
    CASE WHEN '$firma' = 'CMP9SEGN07J1T5' THEN p.madalan1 ELSE NULL END AS pserino,
    k.madalan3, k.madalan4, k.madalan5, k.madalan6,
    k.madalan7, k.madalan8, k.madalan9, k.madalan10,
    p.palettipi,
    p.madalan2 AS lotno,
    p.lotno AS paletlot,
    p.proddate AS pal_proddate,
    p.expdate AS pal_expdate,
    p.gumstat AS palgumstat,
    CASE 
        WHEN p.teslimadr = '-' THEN ''
        ELSE (SELECT a.adreskod FROM ortak.ortadres a WHERE a.adresid = p.teslimadr)
    END AS palteslimadr,
    i.urungrup,
    i.marka,
    i.oz1, i.oz2, i.oz3, i.oz4, i.oz5,
    i.oz6, i.oz7, i.oz8, i.oz9, i.oz10,
    (p.expdate::DATE - i.rafomru) AS trhrafomur,
    (p.expdate::DATE - i.rafomru) - CURRENT_DATE AS kalansure,
    i.rafomru,
    i.rafomrubrm,
    (p.expdate::DATE - CURRENT_DATE) AS sonkalantrh,
    p.paletnitelik,
    a.kapid,
    ortak.getortkodaciklama(886, i.mesajkod) AS mesajkod
FROM ortak.lojcompstokmiz a
JOIN ortak.lojdepolok b 
    ON b.depoid = a.depoid AND b.lokid = a.lokid
JOIN ortak.lojcompstok i 
    ON i.itemid = a.itemid AND i.firmaid = '$firma'
LEFT JOIN ortak.lojpack j 
    ON j.packid = a.packid
LEFT JOIN ortak.ljdkap k 
    ON k.kapid = a.kapid
LEFT JOIN ortak.lojpalet p 
    ON p.paletid = a.paletid
    AND (COALESCE($paletno, '') = '' OR p.paletid = $paletno)
LEFT JOIN ortak.lojzone z 
    ON b.zoneid = z.zoneid
    AND ('' = '' OR z.zoneid = '')
WHERE 
    TRIM(a.lokid) <> '-' 
    AND a.depoid = '$lojistikdepo'
    AND a.firmaid = '$firma'
    AND ('$firma' != 'CMPALKAC5J4121' OR b.lokkod <> 'SAYFARK');



CREATE TEMP TABLE stok_sertifika AS
WITH target_parent AS (
  SELECT ortak.DYS_GetFileID(
    UPPER('LOJİSTİK/') || TRIM(ortak.Loj_GetDepoAlan('DEP216', 'unvan')) || '/' || ortak.GetCompUnvan('$firma') || UPPER('/STOK SERTİFİKA/')
  ) AS parent_id
)
SELECT 
    ls.parentid AS stokdysid,
    ai.arcid,
    split_part(ai.docinfo, '_', 1) AS orderno,
    ly.descrip::INTEGER - 2000 AS yil,
    ls.descrip AS stokno,
    ai.dosyaid AS lotno,
    ai.doctitle AS sertifikano
FROM ortak.dyslevels ls
JOIN target_parent tp ON ls.parentid = tp.parent_id
JOIN ortak.dyslevels ly ON ly.parentid = ls.recordid
JOIN ortak.arcindex ai ON ai.dysid = ly.recordid;



CREATE TEMP TABLE stok_sertifikagrp AS
SELECT 
    stokno,
    lotno,
    STRING_AGG(sertifikano, ',') AS sertifikano
FROM stok_sertifika
GROUP BY stokno, lotno;



SELECT 
    t.*,
    COALESCE(eck.partnerkod, ortak.getortkodaciklama(884, t.paletnitelik)) AS pltnitelik,
    adr.adreskod AS magazakod,
    adr.unvan AS magazaunvan,
    ssg.sertifikano
FROM tmp_depostok t
LEFT JOIN ortak.ebscompkod eck 
    ON eck.compid = 'CMP-SOLGUM-IST'
    AND eck.partnerid = '$firma'
    AND eck.kodtip = 884
    AND eck.compkod = t.paletnitelik
LEFT JOIN stok_sertifikagrp ssg 
    ON ssg.stokno = t.stokno AND ssg.lotno = t.lotno
LEFT JOIN ortak.ljdkap kap 
    ON kap.kapid = t.kapid
LEFT JOIN ortak.ortadres adr 
    ON adr.adresid = kap.teslimadr;