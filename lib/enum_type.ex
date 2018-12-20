defmodule EnumType do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import EnumType
    end
  end

  defmacro defenum(name, do: block) do
    quote do
      defenum(unquote(name), :string, do: unquote(block))
    end
  end
  defmacro defenum(name, ecto_type, do: block) do
    quote do
      defmodule unquote(name) do
        @type t :: __MODULE__

        Module.register_attribute(__MODULE__, :possible_options, accumulate: true)

        if Code.ensure_compiled?(Ecto.Type) do
          @behaviour Ecto.Type

          def type, do: unquote(ecto_type)
        end

        def default, do: nil

        defoverridable [default: 0]

        unquote(block)

        if Code.ensure_compiled?(Ecto.Type) do
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

        def enums, do: Enum.reverse(Enum.map(@possible_options, fn({key, _value}) -> key end))
        def values, do: Enum.reverse(Enum.map(@possible_options, fn({_key, value}) -> value end))
        def options, do: Enum.reverse(@possible_options)
      end
    end
  end

  defmacro default(option) do
    quote do
      def default, do: __MODULE__.unquote(option)
    end
  end

  defmacro value(option, value, [do: block] \\ [do: nil]) do
    quote do
      @possible_options {__MODULE__.unquote(option), unquote(value)}

      defmodule unquote(option) do
        def value, do: unquote(value)
        def upcase_value, do: String.upcase(value())
        def downcase_value, do: String.downcase(value())
        unquote(block)
      end

      def from(unquote(value)), do: unquote(option)

      def value(unquote(option)), do: unquote(option).value

      if Code.ensure_compiled?(Ecto.Type) do
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
end
