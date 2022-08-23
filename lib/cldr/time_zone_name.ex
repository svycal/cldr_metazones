defmodule Cldr.TimeZoneName do
  @moduledoc """
  TODO
  """

  @doc false
  def cldr_backend_provider(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep,
          bind_quoted: [
            module: module,
            backend: backend,
            config: config
          ] do
      defmodule TimeZoneName do
        @moduledoc false
        alias Cldr.LanguageTag
        alias Cldr.Locale

        alias Cldr.TimeZoneName.Info

        # Simpler than unquoting the backend everywhere
        defp backend, do: unquote(backend)
        defp get_locale, do: backend().get_locale()
        defp default_locale, do: backend().default_locale()

        @doc """
        Fetches time zone name info, given a zone name and meta zone.
        """
        @spec resolve(
                zone_name :: Calendar.time_zone(),
                meta_zone :: String.t(),
                opts :: Keyword.t()
              ) ::
                {:ok, Metazone.t()} | {:error, term()}
        def resolve(zone_name, meta_zone, opts \\ []) do
          resolve_by_locale(zone_name, meta_zone, opts[:locale] || get_locale())
        end

        defp resolve_by_locale(zone_name, meta_zone, %LanguageTag{
               cldr_locale_name: cldr_locale_name
             }) do
          resolve_by_locale(zone_name, meta_zone, cldr_locale_name)
        end

        for locale_name <- Locale.Loader.known_locale_names(config) do
          locale_data = Locale.Loader.get_locale(locale_name, config)

          zones =
            locale_data
            |> Map.get(:dates, %{})
            |> Map.get(:time_zone_names, %{})
            |> Map.get(:zone, %{})

          meta_zones =
            locale_data
            |> Map.get(:dates, %{})
            |> Map.get(:time_zone_names, %{})
            |> Map.get(:metazone, %{})

          defp resolve_by_locale(zone_name, meta_zone, unquote(locale_name)) do
            zones = unquote(Macro.escape(zones))
            meta_zones = unquote(Macro.escape(meta_zones))

            zone_name_parts =
              zone_name
              |> String.split("/")
              |> Enum.map(&String.downcase/1)

            zone_data =
              Enum.reduce(zone_name_parts, zones, fn part, acc ->
                Map.get(acc, part, %{})
              end)

            meta_zone_data = meta_zones[meta_zone]

            if meta_zone_data do
              {:ok, Info.new(zone_data, meta_zone_data)}
            else
              {:error, "Metazone type \"#{meta_zone}\" not found"}
            end
          end
        end

        defp resolve_by_locale(_zone_name, _meta_zone, locale),
          do: {:error, Locale.locale_error(locale)}
      end
    end
  end
end
