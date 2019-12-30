defmodule HL7.Test.SegmentTest do
  use ExUnit.Case, async: true

  alias HL7.Segment

  describe "intermediate representation" do
    test "single missing field" do
      segment = %{}
      field_spec = [{:field_name, {1}, :string, 20}]
      assert "" === Segment.get_field_ir(segment, field_spec)
    end

    test "single string field" do
      segment = %{field_name: "ABCDEF"}
      field_spec = [{:field_name, {1}, :string, 20}]
      assert "ABCDEF" === Segment.get_field_ir(segment, field_spec)
    end

    test "single integer field" do
      segment = %{field_name: 123_456}
      field_spec = [{:field_name, {1}, :integer, 20}]
      assert "123456" === Segment.get_field_ir(segment, field_spec)
    end

    test "single float field" do
      segment = %{field_name: 123.456}
      field_spec = [{:field_name, {1}, :float, 20}]
      assert "123.456" === Segment.get_field_ir(segment, field_spec)
    end

    test "single date field" do
      segment = %{field_name: ~D[2020-01-01]}
      field_spec = [{:field_name, {1}, :date, 8}]
      assert "20200101" === Segment.get_field_ir(segment, field_spec)
    end

    test "single datetime field" do
      segment = %{field_name: ~N[2020-01-01 12:01:02]}
      field_spec = [{:field_name, {1}, :datetime, 14}]
      assert "20200101120102" === Segment.get_field_ir(segment, field_spec)
    end

    test "field with two contiguous repetitions" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_2, {2}, :integer, 20},
        {:field_name_1, {1}, :string, 20}
      ]

      assert ["ABCDEF", "123456"] === Segment.get_field_ir(segment, field_spec)
    end

    test "field with two non-contiguous repetitions" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_2, {3}, :integer, 20},
        {:field_name_1, {1}, :string, 20}
      ]

      assert ["ABCDEF", "", "123456"] === Segment.get_field_ir(segment, field_spec)
    end

    test "field with three contiguous repetitions" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456, field_name_3: ~D[2020-01-01]}

      field_spec = [
        {:field_name_3, {3}, :date, 8},
        {:field_name_2, {2}, :integer, 20},
        {:field_name_1, {1}, :string, 20}
      ]

      assert ["ABCDEF", "123456", "20200101"] === Segment.get_field_ir(segment, field_spec)
    end

    test "field with three non-contiguous repetitions" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456, field_name_3: ~D[2020-01-01]}

      field_spec = [
        {:field_name_3, {6}, :date, 8},
        {:field_name_2, {4}, :integer, 20},
        {:field_name_1, {2}, :string, 20}
      ]

      assert ["", "ABCDEF", "", "123456", "", "20200101"] ===
               Segment.get_field_ir(segment, field_spec)
    end

    test "field with multiple empty repetitions" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_3, {10}, :date, 8},
        {:field_name_2, {7}, :integer, 20},
        {:field_name_1, {4}, :string, 20}
      ]

      assert ["", "", "", "ABCDEF", "", "", "123456", "", "", ""] ===
               Segment.get_field_ir(segment, field_spec)
    end

    test "field with single component" do
      segment = %{field_name: "ABCDEF"}
      field_spec = [{:field_name, {1, 1}, :string, 20}]
      assert {"ABCDEF"} === Segment.get_field_ir(segment, field_spec)
    end

    test "field with two components in a repetition each" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_2, {2, 1}, :integer, 20},
        {:field_name_1, {1, 1}, :string, 20}
      ]

      assert [{"ABCDEF"}, {"123456"}] === Segment.get_field_ir(segment, field_spec)
    end

    test "field with two contiguous components" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_2, {1, 2}, :integer, 20},
        {:field_name_1, {1, 1}, :string, 20}
      ]

      assert {"ABCDEF", "123456"} === Segment.get_field_ir(segment, field_spec)
    end

    test "field with three contiguous components" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456, field_name_3: ~D[2020-01-01]}

      field_spec = [
        {:field_name_3, {1, 3}, :date, 8},
        {:field_name_2, {1, 2}, :integer, 20},
        {:field_name_1, {1, 1}, :string, 20}
      ]

      assert {"ABCDEF", "123456", "20200101"} === Segment.get_field_ir(segment, field_spec)
    end

    test "field with three non-contiguous components" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456, field_name_3: ~D[2020-01-01]}

      field_spec = [
        {:field_name_3, {1, 6}, :date, 8},
        {:field_name_2, {1, 4}, :integer, 20},
        {:field_name_1, {1, 2}, :string, 20}
      ]

      assert {"", "ABCDEF", "", "123456", "", "20200101"} ===
               Segment.get_field_ir(segment, field_spec)
    end

    test "field with multiple empty components" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_3, {1, 10}, :date, 8},
        {:field_name_2, {1, 7}, :integer, 20},
        {:field_name_1, {1, 4}, :string, 20}
      ]

      assert {"", "", "", "ABCDEF", "", "", "123456", "", "", ""} ===
               Segment.get_field_ir(segment, field_spec)
    end

    test "field with single subcomponent" do
      segment = %{field_name: "ABCDEF"}
      field_spec = [{:field_name, {1, 1, 1}, :string, 20}]
      assert {{"ABCDEF"}} === Segment.get_field_ir(segment, field_spec)
    end

    test "field with two subcomponents in a repetition each" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_2, {2, 1, 1}, :integer, 20},
        {:field_name_1, {1, 1, 1}, :string, 20}
      ]

      assert [{{"ABCDEF"}}, {{"123456"}}] === Segment.get_field_ir(segment, field_spec)
    end

    test "field with two contiguous subcomponents" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_2, {1, 1, 2}, :integer, 20},
        {:field_name_1, {1, 1, 1}, :string, 20}
      ]

      assert {{"ABCDEF", "123456"}} === Segment.get_field_ir(segment, field_spec)
    end

    test "field with two subcomponents in a component in a repetition each" do
      segment = %{
        field_name_1: "ABCDEF",
        field_name_2: 123_456,
        field_name_3: "GHIJKL",
        field_name_4: 789_012
      }

      field_spec = [
        {:field_name_4, {2, 1, 2}, :integer, 20},
        {:field_name_3, {2, 1, 1}, :string, 20},
        {:field_name_2, {1, 1, 2}, :integer, 20},
        {:field_name_1, {1, 1, 1}, :string, 20}
      ]

      assert [{{"ABCDEF", "123456"}}, {{"GHIJKL", "789012"}}] ===
               Segment.get_field_ir(segment, field_spec)
    end

    test "field with three contiguous subcomponents" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456, field_name_3: ~D[2020-01-01]}

      field_spec = [
        {:field_name_3, {1, 1, 3}, :date, 8},
        {:field_name_2, {1, 1, 2}, :integer, 20},
        {:field_name_1, {1, 1, 1}, :string, 20}
      ]

      assert {{"ABCDEF", "123456", "20200101"}} === Segment.get_field_ir(segment, field_spec)
    end

    test "field with three non-contiguous subcomponents" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456, field_name_3: ~D[2020-01-01]}

      field_spec = [
        {:field_name_3, {1, 1, 6}, :date, 8},
        {:field_name_2, {1, 1, 4}, :integer, 20},
        {:field_name_1, {1, 1, 2}, :string, 20}
      ]

      assert {{"", "ABCDEF", "", "123456", "", "20200101"}} ===
               Segment.get_field_ir(segment, field_spec)
    end

    test "field with multiple empty subcomponents" do
      segment = %{field_name_1: "ABCDEF", field_name_2: 123_456}

      field_spec = [
        {:field_name_3, {1, 1, 10}, :date, 8},
        {:field_name_2, {1, 1, 7}, :integer, 20},
        {:field_name_1, {1, 1, 4}, :string, 20}
      ]

      assert {{"", "", "", "ABCDEF", "", "", "123456", "", "", ""}} ===
               Segment.get_field_ir(segment, field_spec)
    end

    test "field with combined repetitions, components and subcomponents" do
      segment = %{
        patient_id: "Juan Perez",
        authority_id: "MYHMO",
        authority_universal_id: "808818",
        authority_universal_id_type: "IIN",
        id_type: "CU",
        patient_document_id: "12345678",
        patient_document_id_type: "DNI"
      }

      field_spec = [
        {:patient_document_id_type, {2, 4}, :string, 3},
        {:patient_document_id, {2, 1}, :string, 20},
        {:id_type, {1, 5}, :string, 2},
        {:authority_universal_id_type, {1, 4, 3}, :string, 10},
        {:authority_universal_id, {1, 4, 2}, :string, 6},
        {:authority_id, {1, 4, 1}, :string, 6},
        {:patient_id, {1, 1}, :string, 20}
      ]

      assert [
               {"Juan Perez", "", "", {"MYHMO", "808818", "IIN"}, "CU"},
               {"12345678", "", "", "DNI"}
             ] == Segment.get_field_ir(segment, field_spec)
    end
  end
end
