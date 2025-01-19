defmodule AshAuthentication.Phoenix.Web do
  @moduledoc false

  alias AshAuthentication.Phoenix.{LayoutView, Utils.Flash, Web}

  @gettext_fn Application.compile_env(:ash_authentication_phoenix, :gettext_fn, nil)

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

  @doc """
  If a translation function is provided, we generate a `_gettext` function to call that, otherwise provide a dummy.
  """
  if @gettext_fn do
    def maybe_gettext do
      with {module, function} when is_atom(module) and is_atom(function) <- @gettext_fn do
        # Does not work:
        # Code.ensure_compiled!(module)
        # if !function_exported?(module, function, 2),
        #   do:
        #     raise(
        #       "#{module}.#{function}/2 not exported (config :ash_authentication_phoenix, :translate_fn)"
        #     )

        quote do
          def _gettext(msgid, bindings \\ []),
            do: apply(unquote(module), unquote(function), [msgid, bindings])
        end
      else
        _ ->
          raise "#{inspect(@gettext_fn)} is invalid - specify `{module, function}` for a function with a " <>
                  "`gettext/2` like signature (config :ash_authentication_phoenix, :gettext_fn)"
      end
    end
  else
    def maybe_gettext do
      quote do
        def _gettext(msgid, bindings \\ []) do
          for {key, value} <- bindings, reduce: msgid do
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
