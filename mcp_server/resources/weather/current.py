"""Güncel hava durumu kaynağı örneği."""

from datetime import datetime
from typing import Any

from .common import weather_client

# İstemcilerin bu kaynağa erişmek için kullanacağı URI
resource_uri = "havadurumu://guncel"


async def guncel_hava_durumu() -> dict[str, Any]:
    """Varsayılan şehir için güncel hava durumu sağla.

    Bu örnek şunları gösterir:
    1. İç içe kaynak organizasyonu (resources/weather/current.py)
    2. URI parametreleri olmayan kaynak
    3. common.py dosyasından paylaşılan istemciyi kullanma
    """
    # common.py'den paylaşılan hava durumu istemcisini kullan
    hava_durumu_verisi = await weather_client.get_current("İstanbul")

    # Bazı ek veriler ekle
    hava_durumu_verisi.update(
        {
            "zaman": datetime.now().isoformat(),
            "kaynak": "GolfMCP Hava Durumu API",
            "birim": "celsius",
            "sehir": "İstanbul",
        }
    )

    return hava_durumu_verisi


# Giriş noktası fonksiyonunu belirle
export = guncel_hava_durumu
