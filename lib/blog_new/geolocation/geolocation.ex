defmodule BlogNew.Geolocation do
  alias Geolix.Adapter.MMDB2.{Record, Result}

  def is_user_from_australia?(remote_ip) do
    case Geolix.lookup(remote_ip) do
      %{geolite2_country: %Result.Country{country: %Record.Country{iso_code: "AU"}}} -> true
      _ -> false
    end
  end
end
