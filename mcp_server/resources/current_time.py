"""Güncel zaman kaynağı örneği."""

from datetime import datetime
from typing import Any

# İstemcilerin bu kaynağa erişmek için kullanacağı URI
resource_uri = "sistem://zaman"


async def guncel_zaman() -> dict[str, Any]:
    """Çeşitli formatlarda güncel zamanı sağla.

    Bu, tüm formatlarda zamanı döndüren basit bir kaynak örneğidir.
    """
    simdi = datetime.now()

    # Tüm olası formatları hazırla
    tum_formatlar = {
        "iso": simdi.isoformat(),
        "rfc": simdi.strftime("%a, %d %b %Y %H:%M:%S %z"),
        "unix": int(simdi.timestamp()),
        "formatli": {
            "tarih": simdi.strftime("%Y-%m-%d"),
            "saat": simdi.strftime("%H:%M:%S"),
            "saat_dilimi": simdi.astimezone().tzname(),
        },
        "turkce": {
            "tarih": simdi.strftime("%d.%m.%Y"),
            "saat": simdi.strftime("%H:%M:%S"),
            "tam": simdi.strftime("%d %B %Y, %H:%M:%S"),
        },
    }

    # Tüm formatları döndür
    return tum_formatlar


# Giriş noktası fonksiyonunu belirle
export = guncel_zaman
