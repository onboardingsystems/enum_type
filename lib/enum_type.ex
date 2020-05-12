defmodule EnumType do
  @moduledoc """
  Generates Enumerated type modules that can be used as values and matched in
  code. Creates proper types so Dialyzer will be able to check bad calls.
  """

  defmacro __using__(_opts) do
    quote do
      import EnumType
    end
  end

  defmacro defenum(name, do: block) do
    quote generated: true, location: :keep do
      defenum(unquote(name), [type: :string], do: unquote(block))
    end
  end

  # Makes an alias: `build_module(MyModule, [:One])` -> `MyModule.One`
  defp build_module({:__aliases__, meta, prefix}, submodules),
    do: {:__aliases__, meta, prefix ++ submodules}

  defp build_module(prefix, submodules) when is_atom(prefix),
    do: {:__aliases__, [], [prefix | submodules]}

  # Given a prefix like `:MyModule` and some subtypes like `[:One,
  # :Two]`, constructs a pipe list like `MyModule.One | MyModule.Two`.
  # Returns AST.
  defp build_type_pipe(prefix, [subtype]) do
    build_module(prefix, [subtype])
  end

  defp build_type_pipe(prefix, [subtype | other_types]) do
    quote generated: true, location: :keep do
      unquote(build_module(prefix, [subtype])) | unquote(build_type_pipe(prefix, other_types))
    end
  end

  defmacro defenum(name, opts, do: block) do
    ecto_type = Keyword.get(opts, :type)
    generate_ecto_type = Keyword.get(opts, :generate_ecto_type, true)

    {:__block__, _, block_body} = block

    values =
      Enum.reduce(block_body, [], fn
        {:value, _, [{_, _, [sym]} | _]}, acc -> [sym | acc]
        _, acc -> acc
      end)

    type_pipe = build_type_pipe(name, values)

    # type_pipe_string = Macro.to_string(type_pipe, __ENV__)

    syn =
      quote generated: true, location: :keep do
        defmodule unquote(name) do
          @type t :: unquote(type_pipe)

          Module.register_attribute(__MODULE__, :possible_options, accumulate: true)

          if unquote(generate_ecto_type?(generate_ecto_type)) do
            @behaviour Ecto.Type

            def type, do: unquote(ecto_type)
          end

          def default, do: nil

          defoverridable default: 0

          unquote(block)

          if unquote(generate_ecto_type?(generate_ecto_type)) do
            # Default fallback ecto conversion options.
            def cast(_), do: :error
            def load(_), do: :error
            def value(nil), do: nil
            def value(_), do: :error
            def dump(_), do: :error

            def validate(changeset, field, opts \\ []) do
              Ecto.Changeset.validate_inclusion(changeset, field, enums(), opts)
            end
          end

          def enums, do: Enum.reverse(Enum.map(@possible_options, fn {key, _value} -> key end))
          def values, do: Enum.reverse(Enum.map(@possible_options, fn {_key, value} -> value end))
          def options, do: Enum.reverse(@possible_options)
        end
      end

    syn
  end

  defmacro default(option) do
    quote generated: true, location: :keep do
      def default, do: __MODULE__.unquote(option)
    end
  end

  defmacro value(option, value, [do: block] \\ [do: nil]) do
    quote generated: true, location: :keep do
      @possible_options {__MODULE__.unquote(option), unquote(value)}

      defmodule unquote(option) do
        @type t :: __MODULE__

        def value, do: unquote(value)
        def upcase_value, do: String.upcase(value() |> to_string())
        def downcase_value, do: String.downcase(value() |> to_string())
        unquote(block)
      end

      def from(unquote(value)), do: unquote(option)

      def value(unquote(option)), do: unquote(option).value

      if unquote(generate_ecto_type?(true)) do
        # Support querying by both the Enum module and the specific value.
        # Error will occur if an invalid value is attempted to be used.
        def cast(unquote(option)), do: {:ok, unquote(option)}
        def cast(unquote(value)), do: {:ok, unquote(option)}

        def load(unquote(value)), do: {:ok, unquote(option)}

        # Allow both querying by Module and setting a value to the Module when updating or inserting.
        def dump(unquote(option)), do: {:ok, unquote(option).value}
      end
    end
  end

  defp generate_ecto_type?(false), do: false
  defp generate_ecto_type?(true), do: match?({:module, _module}, Code.ensure_compiled(Ecto.Type))
end
