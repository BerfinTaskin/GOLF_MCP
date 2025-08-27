"""Beyanname işlem süreleri rapor aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response, null_if_empty


class DeclarationProcessingTimesResult(BaseModel):
    """Beyanname işlem süreleri sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def beyanname_islem_surelerini_getir(
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
) -> DeclarationProcessingTimesResult:
    """Beyanname işlem sürelerini ve zaman analizini getir.
    
    Bu araç, gümrük beyannameleri için detaylı işlem süreleri ve zaman analizi sağlar:
    - Tescil tarihi ve saati
    - İş emri tarihi
    - Beyanname kapama tarihi
    - Veznede tarihi
    - Sevk tarihi
    - Eşya sevk süresi (tescil ile sevk arasındaki gün)
    - Fatura kesim tarihi
    - Hat durumu (Kırmızı, Sarı, Mavi, Yeşil)
    - Statü ve ek açıklamalar
    - Gümrük idaresi bilgisi
    - Fatura bilgileri (no, tarih, tutar, döviz)
    
    Operasyon verimliliği, süreç analizi ve müşteri hizmet kalitesi ölçümü
    için kritik verileri sağlar.
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
        
        df = run_report("tum_sorgular/Beyanname_İşlem_Süreleri_Raporu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "Beyanname İşlem Süreleri Raporu")
        
        return DeclarationProcessingTimesResult(**result)
        
    except Exception as e:
        return DeclarationProcessingTimesResult(
            rapor_adi="Beyanname İşlem Süreleri Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = beyanname_islem_surelerini_getir
