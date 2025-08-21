"""Detaylı depo hareket raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response


class WarehouseMovementResult(BaseModel):
    """Detaylı depo hareket sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def detayli_depo_hareketlerini_getir(
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
            description="Lojistik depo kodu (örn: 'DEP217')",
            examples=["DEP217", "DEP421"],
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
    onaytip: Annotated[
        str,
        Field(
            description="Onay türü filtresi",
            default="H", 
            examples=["H", "O", "R"],
        ),
    ] = "H",
) -> WarehouseMovementResult:
    """Belirli bir dönem için detaylı depo hareket kayıtlarını getir.
    
    Bu araç şunları içeren kapsamlı depo hareket verilerini alır:
    - Gelen ve giden hareketler
    - Ürün transferleri ve yer değişiklikleri
    - Hareket tarihleri ve miktarları
    - Onay durumları ve türleri
    - Belge referansları ve takip
    
    Envanter değişikliklerini takip etmek, depo operasyonlarını denetlemek
    ve ürün akış modellerini analiz etmek için kullanışlıdır.
    """
    try:
        params = {
            "$firma": firma,
            "$lojistikdepo": lojistikdepo,
            "$tarih1": tarih1,
            "$tarih2": tarih2,
            "$harekettur": harekettur,
            "$onaytip": onaytip
        }
        
        df = run_report("tum_sorgular/Ayrıntılı_Depo_Hareket_Raporu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Detaylı Depo Hareket Raporu")
        
        return WarehouseMovementResult(**result)
        
    except Exception as e:
        return WarehouseMovementResult(
            rapor_adi="Detaylı Depo Hareket Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = detayli_depo_hareketlerini_getir
