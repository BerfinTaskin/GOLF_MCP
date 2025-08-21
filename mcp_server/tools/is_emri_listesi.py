"""İş emri listesi raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response


class WorkOrderResult(BaseModel):
    """İş emri listesi raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def is_emri_listesi_getir(
    firma: Annotated[
        str,
        Field(
            description="Firma kodu (örn: 'CMPBHLFKRMD205')",
            examples=["CMPBHLFKRMD205", "CMP59BHUBJ1126"],
        ),
    ],
    tasktip: Annotated[
        str,
        Field(
            description="Görev tipi (örn: 'GSF')",
            examples=["GSF", "GRM", "TSL"],
        ),
    ],
    durum: Annotated[
        str,
        Field(
            description="İş emri durumu (örn: 'H' - Hazır)",
            examples=["H", "T", "K"],
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
) -> WorkOrderResult:
    """Belirtilen kriterlere göre iş emri listesini getir.
    
    Bu araç, iş emirlerini filtreleyerek şunları sağlar:
    - İş emri detayları ve durumları
    - Görev tipleri ve öncelikleri
    - Atanmış personel bilgileri
    - Tamamlanma süreleri
    - Operasyonel metrikler
    
    İş yükü yönetimi, kaynak planlaması ve performans takibi
    için kritik önemdedir.
    """
    try:
        params = {
            "$firma": firma,
            "$tasktip": tasktip,
            "$durum": durum,
            "$lojistikdepo": lojistikdepo,
            "$tarih1": tarih1,
            "$tarih2": tarih2
        }
        
        df = run_report("tum_sorgular/İş_Emri_Listesi-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "İş Emri Listesi")
        
        return WorkOrderResult(**result)
        
    except Exception as e:
        return WorkOrderResult(
            rapor_adi="İş Emri Listesi",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = is_emri_listesi_getir
