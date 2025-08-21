"""Gümrük ve lojistik operasyonları için arşiv verileri rapor aracı."""

from typing import Annotated, Optional, Dict, Any
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response, null_if_empty


class ArchiveDataResult(BaseModel):
    """Arşiv verileri sorgusu sonucu."""
    
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
            examples=["2024-01-01", "2025-01-01"],
        ),
    ],
    tarih2: Annotated[
        str,
        Field(
            description="Bitiş tarihi YYYY-MM-DD formatında",
            examples=["2024-06-01", "2025-06-30"],
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
) -> ArchiveDataResult:
    """Bir firma için belirtilen tarih aralığındaki arşiv verilerini getir.
    
    Bu araç, belirli bir firma için belirtilen tarih aralığında
    arşivlenmiş gümrük ve lojistik verilerini alır. Referans numaraları
    ve tescil numaraları kullanarak isteğe bağlı filtreler uygulanabilir.
    
    Şunları içeren yapılandırılmış veri döndürür:
    - Firma arşiv kayıtları
    - Belge bilgileri
    - İşlem tarihleri ve durumları
    - Referans numaraları ve tesciller
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
        
        return ArchiveDataResult(**result)
        
    except Exception as e:
        return ArchiveDataResult(
            rapor_adi="Arşiv Verileri Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = arsiv_verilerini_getir
