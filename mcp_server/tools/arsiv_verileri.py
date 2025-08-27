"""Arşiv verileri raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response, null_if_empty


class ArsivVerileriResult(BaseModel):
    """Arşiv verileri raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def arsiv_verilerini_getir(
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
) -> ArsivVerileriResult:
    """Arşivlenmiş gümrük beyanname verilerinin kapsamlı listesini getir.
    
    Bu araç, arşivlenmiş gümrük beyannameleri için şunları içeren detaylı bilgileri sağlar:
    - Beyanname referans numaraları ve seri bilgileri
    - Tescil numaraları ve tarihleri
    - Fatura numaraları ve detayları
    - Manifesto ve konşimento bilgileri
    - Tutar ve döviz bilgileri
    - CIF değerleri (USD)
    - Müşteri/karşı firma bilgileri
    - Durum ve açıklama bilgileri
    - Nakliyeci ve araç bilgileri
    - Eşya yeri ve teslimat bilgileri
    - Arşivlenme durumu
    - Solmaz şube bilgileri
    
    Geçmiş gümrük operasyonlarının analizi, audit süreçleri ve
    tarihi veri raporlaması için kritik öneme sahiptir.
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
        
        df = run_report("tum_sorgular/Arşiv_Verileri-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Arşiv Verileri Raporu")
        
        return ArsivVerileriResult(**result)
        
    except Exception as e:
        return ArsivVerileriResult(
            rapor_adi="Arşiv Verileri Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = arsiv_verilerini_getir
