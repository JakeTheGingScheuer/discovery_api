use Mix.Config

config :discovery_api, DiscoveryApiWeb.Endpoint,
  url: [
    scheme: "https",
    host: System.get_env("HOST"),
    port: 443
  ]

config :discovery_api,
  ldap_user: System.get_env("LDAP_USER"),
  ldap_pass: System.get_env("LDAP_PASS"),
  hosted_bucket: System.get_env("HOSTED_FILE_BUCKET"),
  hosted_region: System.get_env("HOSTED_FILE_REGION")

config :discovery_api, DiscoveryApi.Repo,
  database: System.get_env("POSTGRES_NAME"),
  username: System.get_env("POSTGRES_NAME"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOST"),
  port: System.get_env("POSTGRES_PORT")

required_envars = ["REDIS_HOST", "PRESTO_URL", "ALLOWED_ORIGINS"]

Enum.each(required_envars, fn var ->
  if is_nil(System.get_env(var)) do
    raise ArgumentError, message: "Required environment variable #{var} is undefined"
  end
end)

allowed_origins =
  System.get_env("ALLOWED_ORIGINS")
  |> String.split(",")
  |> Enum.map(&String.trim/1)

secrets_endpoint =
  case System.get_env("SECRETS_ENDPOINT") do
    "" -> nil
    val -> val
  end

config :discovery_api,
  allowed_origins: allowed_origins,
  secrets_endpoint: secrets_endpoint

config :discovery_api,
  jwks_endpoint: System.get_env("AUTH_JWKS_ENDPOINT"),
  user_info_endpoint: System.get_env("AUTH_USER_INFO_ENDPOINT")

config :redix,
  host: System.get_env("REDIS_HOST")

config :smart_city_registry,
  redis: [
    host: System.get_env("REDIS_HOST")
  ]

config :prestige,
  base_url: System.get_env("PRESTO_URL"),
  log_level: :warn

config :paddle, Paddle,
  host: System.get_env("LDAP_HOST"),
  base: System.get_env("LDAP_BASE"),
  account_subdn: System.get_env("LDAP_ACCOUNT_SUBDN")

config :discovery_api, DiscoveryApi.Auth.Guardian, secret_key: System.get_env("GUARDIAN_KEY")

config :discovery_api, DiscoveryApi.Auth.Auth0.Guardian, issuer: System.get_env("AUTH_JWT_ISSUER")

config :ex_aws,
  region: System.get_env("HOSTED_FILE_REGION")

