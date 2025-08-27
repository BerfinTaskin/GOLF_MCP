"""Firma beyannameleri GTİP bazında rapor aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response, null_if_empty


class FirmaBeyannameleriGtipResult(BaseModel):
    """Firma beyannameleri GTİP bazında rapor sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def firma_beyannameleri_gtip_bazinda_raporu_getir(
    firma: Annotated[
        str,
        Field(
            description="Firma kodu (örn: 'CMP59BHUBJ1126')",
            examples=["CMP59BHUBJ1126", "CMPBHLFKRMD205"],
        ),
    ],
    tarih1: Annotated[
        str,
        Field(
            description="Başlangıç tarihi YYYY-MM-DD formatında",
            examples=["2025-01-01", "2024-01-01"],
        ),
    ],
    tarih2: Annotated[
        str,
        Field(
            description="Bitiş tarihi YYYY-MM-DD formatında",
            examples=["2025-06-30", "2024-06-01"],
        ),
    ],
    solmazrefno: Annotated[
        str,
        Field(
            description="Solmaz referans numarası (isteğe bağlı)",
            default="",
        ),
    ] = "",
    refnofirma: Annotated[
        str,
        Field(
            description="Firma referans numarası (isteğe bağlı)",
            default="",
        ),
    ] = "",
    tescilno: Annotated[
        str,
        Field(
            description="Tescil numarası (isteğe bağlı)",
            default="",
        ),
    ] = "",
) -> FirmaBeyannameleriGtipResult:
    """Firma beyannameleri için GTİP (Gümrük Tarife İstatistik Pozisyonu) bazında detaylı rapor getir.
    
    Bu araç, firma beyannameleri için şunları içeren GTİP bazlı analiz sağlar:
    - GTİP kodları ve ticari açıklamalar
    - Beyanname ve kalem bilgileri
    - Stok numaraları ve miktar bilgileri
    - Tutar ve döviz bilgileri
    - Ağırlık ve birim bilgileri
    - İstatistiki değerler ve CIF tutarları
    - Vergi ve masraf detayları
    - Ülke bilgileri (menşe, sevk, ticari)
    - Fatura ve dekont bilgileri
    
    Gümrük operasyonları için GTİP bazlı istatistik, analiz ve raporlama
    için kritik öneme sahiptir.
    """
    try:
        params = {
            "$firma": firma,
            "$tarih1": tarih1,
            "$tarih2": tarih2,
            "$solmazrefno": null_if_empty(solmazrefno),
            "$refnofirma": null_if_empty(refnofirma),
            "$tescilno": null_if_empty(tescilno)
        }
        
        df = run_report("tum_sorgular/Firma_Beyannameleri_GTİP_Bazında_Rapor-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Firma Beyannameleri GTİP Bazında Rapor")
        
        return FirmaBeyannameleriGtipResult(**result)
        
    except Exception as e:
        return FirmaBeyannameleriGtipResult(
            rapor_adi="Firma Beyannameleri GTİP Bazında Rapor",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = firma_beyannameleri_gtip_bazinda_raporu_getir