CALL ortak.ljd_isemrilistesigiris(
    '$firma'::varchar,
    '$tasktip'::varchar,
    '$durum'::varchar,
    'CMP-SOLGUM-IST'::varchar,
    '$lojistikdepo'::varchar,
    '$tarih1'::date,
    (TO_DATE('$tarih2', 'YYYY-MM-DD') + INTERVAL '1 day')::date,
    '$tarih1'::date,
    (TO_DATE('$tarih2', 'YYYY-MM-DD') + INTERVAL '1 day')::date
);



SELECT
emirdurum,
emirtip,
belgeno,
sevkyeri,
musteri,
hareketyon,
gonderici,
alici,
aciklama,
sipmiktar,
adet as eksik_urun_miktari,
tplmiktar,
sevkmiktar,
sevkkapsayi,
skusayi,
irsno,
emrgelis,
trhemirkapat,
defdahil,
emirteslimtar
FROM tmpanatablo