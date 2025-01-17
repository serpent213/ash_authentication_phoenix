defmodule AshAuthentication.Phoenix.Web do
  @moduledoc false

  alias AshAuthentication.Phoenix.{LayoutView, Utils.Flash, Web}

  @gettext_backend Application.compile_env(:ash_authentication_phoenix, :gettext_backend, nil)

  @doc false
  def view do
    quote do
      use Phoenix.View,
        root: "lib/ash_authentication_phoenix/templates",
        namespace: Web

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [view_module: 1, view_template: 1]

      use Phoenix.Component
    end
  end

  @doc false
  def live_view do
    quote do
      use Phoenix.LiveView, layout: {LayoutView, :live}
      on_mount Flash
    end
  end

  @doc false
  def live_component do
    quote do
      use Phoenix.LiveComponent
      import Flash, only: [put_flash!: 3]
    end
  end

  @doc false
  def component do
    quote do
      use Phoenix.Component
      import Flash, only: [put_flash!: 3]
    end
  end

  @doc false
  def maybe_gettext do
    if @gettext_backend && Code.ensure_loaded?(Gettext) do
      quote do
        def _gettext(msgid, args \\ []) do
          Gettext.dgettext(unquote(@gettext_backend), "auth", msgid, args)
        end

        def _ngettext(msgid, msgid_plural, count, args \\ []) do
          Gettext.dngettext(unquote(@gettext_backend), "auth", msgid, msgid_plural, count, args)
        end
      end
    else
      quote do
        def _gettext(msgid, args \\ []) do
          for {key, value} <- args, reduce: msgid do
            acc -> String.replace(acc, "%{#{key}}", to_string(value))
          end
        end

        def _ngettext(msgid, msgid_plural, count, args \\ []) do
          msg = if count == 1, do: msgid, else: msgid_plural

          for {key, value} <- args, reduce: msg do
            acc -> String.replace(acc, "%{#{key}}", to_string(value))
          end
        end
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    quote do
      unquote(apply(__MODULE__, which, []))
      unquote(maybe_gettext())
    end
  end
end
