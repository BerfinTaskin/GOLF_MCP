"""Gün bazlı antrepo stok durumu raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response


class DailyStockStatusResult(BaseModel):
    """Gün bazlı stok durumu raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def gun_bazli_antrepo_stok_durumu_getir(
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
            description="Sorgu tarihi YYYY-MM-DD formatında",
            examples=["2025-01-01", "2024-01-01"],
        ),
    ],
) -> DailyStockStatusResult:
    """Belirli bir tarih için antrepo stok durumunu getir.
    
    Bu araç, belirtilen tarih itibariyle antrepo stok durumunu analiz ederek şunları sağlar:
    - Günlük stok seviyeleri
    - Ürün bazında mevcut miktarlar
    - Depo kapasitesi kullanımı
    - Stok hareketleri özeti
    - Kritik stok uyarıları
    
    Günlük operasyon yönetimi ve kapasite planlaması
    için vazgeçilmezdir.
    """
    try:
        params = {
            "$firma": firma,
            "$lojistikdepo": lojistikdepo,
            "$tarih1": tarih1
        }
        
        df = run_report("tum_sorgular/Gün_Bazlı_Antrepo_Stok_Durumu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Gün Bazlı Antrepo Stok Durumu")
        
        return DailyStockStatusResult(**result)
        
    except Exception as e:
        return DailyStockStatusResult(
            rapor_adi="Gün Bazlı Antrepo Stok Durumu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = gun_bazli_antrepo_stok_durumu_getir
