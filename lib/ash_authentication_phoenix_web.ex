defmodule AshAuthentication.Phoenix.Web do
  @moduledoc false

  alias AshAuthentication.Phoenix.{LayoutView, Utils.Flash, Web}

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
  Provide a `_gettext` macro for views to wrap around text. Output is a function call to `gettext_switch/3`.
  """
  def maybe_translate do
    quote do
      @spec _gettext(String.t() | nil, Keyword.t()) :: String.t()
      defmacro _gettext(msgid, bindings \\ []) do
        gettext_fn =
          cond do
            Macro.Env.has_var?(__CALLER__, {:assigns, nil}) ->
              quote do: var!(assigns)[:gettext_fn]

            Macro.Env.has_var?(__CALLER__, {:socket, nil}) ->
              quote do: var!(socket).assigns[:gettext_fn]

            true ->
              raise "_gettext requires variable \"socket\" or \"assigns\" to exist and be set to a map"
          end

        quote generated: true do
          case unquote(msgid) do
            nil ->
              ""
            msg ->
              AshAuthentication.Phoenix.Web.gettext_switch( unquote(gettext_fn), msg, unquote(bindings))
          end
        end
      end
    end
  end

  @doc """
  If a translation function is provided, we call that, otherwise return the input untranslated.
  """
  def gettext_switch(gettext_fn, msgid, bindings) do
    if gettext_fn do
      with {module, function} when is_atom(module) and is_atom(function) <-
             gettext_fn do
        apply(module, function, [msgid, bindings])
      else
        _ ->
          raise "gettext_fn: #{inspect(gettext_fn)} is invalid - specify `{module, function}` " <>
                  "for a function with a `gettext/2` like signature"
      end
    else
      for {key, value} <- bindings, reduce: msgid do
        acc -> String.replace(acc, "%{#{key}}", to_string(value))
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc. and inject gettext helper.
  """
  defmacro __using__(which) when is_atom(which) do
    quote do
      unquote(apply(__MODULE__, which, []))
      unquote(maybe_translate())
    end
  end
end
