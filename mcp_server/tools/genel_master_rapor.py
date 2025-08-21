"""Kapsamlı gümrük ve lojistik verileri için genel master rapor aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response, null_if_empty


class GeneralMasterResult(BaseModel):
    """Genel master rapor sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def genel_master_raporu_getir(
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
    faturano: Annotated[
        str,
        Field(
            description="Fatura numarası (isteğe bağlı)",
            default="",
        ),
    ] = "",
) -> GeneralMasterResult:
    """Gümrük ve lojistik operasyonları için kapsamlı master rapor getir.
    
    Bu, şunları içeren tüm operasyonların tam bir görünümünü sağlayan
    birincil kapsamlı rapordur:
    - Gümrük beyannameleri ve işlemler
    - Depo operasyonları ve hareketler
    - Fatura ve finansal veriler
    - Belge takip ve durum
    - Referans numarası çapraz referansları
    - Zaman çizelgesi ve işlem geçmişi
    
    Bu rapor, bir firma için tüm gümrük ve lojistik faaliyetlerini
    izlemek için ana pano görevi görür.
    """
    try:
        params = {
            "$firma": firma,
            "$tarih1": tarih1,
            "$tarih2": tarih2,
            "$solmazrefno": null_if_empty(solmazrefno),
            "$refnofirma": null_if_empty(refnofirma),
            "$tescilno": null_if_empty(tescilno),
            "$faturano": null_if_empty(faturano)
        }
        
        df = run_report("tum_sorgular/Genel_Master_Rapor-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Genel Master Rapor")
        
        return GeneralMasterResult(**result)
        
    except Exception as e:
        return GeneralMasterResult(
            rapor_adi="Genel Master Rapor",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = genel_master_raporu_getir
