"""İsteğe bağlı LLM destekli açıklamalarla gelişmiş hesap makinesi aracı."""

from typing import Annotated

from pydantic import BaseModel, Field
from golf.utilities import sample


class CalculationResult(BaseModel):
    """Matematiksel hesaplama sonucu."""

    sonuc: float
    islem: str
    ifade: str


async def hesapla(
    ifade: Annotated[
        str,
        Field(
            description="Değerlendirilecek matematiksel ifade (örn: '2 + 3', '10 * 5', '100 / 4')",
            examples=["2 + 3", "10 * 5.5", "(8 - 3) * 2"],
        ),
    ],
    acikla: Annotated[
        bool,
        Field(
            description="LLM destekli adım adım açıklama sağlanıp sağlanmayacağı",
            default=False,
        ),
    ] = False,
) -> CalculationResult:
    """İsteğe bağlı LLM açıklaması ile matematiksel ifade değerlendir.

    Bu gelişmiş hesap makinesi şunları yapabilir:
    - Temel aritmetik işlemleri gerçekleştirir (+, -, *, /, parantezler)
    - Ondalık sayıları işler
    - İsteğe bağlı olarak LLM destekli adım adım açıklamalar sağlar

    Örnekler:
    - hesapla("2 + 3") → 5
    - hesapla("10 * 5.5") → 55.0
    - hesapla("(8 - 3) * 2", acikla=True) → açıklamalı 10
    """
    try:
        # eval kullanarak basit ifade değerlendirmesi (temel matematik için güvenli)
        # Üretimde uygun matematik ifade ayrıştırıcısı kullanmayı düşünün
        izin_verilen_karakterler = set("0123456789+-*/.() ")
        if not all(c in izin_verilen_karakterler for c in ifade):
            raise ValueError("İfade geçersiz karakterler içeriyor")

        # İfadeyi değerlendir
        sonuc = eval(ifade, {"__builtins__": {}}, {})

        # Sonucun bir sayı olduğundan emin ol
        if not isinstance(sonuc, (int, float)):
            raise ValueError("İfade bir sayı olarak değerlendirilemedi")

        # İstenirse açıklama üret
        sonuc_ifadesi = ifade
        if acikla:
            try:
                aciklama = await sample(
                    f"Bu matematiksel ifadeyi adım adım açıkla: {ifade} = {sonuc}",
                    system_prompt="Sen yardımcı bir matematik öğretmenisin. Açık, adım adım açıklamalar sağla.",
                    max_tokens=200,
                )
                sonuc_ifadesi = f"{ifade}\n\nAçıklama: {aciklama}"
            except Exception:
                # Örnekleme başarısız olursa, açıklama olmadan devam et
                sonuc_ifadesi = f"{ifade}\n\n(Açıklama mevcut değil)"

        return CalculationResult(
            sonuc=float(sonuc),
            islem="değerlendir",
            ifade=sonuc_ifadesi,
        )

    except ZeroDivisionError:
        return CalculationResult(
            sonuc=float("inf"),
            islem="hata",
            ifade=f"{ifade} → Sıfıra bölme",
        )
    except Exception as e:
        return CalculationResult(
            sonuc=0.0,
            islem="hata",
            ifade=f"{ifade} → Hata: {str(e)}",
        )


# Aracı dışa aktar
export = hesapla
