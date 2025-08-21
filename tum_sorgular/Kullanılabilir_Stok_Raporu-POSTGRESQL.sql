CREATE TEMP TABLE tmpstok AS
SELECT 
    itemid, 
    stokno, 
    aciklama, 
    birim, 
    rafomru, 
    CASE 
        WHEN rafomrubrm = 'A' THEN rafomru * 30 
        WHEN rafomrubrm = 'G' THEN rafomru 
        ELSE NULL 
    END AS hesrafomru
FROM ortak.lojcompstok st
WHERE st.firmaid = '$firma';



CREATE TEMP TABLE tmpmiz AS
SELECT 
    i.stokno, 
    i.aciklama, 
    i.itemid, 
    SUM(a.miktar) AS miktar, 
    i.birim, 
    ortak.getortkodaciklama(873, b.stoknitelik) AS stoknitelik_tnm, 
    b.stoknitelik, 
    CASE 
        WHEN (DATE(p.proddate) + i.hesrafomru < CURRENT_DATE) THEN '-' 
        ELSE 'X' 
    END AS rafomru, 
    ortak.getortkodaciklama(884, p.paletnitelik) AS pltnitelik, 
    p.paletnitelik
FROM ortak.lojcompstokmiz a
JOIN ortak.lojdepolok b ON b.depoid = a.depoid AND b.lokid = a.lokid
JOIN tmpstok i ON i.itemid = a.itemid
LEFT JOIN ortak.lojpack j ON j.packid = a.packid
LEFT JOIN ortak.lojpalet p ON p.paletid = a.paletid
WHERE 
    a.firmaid = '$firma' 
    AND a.depoid = '$lojistikdepo' 
    AND a.merkezid = 'CMP-SOLGUM-IST' 
    AND a.lokid > '-'
GROUP BY 
    i.stokno, 
    i.aciklama, 
    i.itemid, 
    i.birim, 
    ortak.getortkodaciklama(873, b.stoknitelik), 
    b.stoknitelik, 
    CASE 
        WHEN (DATE(p.proddate) + i.hesrafomru < CURRENT_DATE) THEN '-' 
        ELSE 'X' 
    END,
    ortak.getortkodaciklama(884, p.paletnitelik), 
    p.paletnitelik;



CREATE TEMP TABLE tmpbloke AS
SELECT 
    sm.itemid, 
    SUM(sm.miktar - COALESCE(dm.rfmiktar, 0)) AS toplam
FROM ortak.ljdfisbaslik sf
JOIN ortak.ljdfismadde sm 
    ON sm.fisid = sf.fisid
JOIN tmpstok ss 
    ON sm.itemid = ss.itemid
LEFT JOIN ortak.ljdfisbaslik df 
    ON df.taskid = sf.taskid 
   AND df.firmamerkezid = '$firma'
   AND (df.fistip = 'CIR' OR df.fistip = 'DCF') 
   AND df.depoid = '$lojistikdepo' 
   AND df.merkezid = 'CMP-SOLGUM-IST'
LEFT JOIN ortak.ljdfismadde dm 
    ON dm.fisid = df.fisid 
   AND dm.itemid = sm.itemid
WHERE 
    sf.firmamerkezid = '$firma'
    AND sf.fistip = 'CSF' 
    AND sf.durumtip = 'A' 
    AND sf.iptal = '-' 
    AND sf.onay = 'X' 
    AND sf.depoid = '$lojistikdepo' 
    AND sf.merkezid = 'CMP-SOLGUM-IST'
GROUP BY sm.itemid;



CREATE TEMP TABLE tmpstokrap AS
SELECT 
    s.stokno, 
    s.aciklama,
    s.birim, 

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.stoknitelik = 'N' AND m.rafomru = 'X'), 0) AS normalmik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.stoknitelik = 'X' AND m.rafomru = 'X'), 0) AS adetlimik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.stoknitelik = 'G' AND m.rafomru = 'X'), 0) AS hasarlimik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.stoknitelik = 'H' AND m.rafomru = 'X'), 0) AS hurdamik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.stoknitelik = 'C' AND m.rafomru = 'X'), 0) AS karantimik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.stoknitelik = 'U' AND m.rafomru = 'X'), 0) AS numunemik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.stoknitelik = '7' AND m.rafomru = 'X'), 0) AS stokfarkmik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid), 0) AS mizanmik,

    COALESCE((SELECT SUM(miktar) 
              FROM tmpmiz m 
              WHERE m.itemid = s.itemid AND m.rafomru = '-'), 0) AS rafomrugecenmik,

    COALESCE((SELECT SUM(toplam) 
              FROM tmpbloke b 
              WHERE b.itemid = s.itemid), 0) AS rezervmik

FROM tmpstok s;



SELECT 
    stokno,
    aciklama,
    normalmik,
    adetlimik,
    hasarlimik,
    hurdamik,
    karantimik,
    numunemik,
    stokfarkmik,
    rafomrugecenmik,
    (mizanmik - rafomrugecenmik - normalmik) AS digermizanmik,
    birim,
    rezervmik,
    (normalmik - rezervmik) AS kullanmik,
    mizanmik
FROM tmpstokrap;
