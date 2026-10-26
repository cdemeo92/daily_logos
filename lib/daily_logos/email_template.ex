defmodule DailyLogos.EmailTemplate do
  @moduledoc "Renders the shared HTML frame used by Daily Logos emails."

  def render(language, subject, content_html, footer_html \\ "") do
    """
    <!doctype html>
    <html lang="#{escape_html(language)}">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>#{escape_html(subject)}</title>
      </head>
      <body style="margin:0;padding:0;background-color:#f2f1ed;color:#252525;font-family:Arial,Helvetica,sans-serif;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;background-color:#f2f1ed;">
          <tr>
            <td align="center" style="padding:32px 16px;">
              <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:100%;max-width:600px;border-collapse:separate;border-spacing:0;background-color:#ffffff;border:1px solid #e2dfd8;border-radius:8px;">
                <tr>
                  <td style="padding:28px 32px;background-color:#252525;border-radius:8px 8px 0 0;">
                    <p style="margin:0 0 12px;color:#f4b942;font-size:12px;font-weight:700;letter-spacing:1px;text-transform:uppercase;">
                      Daily Logos
                    </p>
                    <h1 style="margin:0;color:#ffffff;font-family:Georgia,'Times New Roman',serif;font-size:26px;font-weight:400;line-height:1.25;">
                      #{escape_html(subject)}
                    </h1>
                  </td>
                </tr>
                <tr>
                  <td style="padding:28px 32px 24px;">
                    #{content_html}
                  </td>
                </tr>
                #{footer_html}
                <tr>
                  <td style="padding:18px 32px;background-color:#f8f7f4;border-radius:0 0 8px 8px;text-align:center;">
                    <p style="margin:0;color:#77736b;font-size:12px;line-height:1.5;">
                      Daily Logos
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  def escape_html(value) do
    value
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
