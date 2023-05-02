defmodule EnumTypeTest do
  alias EnumTypeTest.MixedTypeSample
  use ExUnit.Case

  use EnumType

  defenum Sample do
    value Red, "red"
    value Blue, "blue"
    value Green, "green"

    default(Blue)
  end

  defenum IntegerSample do
    value Yes, 1
    value No, 0
    value Maybe, 2

    default(Maybe)
  end

  defenum BooleanSample do
    value Yes, true
    value No, false

    default(No)
  end

  defenum CustomSample do
    value One, "Test 1"

    value Two, "Test 2" do
      def custom, do: "Custom #{value()}"
    end

    default(One)

    @spec hello(CustomSample.t()) :: String.t()
    def hello(enum), do: "Hello #{enum.value}"
  end

  defenum MixedTypeSample do
    value One, "Test 1"
    value Two, 2
    value Three, true
    value TwentyTwo, "22"
  end

  defmodule LoadEnumsSubset do
    EnumType.load_enums(MixedTypeSample, only: [One, TwentyTwo], prefix: "mixed")

    def get_one, do: @mixed_one
    def get_twenty_two, do: @mixed_twenty_two
  end

  defmodule LoadAllEnums do
    EnumType.load_enums(MixedTypeSample, prefix: "mixed")

    def loaded_enums(), do: [@mixed_one, @mixed_two, @mixed_three, @mixed_twenty_two]
  end

  defmodule LoadEnumsWithoutPrefix do
    EnumType.load_enums(MixedTypeSample)

    def loaded_enums(), do: [@one, @two, @three, @twenty_two]
  end

  describe "enum values" do
    test "value" do
      assert "red" == Sample.Red.value()
    end

    test "default value" do
      assert "blue" == Sample.default().value
    end

    test "integer value" do
      assert 1 == IntegerSample.Yes.value()
    end

    test "integer default value" do
      assert 2 == IntegerSample.default().value
    end

    test "boolean value" do
      assert true == BooleanSample.Yes.value()
    end

    test "boolean default value" do
      assert false == BooleanSample.default().value
    end
  end

  describe "enum options" do
    test "values are in order defined in enum" do
      assert ["red", "blue", "green"] == Sample.values()
    end

    test "enums are in order defined in enum" do
      assert [Sample.Red, Sample.Blue, Sample.Green] == Sample.enums()
    end

    test "options" do
      assert [{Sample.Red, "red"}, {Sample.Blue, "blue"}, {Sample.Green, "green"}]
    end
  end

  describe "custom functions" do
    test "type function" do
      assert "Hello Test 1" == CustomSample.hello(CustomSample.One)
    end

    test "value function" do
      assert "Custom Test 2" == CustomSample.Two.custom()
    end
  end

  describe "load enums" do
    test "enums are loaded into module attributes" do
      assert LoadEnumsSubset.get_one() == MixedTypeSample.One.value()
      assert LoadEnumsSubset.get_twenty_two() == MixedTypeSample.TwentyTwo.value()
    end

    test "all enums are loaded if :only is not specified" do
      assert LoadAllEnums.loaded_enums() == MixedTypeSample.values()
    end

    test "enums maintain their names if :prefix is not specified" do
      assert LoadEnumsWithoutPrefix.loaded_enums() == MixedTypeSample.values()
    end
  end
end
