defmodule EctoTest do
  use ExUnit.Case

  defmodule EctoSchema do
    use Ecto.Schema
    use EnumType
    import Ecto.Changeset

    defenum Sample do
      value Red, "red"
      value Blue, "blue"
      value Green, "green"

      default Blue
    end

    embedded_schema do
      field :color, Sample, default: Sample.default()
    end

    def changeset(struct, params) do
      struct
      |> cast(params, [:color])
      |> Sample.validate(:color)
    end
  end

  test "ecto type type/0" do
    assert EctoSchema.Sample.type() == :string
  end

  describe "ecto type cast" do
    # called with using changeset cast as well as when running queries.  So we
    # should be able to accept both the extenal string representation of the
    # enum value as well as the module name representation.
    test "with module value" do
      assert EctoSchema.Sample.cast(EctoSchema.Sample.Red) == {:ok, EctoSchema.Sample.Red}
    end

    test "with string value" do
      assert EctoSchema.Sample.cast(EctoSchema.Sample.Red.value()) == {:ok, EctoSchema.Sample.Red}
    end

    test "with invalid module value" do
      assert EctoSchema.Sample.cast(EctoSchema.Sample.Puke) == :error
    end

    test "with invalid string value" do
      assert EctoSchema.Sample.cast("puke") == :error
    end
  end

  test "ecto type load" do
    # when loading from the DB, we are guaranteed to have a string version of the atom
    assert EctoSchema.Sample.load(EctoSchema.Sample.Red.value()) == {:ok, EctoSchema.Sample.Red}
  end

  describe "ecto type dump" do
    # when dumping data to the DB we expect a module name or atom.  But we
    # should still guard against invalid values since any value could be
    # inserted into the schema struct outside of the changeset and cast
    # functions at runtime.
    test "with valid value" do
      assert EctoSchema.Sample.dump(EctoSchema.Sample.Red) == {:ok, EctoSchema.Sample.Red.value()}
    end

    test "with invalid value" do
      assert EctoSchema.Sample.dump(EctoSchema.Sample.Puke) == :error
    end
  end

  describe "changesets" do
    test "with module value" do
      changeset = EctoSchema.changeset(%EctoSchema{}, %{color: EctoSchema.Sample.Red})
      assert changeset.valid?
      assert changeset.changes.color == EctoSchema.Sample.Red
    end

    test "with string value" do
      changeset = EctoSchema.changeset(%EctoSchema{}, %{color: EctoSchema.Sample.Red.value()})
      assert changeset.valid?
      assert changeset.changes.color == EctoSchema.Sample.Red
    end

    test "with invalid module value" do
      changeset = EctoSchema.changeset(%EctoSchema{}, %{color: EctoSchema.Sample.Puke})
      refute changeset.valid?

      assert changeset.errors == [
               color: {"is invalid", [type: EctoTest.EctoSchema.Sample, validation: :cast]}
             ]
    end

    test "with invalid string value" do
      changeset = EctoSchema.changeset(%EctoSchema{}, %{color: "puke"})
      refute changeset.valid?

      assert changeset.errors == [
               color: {"is invalid", [type: EctoTest.EctoSchema.Sample, validation: :cast]}
             ]
    end
  end
end
