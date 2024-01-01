import Config

if config_env() == :prod do
  config :blog_new, BlogNewWeb.Endpoint,
  url: [host: "taylor.gl", port: 80],
  https: [
    port: 443,
    cipher_suite: :compatible,
    keyfile: System.get_env("SSL_KEY_PATH"),
    certfile: System.get_env("SSL_CERT_PATH"),
    transport_options: [socket_opts: [:inet6]]
  ],
  cache_static_manifest: "priv/static/cache_manifest.json"
end
