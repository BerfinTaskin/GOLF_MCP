CREATE TEMP TABLE tmpgunsonu AS
SELECT 
  m.madid,
  m.rfmiktar * m.carpan AS miktar,
  m.rfkap * m.carpan AS kap,
  m.rfagirlik * m.carpan AS agirlik,
  m.rfhacim * m.carpan AS hacim,
  m.ldm * m.carpan AS ldm,
  m.paletadet * m.carpan AS paletadet,
  m.ldm AS girldm,
  m.paletadet AS girpalet
FROM 
  ortak.antdosya s
JOIN 
  ortak.antdosyamad m ON m.dosyaid = s.dosyaid
WHERE 
  s.merkezid = 'CMP-SOLGUM-IST' AND
  s.depoid = '$lojistikdepo' AND
  s.islemtip = 'I' AND
  s.deftertur IN ('GEC', 'ANT', 'MIL') AND
  s.alttip NOT IN ('KAR') AND
  s.tarih <= cast('$tarih1' as timestamp) AND
  m.musteriid = '$firma';


                                                 
INSERT INTO tmpgunsonu (
  madid,
  miktar,
  kap,
  agirlik,
  hacim,
  ldm,
  paletadet,
  girldm,
  girpalet
)
SELECT 
  t.madid,
  x.miktar * x.carpan AS miktar,
  x.kapsayi * x.carpan AS kap,
  x.agirlik * x.carpan AS agirlik,
  x.hacim * x.carpan AS hacim,
  0 AS ldm,
  0 AS paletadet,
  0 AS girldm,
  0 AS girpalet
FROM 
  tmpgunsonu t
JOIN 
  ortak.detdusum x ON x.devmadid = t.madid
JOIN 
  ortak.antdosyamad m ON m.madid = x.fatmadid
JOIN 
  ortak.antdosya d ON d.dosyaid = m.dosyaid
WHERE 
  d.onay = 'X' AND
  d.tarih <= cast('$tarih1' as timestamp);



CREATE TEMP TABLE tmpsonuc1 AS
SELECT 
  RTRIM(madid) AS madid,
  SUM(miktar) AS miktar,
  SUM(kap) AS kap,
  SUM(agirlik) AS agirlik,
  SUM(hacim) AS hacim,
  SUM(ldm) AS ldm,
  SUM(paletadet) AS paletadet,
  SUM(girldm) AS girldm,
  SUM(girpalet) AS girpalet
FROM tmpgunsonu
GROUP BY RTRIM(madid)
HAVING SUM(miktar) > 0;



INSERT INTO tmpsonuc1 (
  madid,
  miktar,
  kap,
  agirlik,
  hacim,
  ldm,
  paletadet,
  girldm,
  girpalet
)
SELECT 
  t.madid,
  0 AS miktar,
  0 AS kap,
  0 AS agirlik,
  0 AS hacim,
  m.ldm * m.carpan AS ldm,
  m.paletadet * m.carpan AS paletadet,
  0 AS girldm,
  0 AS girpalet
FROM 
  tmpsonuc1 t
JOIN 
  ortak.antdosyamad m ON t.madid = m.bagid
WHERE 
  m.rfmiktar > 0;



CREATE TEMP TABLE tmpsonuc AS
SELECT 
  madid,
  SUM(miktar) AS miktar,
  SUM(kap) AS kap,
  SUM(agirlik) AS agirlik,
  SUM(hacim) AS hacim,
  SUM(ldm) AS ldm,
  SUM(paletadet) AS paletadet,
  SUM(girldm) AS girldm,
  SUM(girpalet) AS girpalet
FROM 
  tmpsonuc1
GROUP BY 
  madid
HAVING 
  SUM(miktar) > 0;



SELECT
  d.tescilno,
  TO_CHAR(d.tesciltarih, 'DD/MM/YYYY HH24:MI') AS tesciltarih,
  d.tarih AS giristrh,
  f.dosyano,
  CASE d.deftertur
    WHEN 'GEC' THEN 'GEÇİCİ'
    WHEN 'ANT' THEN 'ANTREPO'
    WHEN 'MIL' THEN 'MİLLİ'
    ELSE d.deftertur
  END AS deftertur,
  ortak.getcompunvan(f.alici) AS alici,
  ortak.getcompunvan(f.gonderici) AS gonderici,
  l.stokno,
  l.aciklama,
  SUM(t.miktar) AS miktar,
  o.aciklama AS birim,
  t.kap,
  ok.aciklama AS kapcinsi,
  t.ldm,
  t.paletadet,
  t.agirlik,
  t.hacim,
  m.rfmiktar AS girmiktar,
  m.rfkap AS girkap,
  t.girldm,
  t.girpalet,
  m.agirlik AS giragirlik,
  (CURRENT_DATE - d.tarih::date) + 1 AS depogun,
  f.arakonsimento,
  m.gtip,
  u.adi AS ulkeadi,
  u.edikod AS ulkeedikod,
  ROUND(SUM((m.istatdeger / NULLIF(m.miktar, 0)) * t.miktar), 1) AS kiẏmet,
  COALESCE(NULLIF(m.kiymetdov, ''), 'USD') AS doviz,
  m.madid,
  d.aciklama AS dosyaaciklama,
  f.tem_tem,
  CASE 
    WHEN m.merkezid = 'CMP-SOLGUM-IST' THEN ortak.ANT_GETILKTESCILNO(m.ilkgirmadid)
    ELSE '-'
  END AS ilkgiris_tescilno,
  SUM(f.istatdeger) AS istatdeger
FROM tmpsonuc t
JOIN ortak.antdosyamad m ON m.madid = t.madid
JOIN ortak.antdosyadef f ON f.defid = m.defid
JOIN ortak.antdosya d ON d.dosyaid = f.dosyaid
JOIN ortak.lojcompstok l ON l.itemid = m.itemid
JOIN ortak.ortkod o ON o.tip = 12 AND o.kod = m.birim
JOIN ortak.ortkod ok ON ok.tip = 66 AND ok.kod = m.kapcinsi
LEFT JOIN ortak.ortulke u ON u.ulkeid = m.menseulke
GROUP BY 
  d.tescilno,
  d.tesciltarih,
  d.tarih,
  f.dosyano,
  d.deftertur,
  f.alici,
  f.gonderici,
  l.stokno,
  l.aciklama,
  o.aciklama,
  t.kap,
  ok.aciklama,
  t.ldm,
  t.paletadet,
  t.agirlik,
  t.hacim,
  m.rfmiktar,
  m.rfkap,
  t.girldm,
  t.girpalet,
  m.agirlik,
  d.tarih,
  f.arakonsimento,
  m.gtip,
  u.adi,
  u.edikod,
  m.kiymetdov,
  m.madid,
  d.aciklama,
  f.tem_tem,
  m.merkezid,
  m.ilkgirmadid;
