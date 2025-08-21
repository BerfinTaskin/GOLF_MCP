"""Proje hakkında bilgi sağlayan örnek kaynak."""

import platform
from datetime import datetime
from typing import Any

resource_uri = "info://sistem"


async def bilgi() -> dict[str, Any]:
    """Kaynak olarak sistem bilgisi sağla.

    Bu, MCP protokolü aracılığıyla bir LLM istemcisine
    verilerin nasıl açığa çıkarılacağını gösteren basit bir örnek kaynaktır.
    """
    return {
        "proje": "akilli_gmcp_raporlar",
        "zaman_damgasi": datetime.now().isoformat(),
        "platform": {
            "sistem": platform.system(),
            "python_surumu": platform.python_version(),
            "mimari": platform.machine(),
        },
        "aciklama": "Gümrük ve lojistik operasyonları için akıllı rapor sistemi",
        "versiyon": "1.0.0"
    }


# Giriş noktası fonksiyonunu belirle
export = bilgi
