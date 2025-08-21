"""Gönderi sorgulama lokasyon raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response


class ShipmentLocationResult(BaseModel):
    """Gönderi lokasyon raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def gonderi_sorgulama_lokasyon_raporu_getir(
    firma: Annotated[
        str,
        Field(
            description="Firma kodu (örn: 'CMP84HLHHS111W')",
            examples=["CMP84HLHHS111W", "CMP59BHUBJ1126"],
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
) -> ShipmentLocationResult:
    """Gönderi sorgulama ve lokasyon takip raporu getir.
    
    Bu araç, gönderilerin konumlarını ve durumlarını takip ederek şunları sağlar:
    - Gönderi konum bilgileri
    - Taşıma durumu ve aşamaları
    - Teslimat zamanlamaları
    - Rota ve güzergah bilgileri
    - Lokasyon geçmişi
    
    Lojistik süreç yönetimi ve müşteri bilgilendirmesi
    için kritik önemdedir.
    """
    try:
        params = {
            "$firma": firma,
            "$tarih1": tarih1,
            "$tarih2": tarih2
        }
        
        df = run_report("tum_sorgular/Gönderi_Sorgulama_Lokasyon_Raporu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Gönderi Sorgulama Lokasyon Raporu")
        
        return ShipmentLocationResult(**result)
        
    except Exception as e:
        return ShipmentLocationResult(
            rapor_adi="Gönderi Sorgulama Lokasyon Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = gonderi_sorgulama_lokasyon_raporu_getir
