defmodule BambooPreview.Plug.Helper do
  def selected_email_class(email_id, selected_email) do
    if _as_atom(email_id) == get_id(selected_email) do
      "selected-email"
    else
      ""
    end
  end

  def email_addresses(email) do
    Bamboo.Email.all_recipients(email)
    |> Enum.map(&Bamboo.Email.get_address/1)
    |> Enum.join(", ")
  end

  def format_headers(values) when is_binary(values), do: values
  def format_headers(values) when is_list(values) do
    Enum.join(values, ", ")
  end
  def format_headers(values), do: inspect(values)

  def format_text(nil), do: ""
  def format_text(text_body) do
    String.replace(text_body, "\n", "<br>")
  end

  def format_email_address({nil, address}), do: address
  def format_email_address({name, address}) do
    "#{name}&lt;#{address}&gt;"
  end
  def format_email_address(address), do: inspect(address)

  def get_id(%Bamboo.Email{private: %{local_adapter_id: id}}) do
    id
  end

  def get_id(_value) do
    nil
  end

  defp _as_atom(s) when is_binary(s) do
    String.to_atom(s)
  end

  defp _as_atom(a) when is_atom(a) do
    a
  end

end
