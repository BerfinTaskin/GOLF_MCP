"""Kümülatif depo hareket raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response


class CumulativeMovementResult(BaseModel):
    """Kümülatif depo hareket raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def kumulatif_depo_hareket_raporu_getir(
    firma: Annotated[
        str,
        Field(
            description="Firma kodu (örn: 'CMPBHLFKRMD205')",
            examples=["CMPBHLFKRMD205", "CMP59BHUBJ1126"],
        ),
    ],
    lojistikdepo: Annotated[
        str,
        Field(
            description="Lojistik depo kodu (örn: 'DEP421')",
            examples=["DEP421", "DEP217"],
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
    harekettur: Annotated[
        str,
        Field(
            description="Hareket türü filtresi",
            default="H",
            examples=["H", "G", "C"],
        ),
    ] = "H",
) -> CumulativeMovementResult:
    """Belirtilen dönem için kümülatif depo hareketlerini analiz et.
    
    Bu araç, depo hareketlerini kümülatif olarak toplayarak şunları sağlar:
    - Toplam giriş/çıkış miktarları
    - Dönemsel hareket trendleri
    - Ürün bazında kümülatif veriler
    - Net stok değişimleri
    - Hareket oranları ve hızları
    
    Dönemsel analiz, trend takibi ve kapasite planlaması
    için vazgeçilmezdir.
    """
    try:
        params = {
            "$firma": firma,
            "$lojistikdepo": lojistikdepo,
            "$tarih1": tarih1,
            "$tarih2": tarih2,
            "$harekettur": harekettur
        }
        
        df = run_report("tum_sorgular/Kümülatif_Depo_Hareket_Raporu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Kümülatif Depo Hareket Raporu")
        
        return CumulativeMovementResult(**result)
        
    except Exception as e:
        return CumulativeMovementResult(
            rapor_adi="Kümülatif Depo Hareket Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = kumulatif_depo_hareket_raporu_getir
