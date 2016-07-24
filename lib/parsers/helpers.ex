defmodule Feedme.Parsers.Helpers do
  alias Feedme.XmlNode
  alias Timex.Parse.DateTime.Parser

  @date_formats [
    "{RFC1123}",
    "{ISO:Extended}",
    "{D} {Mshort} {YYYY} {h24}:{m} {Zname}", # 1 Jul 2016 12:00 GMT
    "{WDshort} {D} {Mshort} {YYYY} {h24}:{m}:{s} {AM} {Zname}", # Fri 22 Jul 2016 11:25:39 AM CDT
  ]

  def parse_datetime(node), do: parse_datetime(node, "{RFC1123}")
  def parse_datetime(nil, _), do: nil
  def parse_datetime(node, format) do
    case XmlNode.text(node) |> parse_date do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(text) do
    @date_formats
    |> Enum.map(fn f -> Parser.parse(text, f) end)
    |> Enum.find(
    fn {:ok, _} -> true
      {:error, _} -> false
    end)
  end

  def parse_into_struct(document, struct), do: parse_into_struct(document, struct, [])
  def parse_into_struct(nil, _, _), do: nil
  def parse_into_struct(document, struct, ignore) do
    # structs are basically maps
    [_ | string_fields] = Map.keys(struct)
                          |> Enum.reject(&Enum.member?(ignore, &1))

    get_text = fn(name) -> XmlNode.text_for_node(document, name) end

    # try to read all string typed fields from xml into struct
    Enum.reduce string_fields, struct, fn(key, struct) ->
      value = get_text.(key) || Map.get struct, key
      Map.put struct, key, value
    end
  end

  def parse_attributes_into_struct(document, struct), do: parse_attributes_into_struct(document, struct, [])
  def parse_attributes_into_struct(nil, _, _), do: nil
  def parse_attributes_into_struct(node, struct, ignore) do
    [_ | string_fields] = Map.keys(struct)
                          |> Enum.reject(&Enum.member?(ignore, &1))

    get_text = fn(name) -> XmlNode.attr(node, name) end

    Enum.reduce string_fields, struct, fn(key, struct) ->
      value = get_text.(key) || Map.get struct, key
      Map.put struct, key, value
    end
  end
end
