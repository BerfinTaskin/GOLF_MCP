"""Temel Golf MCP sunucu örneği için kimlik doğrulama yapılandırması.

Bu örnek Golf 0.2.x'te mevcut farklı kimlik doğrulama seçeneklerini gösterir:
- Statik anahtarlar veya JWKS uç noktaları ile JWT kimlik doğrulaması (üretim)
- Statik token kimlik doğrulaması (geliştirme/test)
- OAuth Server modu (tam OAuth 2.0 sunucusu)
- Uzak Yetkilendirme Sunucusu entegrasyonu
"""

# Örnek 1: Statik genel anahtar ile JWT kimlik doğrulaması
# from golf.auth import configure_auth, JWTAuthConfig
#
# configure_auth(
#     JWTAuthConfig(
#         public_key_env_var="JWT_PUBLIC_KEY",  # PEM kodlu genel anahtar
#         issuer="https://your-auth-server.com",
#         audience="https://your-golf-server.com",
#         required_scopes=["read:data"],
#     )
# )

# Örnek 2: JWKS ile JWT kimlik doğrulaması (üretim için önerilen)
# from golf.auth import configure_auth, JWTAuthConfig
#
# configure_auth(
#     JWTAuthConfig(
#         jwks_uri_env_var="JWKS_URI",        # örn., "https://your-domain.auth0.com/.well-known/jwks.json"
#         issuer_env_var="JWT_ISSUER",        # örn., "https://your-domain.auth0.com/"
#         audience_env_var="JWT_AUDIENCE",    # örn., "https://your-api.example.com"
#         required_scopes=["read:user"],
#     )
# )

# Örnek 3: OAuth Server modu - Golf tam OAuth 2.0 yetkilendirme sunucusu olarak çalışır
# from golf.auth import configure_auth, OAuthServerConfig
#
# configure_auth(
#     OAuthServerConfig(
#         base_url_env_var="OAUTH_BASE_URL",          # örn., "https://auth.example.com"
#         valid_scopes=["read", "write", "admin"],    # İstemcilerin talep edebileceği kapsamlar
#         default_scopes=["read"],                    # Yeni istemciler için varsayılan kapsamlar
#         required_scopes=["read"],                   # Tüm istekler için gerekli kapsamlar
#     )
# )

# Örnek 4: Uzak Yetkilendirme Sunucusu entegrasyonu
# from golf.auth import configure_auth, RemoteAuthConfig, JWTAuthConfig
#
# configure_auth(
#     RemoteAuthConfig(
#         authorization_servers_env_var="AUTH_SERVERS",    # Virgülle ayrılmış: "https://auth1.com,https://auth2.com"
#         resource_server_url_env_var="RESOURCE_URL",     # Bu sunucunun URL'si
#         token_verifier_config=JWTAuthConfig(
#             jwks_uri_env_var="JWKS_URI"
#         ),
#     )
# )

# Örnek 5: Geliştirme için statik token kimlik doğrulaması (üretimde KULLANMAYIN)
from golf.auth import configure_auth, StaticTokenConfig

configure_auth(
    StaticTokenConfig(
        tokens={
            "dev-token-123": {
                "client_id": "dev-client",
                "scopes": ["read", "write"],
            },
            "admin-token-456": {
                "client_id": "admin-client",
                "scopes": ["read", "write", "admin"],
            },
        },
        required_scopes=["read"],
    )
)
