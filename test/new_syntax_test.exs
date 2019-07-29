defmodule NewSyntaxTest do
  use ExUnit.Case

  use EnumType

  defenum(MyType) do
    value One, "one"
    value Two, "two"
  end

  @spec foo(thing :: MyEnum.t()) :: atom()
  def foo(MyEnum.One), do: :one_here
  def foo(MyEnum.Two), do: :two_here
  def foo(MyEnum.Three), do: :three_here

  def bar_two() do
    foo(MyEnum.Two)
  end

  def bar_bad() do
    foo(MyEnum.NotASubtype)
  end

  test "just tinkering" do
    assert foo(MyEnum.One) == :one_here
    assert foo(MyEnum.Two) == :two_here
    assert foo(MyEnum.Three) == :three_here
    assert_raise FunctionClauseError, fn -> foo(MyEnum.Boom) end
  end
end
