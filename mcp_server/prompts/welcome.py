"""Yeni kullanıcılar için hoş geldin prompt'u."""


async def hosgeldin() -> list[dict]:
    """Yeni kullanıcılar için hoş geldin prompt'u sağla.

    Bu, GolfMCP'de bir prompt şablonunun nasıl tanımlanacağını
    gösteren basit bir örnek prompt'dur.
    """
    return [
        {
            "role": "system",
            "content": (
                "Sen Akıllı GMCP Raporlar uygulaması için bir asistansın. "
                "Kullanıcıların bu sistemle nasıl etkileşim kuracağını ve "
                "yeteneklerini anlamalarına yardımcı oluyorsun. "
                "Bu sistem gümrük ve lojistik operasyonları için veritabanı raporlama araçları sağlar."
            ),
        },
        {
            "role": "user",
            "content": (
                "Akıllı GMCP Raporlar sistemine hoş geldiniz! Bu GolfMCP ile geliştirilmiş bir projedir. "
                "Gümrük ve lojistik operasyonlarınız için detaylı raporlar alabilirsiniz. "
                "Nasıl başlayabilirim?"
            ),
        },
    ]


# Giriş noktası fonksiyonunu belirle
export = hosgeldin
