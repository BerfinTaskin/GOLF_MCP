CREATE TEMP TABLE tx AS
SELECT 
    b.merkezid, 
    b.firmamerkezid, 
    b.fisid, 
    b.taskid, 
    b.sevktrh, 
    b.adddate, 
    b.tarih, 
    b.aciklama, 
    b.stoknitelik, 
    b.belgeno,
    b.ozkod1, 
    b.firmaref, 
    b.fistip, 
    b.haryon, 
    b.kapsayi, 
    b.musteriid, 
    b.onay, 
    b.alisadr, 
    b.teslimadr, 
    b.iade, 
    b.netag, 
    b.brutag, 
    b.nethac, 
    b.bruthac, 
    CAST('' AS VARCHAR(20)) AS taskno, 
    CAST('' AS VARCHAR(20)) AS sipbelge, 
    CAST(NULL AS DATE) AS siptarih, 
    CAST(0 AS NUMERIC(15,3)) AS sipmik, 
    (
        SELECT trim(ok.aciklama)
        FROM ortak.ortdosyadrm dr 
        LEFT JOIN ortak.ortkod ok ON ok.tip = '23300' AND ok.kod = dr.externalid
        WHERE dr.dosyaid = b.fisid AND dr.durum = 'EIRS'
        LIMIT 1
    ) AS tasiyici,
    (
        SELECT trim(ok.kod)
        FROM ortak.ortdosyadrm dr 
        LEFT JOIN ortak.ortkod ok ON ok.tip = '23300' AND ok.kod = dr.externalid
        WHERE dr.dosyaid = b.fisid AND dr.durum = 'EIRS'
        LIMIT 1
    ) AS tasiyicivn,
    SUM(h.miktar) AS miktar, 
    SUM(CASE WHEN h.barcode = '-' THEN h.miktar ELSE 0 END) AS kap, 
    SUM(h.miktar) - SUM(CASE WHEN h.barcode = '-' THEN h.miktar ELSE 0 END) AS tek, 
    MIN(h.adddate) AS ilkokutma, 
    MAX(h.adddate) AS sonokutma, 
    COUNT(DISTINCT h.itemid) AS skusayi 
FROM ortak.ljdfisbaslik b 
LEFT JOIN ortak.ljdlokhareket h ON b.fisid = h.fisid 
WHERE 
    b.merkezid = 'CMP-SOLGUM-IST'
    AND b.firmamerkezid = '$firma'
    AND b.depoid = '$lojistikdepo'
    AND b.fistip IN ('DGF','GIR','DCF','CIR') 
    AND (
        ('H' = '$harekettur') OR 
        ('H' = '$harekettur' AND b.fistip IN ('DGF','GIR')) OR 
        ('H' = '$harekettur' AND b.fistip IN ('DCF','CIR'))
    )
    AND b.onay = 'X'
    AND b.sevktrh between cast('$tarih1' as timestamp) and cast('$tarih2' as timestamp)
    AND h.carpan <> 0 
GROUP BY 
    b.merkezid, b.firmamerkezid, b.fisid, b.taskid, b.sevktrh, b.adddate, b.tarih, 
    b.aciklama, b.stoknitelik, b.belgeno, b.ozkod1, b.firmaref, b.fistip, b.haryon, 
    b.kapsayi, b.musteriid, b.onay, b.alisadr, b.teslimadr, b.iade, 
    b.netag, b.brutag, b.nethac, b.bruthac;

 
 
CREATE INDEX tx00 ON tx(fisid);
 

 
CREATE INDEX tx01 ON tx(taskid);
 

 
ANALYZE tx;



UPDATE tx
SET 
    taskno   = sub.taskno,
    sipbelge = sub.belgeno,
    siptarih = sub.tarih,
    sipmik   = sub.sipmik
