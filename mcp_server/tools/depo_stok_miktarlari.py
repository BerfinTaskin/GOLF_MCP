"""Depo stok miktarları rapor aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response, null_if_empty


class StockQuantitiesResult(BaseModel):
    """Depo stok miktarları sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def depo_stok_miktarlarini_getir(
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
    paletno: Annotated[
        str,
        Field(
            description="Palet numarası (isteğe bağlı filtre)",
            default="",
        ),
    ] = "",
) -> StockQuantitiesResult:
    """Bir depodaki mevcut stok miktarlarını getir.
    
    Bu araç, belirli bir depo için mevcut stok seviyelerini alır,
    şunları içeren detaylı envanter bilgilerini gösterir:
    - Ürün detayları ve miktarları
    - Palet bilgileri
    - Depolama konumları
    - Stok durumu ve kullanılabilirlik
    
    Gerekirse belirli palet numarasına göre filtrelenebilir.
    """
    try:
        params = {
            "$firma": firma,
            "$lojistikdepo": lojistikdepo,
            "$paletno": null_if_empty(paletno)
        }
        
        df = run_report("tum_sorgular/Depo_Stok_Miktarları-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Depo Stok Miktarları Raporu")
        
        return StockQuantitiesResult(**result)
        
    except Exception as e:
        return StockQuantitiesResult(
            rapor_adi="Depo Stok Miktarları Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = depo_stok_miktarlarini_getir
