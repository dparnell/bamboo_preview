defmodule BambooPreview.Plug do
  use Plug.Router
  require EEx
  require Logger

  no_emails_template = Path.join(__DIR__, "no_emails.html.eex")
  EEx.function_from_file(:defp, :no_emails, no_emails_template)

  index_template = Path.join(__DIR__, "index.html.eex")
  EEx.function_from_file(:defp, :index, index_template, [:assigns])

  not_found_template = Path.join(__DIR__, "email_not_found.html.eex")
  EEx.function_from_file(:defp, :not_found, not_found_template, [:assigns])

  plug :match
  plug :dispatch

  get "/" do
    if Enum.empty?(conn.assigns.emails) do
      conn |> render_no_emails
    else
      id = conn.assigns.emails |> Map.keys |> List.first
      desc = conn.assigns.emails[id]
      conn |> render_index(_build_email(desc, id, conn))
    end
  end

  get "/:id" do
    if desc = conn.assigns.emails[id |> String.to_atom] do
      conn |> render_index(_build_email(desc, id, conn))
    else
      conn |> render_not_found
    end
  end

  get "/:id/html" do
    if email = get_email(conn, id) do
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> send_resp(:ok, email.html_body || "")
    else
      conn |> render_not_found
    end
  end

  defp render_no_emails(conn) do
    send_html(conn, :ok, no_emails())
  end

  defp render_not_found(conn) do
    assigns = %{base_path: base_path(conn)}
    send_html(conn, :not_found, not_found(assigns))
  end

  defp render_index(conn, email) do
    assigns = %{
      conn: conn,
      base_path: base_path(conn),
      email_ids: conn.assigns.emails |> Map.keys,
      selected_email: email
    }
    send_html(conn, :ok, index(assigns))
  end

  defp send_html(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> send_resp(status, body)
  end

  defp base_path(%{script_name: []}), do: ""
  defp base_path(%{script_name: script_name}) do
    "/" <> Enum.join(script_name, "/")
  end

  defp get_email(conn, id) do
    conn.assigns.emails[id |> String.to_existing_atom]
    |> _build_email(id, conn)
  end

  defp _build_email(nil, _id, _conn) do
    nil
  end

  defp _build_email({m, f, a}, id, conn) do
    apply(m, f, _build_args(a, conn))
    |> _add_message_id(id)
    |> Bamboo.Mailer.normalize_addresses()
  end

  defp _build_args({:conn, a}, conn) do
    [conn | a]
  end

  defp _build_args(a, _conn) do
    a
  end

  defp _add_message_id(email, id) do
    privs = (email.private || %{}) |> Map.put(:local_adapter_id, id)

    email |> Map.put(:private, privs)
  end
end
