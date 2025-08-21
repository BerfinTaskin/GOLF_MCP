select
	b.evrseri || ' ' || b.evrno sreferans,
	--b.evrseri,
	b.evrno,
	b.referans,
	b.tescilno,
	b.beyan1,
	b.beyan2,
	slz05.gum_getbeyanfatno(b.evrcinsi,b.evrseri,b.evrno) fatnolar,
	CASE
    	WHEN CAST(b.trhtescil AS TEXT) LIKE '%1899%' THEN NULL
    	ELSE TO_CHAR(b.trhtescil, 'YYYY-MM-DD')
	END AS trhtescil_tarih,
	CASE
    	WHEN CAST(b.trhtescil AS TEXT) LIKE '%1899%' THEN NULL
    	ELSE TO_CHAR(b.trhtescil, 'HH24:MI')
	END AS trhtescil_saat,
	b.manifesto,
	b.manifestotrh,
	b.kons_trh,
	b.kons_no,
	b.tutar,
	slz05.infx_decode(b.dovizkod,'YTL','TL',b.dovizkod) as dovizkod,
	b.hd_topcif_usd,
	b.aciklama1,
	slz05.gum_getfirmakarsiunvan(b.firma,b.karsifirma) kunvan,
	slz05.getdurumaciklamasi(b.durum,'') durum,
	b.trhintac,
	slz05.get_solmazsube(b.rplserver) as solmazsube,
	slz05.infx_decode(b.arc_id,0,'HAYIR','EVET') c_arsivlenmis,
	slz05.gum_beyanarac(b.evrcinsi,b.evrseri,b.evrno) arac,
	slz05.get_nakliyeci(b.nakliyeci) nakliyeci,
	b.esyayer
--	c.unvan firmaunvan,
--	b.arc_id,
--	b.evrcinsi,
--	b.evrseri,
--	b.teslimsek,
--	b.kapsayi,
--	b.kalemsayi,
--	b.durumaciklama,
--	b.hd_topcif,
--	b.topnetag,
--	b.topbrutag,
--	b.fatnot,
--	b.firma,
--	b.adddate beyanadddate,
--	b.operasyon,
--	b.aciklama1 kod1,
--	b.aciklama2 kod2,
--	b.aciklama3 kod3,
--	b.rplserver
from
	slz05.gumfirma c,
	slz05.gumbeyanbaslik b
where
	(b.firma in (
	select
		*
	from
		unnest(slz05.get_firmalar('CMP-SOLGUM-IST', '$firma' )))
		or b.faturafirma in (
		select
			*
		from
			unnest(slz05.get_firmalar('CMP-SOLGUM-IST', '$firma' ))))
	and b.firma = c.firma
	AND b.tesciltarih BETWEEN CAST('$tarih1' AS timestamp) AND CAST('$tarih2' AS timestamp)
	and evrno = coalesce ($solmazrefno,
	b.evrno)
	and (referans = coalesce($refnofirma,
	b.referans)
		or b.referans like '%' || coalesce($refnofirma,
		b.referans) || '%')
	and tescilno = coalesce ($tescilno,
	b.tescilno)