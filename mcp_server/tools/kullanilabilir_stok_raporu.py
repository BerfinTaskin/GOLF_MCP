"""Kullanılabilir stok raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response


class AvailableStockResult(BaseModel):
    """Kullanılabilir stok raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def kullanilabilir_stok_raporu_getir(
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
) -> AvailableStockResult:
    """Kullanılabilir stok durumunu analiz et.
    
    Bu araç, mevcut stoklardan kullanılabilir olanları belirleyerek şunları sağlar:
    - Serbest kullanılabilir stok miktarları
    - Rezerve edilmiş stoklar
    - Bloke edilmiş stoklar
    - Kullanılabilirlik durumları
    - Stok kalitesi bilgileri
    
    Sipariş karşılama, satış planlaması ve stok optimizasyonu
    için kritik önemdedir.
    """
    try:
        params = {
            "$firma": firma,
            "$lojistikdepo": lojistikdepo
        }
        
        df = run_report("tum_sorgular/Kullanılabilir_Stok_Raporu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Kullanılabilir Stok Raporu")
        
        return AvailableStockResult(**result)
        
    except Exception as e:
        return AvailableStockResult(
            rapor_adi="Kullanılabilir Stok Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = kullanilabilir_stok_raporu_getir
