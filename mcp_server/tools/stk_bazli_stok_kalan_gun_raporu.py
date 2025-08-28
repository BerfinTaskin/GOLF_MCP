"""STK bazlı stok kalan gün raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response


class StockRemainingDaysResult(BaseModel):
    """STK bazlı stok kalan gün raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def stk_bazli_stok_kalan_gun_raporu_getir(
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
            description="Referans tarihi YYYY-MM-DD formatında",
            examples=["2023-05-01", "2024-01-01"],
        ),
    ],
) -> StockRemainingDaysResult:
    """STK (Stok Kodu) bazında stokların kaç gün yeteceğini analiz et.
    
    Bu araç, mevcut stokların tükenme sürelerini hesaplayarak şunları sağlar:
    - Stok kodu bazında kalan gün hesaplamaları
    - Tükenme tahminleri
    - Kritik stok uyarıları
    - Yeniden sipariş önerileri
    - Stok devir hızları
    
    Stok yönetimi, sipariş planlaması ve tedarik zinciri optimizasyonu
    için kritik önemdedir.
    """
    try:
        params = {
            "$firma": f"'{firma}'",
            "$lojistikdepo": f"'{lojistikdepo}'",
            "$tarih1": f"'{tarih1}'"
        }
        
        df = run_report("tum_sorgular/STK_Bazlı_Stok_Kalan_Gün_Raporu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "STK Bazlı Stok Kalan Gün Raporu")
        
        return StockRemainingDaysResult(**result)
        
    except Exception as e:
        return StockRemainingDaysResult(
            rapor_adi="STK Bazlı Stok Kalan Gün Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = stk_bazli_stok_kalan_gun_raporu_getir
