"""İşlemdeki dosyalar raporu aracı."""

from typing import Annotated, Optional
from pydantic import BaseModel, Field
from .common import run_report, format_dataframe_response, null_if_empty


class IslemdekiDosyalarResult(BaseModel):
    """İşlemdeki dosyalar raporu sorgusu sonucu."""
    
    rapor_adi: str
    durum: str
    satir_sayisi: int
    sutunlar: Optional[list] = None
    veri: list
    kesildi: Optional[bool] = False
    toplam_satir: Optional[int] = None
    mesaj: Optional[str] = None


async def islemdeki_dosyalari_getir(
    firma: Annotated[
        str,
        Field(
            description="Firma kodu (örn: 'CMP59BHUBJ1126')",
            examples=["CMP59BHUBJ1126", "CMPBHLFKRMD205"],
        ),
    ],
    solmazrefno: Annotated[
        str,
        Field(
            description="Solmaz referans numarası (isteğe bağlı)",
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
    refnofirma: Annotated[
        str,
        Field(
            description="Firma referans numarası (isteğe bağlı)",
            default="",
        ),
    ] = "",
) -> IslemdekiDosyalarResult:
    """Aktif olarak işlemde olan gümrük dosyalarının detaylı listesini getir.
    
    Bu araç, işlemdeki gümrük dosyaları için şunları içeren kapsamlı bilgileri sağlar:
    - Dosya durumu ve işlem aşaması
    - Beyanname bilgileri ve tescil durumu
    - Fatura numaraları ve tarihleri
    - Satıcı ve gümrük bilgileri
    - Konşimento ve taşıma bilgileri
    - ETA tarihleri ve sevk durumu
    - İşlem süreleri ve tarih takibi
    - Özet beyan numaraları
    - Dosya türü ve arşivlenme durumu
    
    Gümrük operasyonlarında aktif dosya takibi, süreç yönetimi ve
    müşteri bilgilendirme için kritik öneme sahiptir.
    """
    try:
        params = {
            "$firma": firma,
            "$solmazrefno": null_if_empty(solmazrefno),
            "$tescilno": null_if_empty(tescilno),
            "$faturano": null_if_empty(faturano),
            "$refnofirma": null_if_empty(refnofirma)
        }
        
        df = run_report("tum_sorgular/İşlemdeki_Dosyalar_Raporu-POSTGRESQL.sql", params)
        result = format_dataframe_response(df, "İşlemdeki Dosyalar Raporu")
        
        return IslemdekiDosyalarResult(**result)
        
    except Exception as e:
        return IslemdekiDosyalarResult(
            rapor_adi="İşlemdeki Dosyalar Raporu",
            durum="hata",
            satir_sayisi=0,
            veri=[],
            mesaj=f"Sorgu çalıştırılırken hata oluştu: {str(e)}"
        )


# Aracı dışa aktar
export = islemdeki_dosyalari_getir