FROM (
    SELECT 
        t.taskid,
        t.taskno,
        b.belgeno,
        b.tarih,
        SUM(m.miktar) AS sipmik
    FROM ortak.orttask t
    JOIN ortak.ljdfisbaslik b ON b.taskid = t.taskid
    JOIN ortak.ljdfismadde m ON m.fisid = b.fisid
    WHERE b.fistip IN ('CSF', 'GSF')
      AND b.tarih between cast('$tarih1' as timestamp) and cast('$tarih2' as timestamp)
    GROUP BY t.taskid, t.taskno, b.belgeno, b.tarih
) sub
WHERE tx.taskid = sub.taskid
  AND tx.taskid <> '-';



 
UPDATE tx
SET sipmik = sub.sipmik
FROM (
    SELECT fisid, SUM(miktar) AS sipmik
    FROM ortak.ljdfismadde
    GROUP BY fisid
) sub
WHERE tx.fisid = sub.fisid
  AND tx.taskid = '-';



SELECT 
    ortak.getcompunvan(x.firmamerkezid) AS firmaunvan,
    x.taskno,
    x.tarih,
    x.belgeno,
    x.ozkod1,
    x.sevktrh,
    x.firmaref,
    x.fistip,
    x.netag,
    x.brutag,
    x.nethac,
    x.bruthac,
    (
        SELECT e.partnerkod 
        FROM ortak.ebscompkod e 
        WHERE e.compid = x.merkezid 
          AND e.partnerid = x.firmamerkezid 
          AND e.compkod = x.musteriid 
          AND e.kodtip = 2000
        LIMIT 1
    ) AS gonalicikod,
    c.unvan AS gonalici,
    ortak.getortkodaciklama(874, x.haryon) AS haryon,
    aa.unvan AS alisadr,
    CASE 
        WHEN x.alisadr IS NULL OR x.alisadr = '-' THEN ''
        ELSE (
            SELECT e.partnerkod 
            FROM ortak.ebscompkod e 
            WHERE e.compid = x.merkezid 
              AND e.partnerid = x.firmamerkezid 
              AND e.compkod = x.alisadr 
              AND e.kodtip = 2002
            LIMIT 1
        )
    END AS alisadrkod,
    ta.unvan AS teslimadr,
    CASE 
        WHEN x.teslimadr IS NULL OR x.teslimadr = '-' THEN ''
        ELSE (
            SELECT e.partnerkod 
            FROM ortak.ebscompkod e 
            WHERE e.compid = x.merkezid 
              AND e.partnerid = x.firmamerkezid 
              AND e.compkod = x.teslimadr 
              AND e.kodtip = 2002
            LIMIT 1
        )
    END AS teslimadrkod,
    x.aciklama,
    x.adddate,
    x.onay,
    ortak.getortkodaciklama(873, x.stoknitelik) AS stoknitelik,
    x.iade,
    x.sipbelge,
    CAST(TO_CHAR(x.siptarih, 'DD/MM/YYYY') AS VARCHAR(10)) AS siptarih,
    x.sipmik,
    x.tasiyici,
    x.tasiyicivn,
    x.kapsayi,
    COALESCE(
        (
            SELECT COUNT(DISTINCT paletid) 
            FROM ortak.ljdlokhareket h 
            WHERE h.fisid = x.fisid 
              AND TRIM(h.paletid) <> '-'
        ), 
        0
    ) AS paletsayi,
    COALESCE(
        (
            SELECT COUNT(DISTINCT paletid) 
            FROM ortak.ljdfispalet fp 
            WHERE fp.fisid = x.fisid 
              AND TRIM(fp.paletid) <> '-'
        ), 
        0
    ) AS tampaletsayi,
    x.skusayi,
    x.miktar,
    x.kap,
    x.tek,
    CAST(TO_CHAR(x.ilkokutma, 'DD.MM.YYYY HH24:MI') AS VARCHAR(20)) AS ilkokutma,
    CAST(TO_CHAR(x.sonokutma, 'DD.MM.YYYY HH24:MI') AS VARCHAR(20)) AS sonokutma
FROM tx x
LEFT JOIN ortak.ortcomp c ON c.compid = x.musteriid
LEFT JOIN ortak.ortadres aa ON aa.adresid = x.alisadr
LEFT JOIN ortak.ortadres ta ON ta.adresid = x.teslimadr
ORDER BY 1, 2, 3;

