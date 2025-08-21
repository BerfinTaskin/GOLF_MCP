SELECT 
    TO_CHAR(c.tarih, 'DD/MM/YYYY HH24:MI:SS') AS tarih,
    c.belgeno,  
    c.firmaref,  
    ortak.getadresid2kod(c.alisadr) AS gondericiadrkod,  
    TO_CHAR(c.cikistrh, 'DD/MM/YYYY HH24:MI:SS') AS cikistrh,
    alis.unvan AS gonderici,  
    ortak.getadresalan(c.teslimadr, 'unvan') AS alici,  
    c.chweight,  
    c.packmik,  
    c.desi,  
    ortak.getkentname(ortak.getadresid_kent(c.teslimadr)) AS teslimkent,  
    ortak.getlocname(ortak.getadresid_ilce(c.teslimadr)::VARCHAR, 'TR'::VARCHAR) as teslimilce
FROM 
    ortak.krgkons c  
    INNER JOIN ortak.lojdepo depo ON depo.depoid = c.depoid  
    LEFT JOIN ortak.ortcomp cmp ON cmp.compid = c.firmamerkezid  
    LEFT JOIN ortak.ortadres alis ON alis.adresid = c.alisadr  
    LEFT JOIN ortak.ortadres teslim ON teslim.adresid = c.teslimadr 
WHERE 
    c.merkezid = 'CMP-SOLGUM-IST'
    AND c.firmaid = '$firma'
    AND c.tarih BETWEEN cast('$tarih1' as timestamp) AND cast('$tarih2' as timestamp);