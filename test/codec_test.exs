defmodule HL7.Test.CodecTest do
  use ExUnit.Case, async: true

  import HL7.Codec, only: [decode_field!: 2, decode_field!: 3,
                           decode_components!: 2, decode_components!: 3,
                           decode_subcomponents!: 2, decode_subcomponents!: 3,
                           decode_value!: 2, escape: 3, unescape: 3]

  @separators HL7.Codec.separators()


  # Decoding tests
  test "decode single binary subcomponent" do
    assert decode_subcomponents!("S1", @separators) === "S1"
  end

  test "decode single empty subcomponent" do
    assert decode_subcomponents!("", @separators) === ""
  end

  test "decode single null subcomponent" do
    assert decode_subcomponents!("\"\"", @separators) === nil
  end

  test "decode multiple subcomponents" do
    assert decode_subcomponents!("&\"\"&S3&S4", @separators) === {"", nil, "S3", "S4"}
    assert decode_subcomponents!("S1&&\"\"&S4", @separators) === {"S1", "", nil, "S4"}
    assert decode_subcomponents!("S1&S2&&\"\"", @separators) === {"S1", "S2", "", nil}
    assert decode_subcomponents!("\"\"&S2&S3&", @separators, true) === {nil, "S2", "S3"}
    assert decode_subcomponents!("\"\"&S2&S3&", @separators, false) === {nil, "S2", "S3", ""}
  end

  test "decode single binary component" do
    assert decode_components!("C1", @separators) === "C1"
  end

  test "decode single empty component" do
    assert decode_components!("", @separators) === ""
  end

  test "decode single null component" do
    assert decode_components!("\"\"", @separators) === nil
  end

  test "decode multiple components" do
    assert decode_components!("^\"\"^C3^C4", @separators) === {"", nil, "C3", "C4"}
    assert decode_components!("C1^^\"\"^C4", @separators) === {"C1", "", nil, "C4"}
    assert decode_components!("C1^C2^^\"\"", @separators) === {"C1", "C2", "", nil}
    assert decode_components!("\"\"^C2^C3^", @separators, true) === {nil, "C2", "C3"}
    assert decode_components!("\"\"^C2^C3^", @separators, false) === {nil, "C2", "C3", ""}
  end

  test "decode single component with subcomponents" do
    assert decode_components!("S1&S2&S3", @separators) === {{"S1", "S2", "S3"}}
    assert decode_components!("&S2&S3", @separators) === {{"", "S2", "S3"}}
    assert decode_components!("S1&S2&\"\"", @separators) === {{"S1", "S2", nil}}
    assert decode_components!("&S2&S3&", @separators, true) === {{"", "S2", "S3"}}
    assert decode_components!("&S2&S3&", @separators, false) === {{"", "S2", "S3", ""}}
  end

  test "decode multiple components with subcomponents" do
    assert decode_components!("^S1&S2&\"\"^C3^C4", @separators) === {"", {"S1", "S2", nil}, "C3", "C4"}
    assert decode_components!("S1&S2^C2^S3&S4", @separators) === {{"S1", "S2"}, "C2", {"S3", "S4"}}
    assert decode_components!("C1^&&^\"\"^C4", @separators, true) === {"C1", "", nil, "C4"}
    assert decode_components!("C1^&&^\"\"^C4", @separators, false) === {"C1", {"", "", ""}, nil, "C4"}
  end

  test "decode single binary field" do
    assert decode_field!("F1", @separators) === "F1"
  end

  test "decode single empty field" do
    assert decode_field!("", @separators) === ""
  end

  test "decode single null field" do
    assert decode_field!("\"\"", @separators) === nil
  end

  test "decode repeated fields" do
    assert decode_field!("F1~F2", @separators) === ["F1", "F2"]
    assert decode_field!("\"\"~F1~F2~", @separators) === [nil, "F1", "F2"]
    assert decode_field!("F1~~~F2", @separators) === ["F1", "", "", "F2"]
    assert decode_field!("F1~F2~\"\"~~", @separators) === ["F1", "F2", nil]
  end

  test "decode field with multiple components" do
    assert decode_field!("^\"\"^C3^C4", @separators) === {"", nil, "C3", "C4"}
    assert decode_field!("C1^^\"\"^C4", @separators) === {"C1", "", nil, "C4"}
    assert decode_field!("C1^C2^^\"\"", @separators) === {"C1", "C2", "", nil}
    assert decode_field!("\"\"^C2^C3^", @separators) === {nil, "C2", "C3"}
    assert decode_field!("504599^223344&&IIN^", @separators, true) === {"504599", {"223344", "", "IIN"}}
    assert decode_field!("504599^223344&&IIN^", @separators, false) === {"504599", {"223344", "", "IIN"}, ""}
  end

  test "decode repeated fields with multiple components" do
    assert decode_field!("^\"\"^C3^C4~F1", @separators) === [{"", nil, "C3", "C4"}, "F1"]
    assert decode_field!("C1^C2~C3^^\"\"^C4", @separators) === [{"C1", "C2"}, {"C3", "", nil, "C4"}]
    assert decode_field!("C1^C2^^\"\"~", @separators) === {"C1", "C2", "", nil}
    assert decode_field!("\"\"~\"\"^C2^C3^", @separators) === [nil, {nil, "C2", "C3"}]
  end

  test "decode repeated fields with multiple components and subcomponents" do
    assert decode_field!("^\"\"^C3^C4~S1&S2&S3", @separators) === [{"", nil, "C3", "C4"}, {{"S1", "S2", "S3"}}]
    assert decode_field!("C1^C2~S1&S2^C3^^\"\"^C4", @separators) === [{"C1", "C2"}, {{"S1", "S2"}, "C3", "", nil, "C4"}]
    assert decode_field!("S1&S2~C1^C2^^\"\"~", @separators) === [{{"S1", "S2"}}, {"C1", "C2", "", nil}]
    assert decode_field!("\"\"~\"\"^S1&S2^C3^", @separators) === [nil, {nil, {"S1", "S2"}, "C3"}]
  end

  test "decode null value" do
    assert decode_value!("\"\"", :string) === nil
    assert decode_value!("\"\"", :integer) === nil
    assert decode_value!("\"\"", :float) === nil
    assert decode_value!("\"\"", :date) === nil
    assert decode_value!("\"\"", :datetime) === nil
  end

  test "decode empty value" do
    assert decode_value!("", :string) === ""
    assert decode_value!("", :integer) === ""
    assert decode_value!("", :float) === ""
    assert decode_value!("", :date) === ""
    assert decode_value!("", :datetime) === ""
  end

  test "decode string value" do
    assert decode_value!("ABC", :string) === "ABC"
    assert decode_value!("1.0", :string) === "1.0"
  end

  test "decode integer value" do
    assert decode_value!("100", :integer) === 100
    assert_raise ArgumentError, fn -> decode_value!("100.0", :integer) end
    assert_raise ArgumentError, fn -> decode_value!("ABC", :integer) end
  end

  test "decode float value" do
    assert decode_value!("100.0", :float) === 100.0
    assert decode_value!("100", :float) === 100.0
    assert_raise ArgumentError, fn -> decode_value!("ABC", :float) end
  end

  test "decode date value" do
    assert decode_value!("20120823", :date) === ~D[2012-08-23]
    assert decode_value!("20120823103211", :date) === ~D[2012-08-23]
    assert decode_value!("201208231032", :date) === ~D[2012-08-23]
    assert_raise ArgumentError, fn -> decode_value!("20121323", :date) end
    assert_raise ArgumentError, fn -> decode_value!("20130832", :date) end
    assert_raise ArgumentError, fn -> decode_value!("20130229", :date) end
    assert_raise ArgumentError, fn -> decode_value!("ABC", :date) end
  end

  test "decode datetime value" do
    assert decode_value!("20120823103211", :datetime) === ~N[2012-08-23 10:32:11]
    assert decode_value!("201208231032", :datetime) === ~N[2012-08-23 10:32:00]
    assert decode_value!("20120823", :datetime) === ~N[2012-08-23 00:00:00]
    assert_raise ArgumentError, fn -> decode_value!("20120823253211", :datetime) end
    assert_raise ArgumentError, fn -> decode_value!("20120823106311", :datetime) end
    assert_raise ArgumentError, fn -> decode_value!("20120823103270", :datetime) end
    assert_raise ArgumentError, fn -> decode_value!("ABC", :datetime) end
  end

  # Convenience functions used to simplify encoding tests
  def encode_field!(value, separators), do:
    IO.iodata_to_binary(HL7.Codec.encode_field!(value, separators))

  def encode_field!(value, separators, options), do:
    IO.iodata_to_binary(HL7.Codec.encode_field!(value, separators, options))

  def encode_components!(value, separators), do:
    IO.iodata_to_binary(HL7.Codec.encode_components!(value, separators))

  def encode_components!(value, separators, options), do:
    IO.iodata_to_binary(HL7.Codec.encode_components!(value, separators, options))

  def encode_subcomponents!(value, separators), do:
    IO.iodata_to_binary(HL7.Codec.encode_subcomponents!(value, separators))

  def encode_subcomponents!(value, separators, options), do:
    IO.iodata_to_binary(HL7.Codec.encode_subcomponents!(value, separators, options))

  def encode_value!(value, type), do:
    IO.iodata_to_binary(HL7.Codec.encode_value!(value, type))

  # Encoding tests
  test "encode single binary subcomponent" do
    assert encode_subcomponents!("S1", @separators) === "S1"
  end

  test "encode single empty subcomponent" do
    assert encode_subcomponents!("", @separators) === ""
  end

  test "encode single null subcomponent" do
    assert encode_subcomponents!(nil, @separators) === "\"\""
  end

  test "encode multiple subcomponents" do
    assert encode_subcomponents!({"", nil, "S3", "S4"}, @separators) === "&\"\"&S3&S4"
    assert encode_subcomponents!({"S1", "", nil, "S4"}, @separators) === "S1&&\"\"&S4"
    assert encode_subcomponents!({"S1", "S2", "", nil}, @separators) === "S1&S2&&\"\""
    assert encode_subcomponents!({nil, "S2", "S3", ""}, @separators) === "\"\"&S2&S3"
  end

  test "encode single binary component" do
    assert encode_components!("C1", @separators) === "C1"
  end

  test "encode single empty component" do
    assert encode_components!("", @separators) === ""
  end

  test "Encode single null component" do
    assert encode_components!(nil, @separators) === "\"\""
  end

  test "encode multiple components" do
    assert encode_components!({"", nil, "C3", "C4"}, @separators) === "^\"\"^C3^C4"
    assert encode_components!({"C1", "", nil, "C4"}, @separators) === "C1^^\"\"^C4"
    assert encode_components!({"C1", "C2", "", nil}, @separators) === "C1^C2^^\"\""
    assert encode_components!({nil, "C2", "C3", ""}, @separators) === "\"\"^C2^C3"
  end

  test "encode single component with subcomponents" do
    assert encode_components!({{"S1", "S2", "S3"}}, @separators) === "S1&S2&S3"
    assert encode_components!({{"", "S2", "S3"}}, @separators) === "&S2&S3"
    assert encode_components!({{"", "S2", "S3", ""}}, @separators) === "&S2&S3"
    assert encode_components!({{"S1", "S2", nil}}, @separators) === "S1&S2&\"\""
  end

  test "encode multiple components with subcomponents" do
    assert encode_components!({"", {"S1", "S2", nil}, "C3", "C4"}, @separators) === "^S1&S2&\"\"^C3^C4"
    assert encode_components!({{"S1", "S2"}, "C2", {"S3", "S4"}}, @separators) === "S1&S2^C2^S3&S4"
    assert encode_components!({"C1", {"", "", ""}, nil, "C4"}, @separators, true) === "C1^^\"\"^C4"
    assert encode_components!({"C1", {"", "", ""}, nil, "C4"}, @separators, false) === "C1^&&^\"\"^C4"
  end

  test "encode single binary field" do
    assert encode_field!("F1", @separators) === "F1"
  end

  test "encode single empty field" do
    assert encode_field!("", @separators) === ""
  end

  test "encode single null field" do
    assert encode_field!(nil, @separators) === "\"\""
  end

  test "encode repeated fields" do
    assert encode_field!(["F1", "F2"], @separators) === "F1~F2"
    assert encode_field!([nil, "F1", "F2", ""], @separators, true) === "\"\"~F1~F2"
    assert encode_field!([nil, "F1", "F2", ""], @separators, false) === "\"\"~F1~F2~"
    assert encode_field!(["F1", "", "", "F2"], @separators) === "F1~~~F2"
    assert encode_field!(["F1", "F2", nil, "", ""], @separators, true) === "F1~F2~\"\""
    assert encode_field!(["F1", "F2", nil, "", ""], @separators, false) === "F1~F2~\"\"~~"
  end

  test "encode field with multiple components" do
    assert encode_field!({"", nil, "C3", "C4"}, @separators) === "^\"\"^C3^C4"
    assert encode_field!({"C1", "", nil, "C4"}, @separators) === "C1^^\"\"^C4"
    assert encode_field!({"C1", "C2", "", nil}, @separators) === "C1^C2^^\"\""
    assert encode_field!({nil, "C2", "C3", ""}, @separators, true) === "\"\"^C2^C3"
    assert encode_field!({nil, "C2", "C3", ""}, @separators, false) === "\"\"^C2^C3^"
    assert encode_field!({"NAME", "", "", "", "", "", "", "", {"", "", "", "", "", ""},
                        {"", ""}, ""}, @separators, true) == "NAME"
    assert encode_field!({"NAME", "", "", "", "", "", "", "", {"", "", "", "", "", ""},
                        {"", ""}, ""}, @separators, false) == "NAME^^^^^^^^&&&&&^&^"
  end

  test "encode repeated fields with multiple components" do
    assert encode_field!([{"", nil, "C3", "C4"}, "F1"], @separators) === "^\"\"^C3^C4~F1"
    assert encode_field!([{"C1", "C2"}, {"C3", "", nil, "C4"}], @separators) === "C1^C2~C3^^\"\"^C4"
    assert encode_field!({"C1", "C2", "", nil}, @separators) === "C1^C2^^\"\""
    assert encode_field!([nil, {nil, "C2", "C3", ""}], @separators) === "\"\"~\"\"^C2^C3"
  end

  test "encode repeated fields with multiple components and subcomponents" do
    assert encode_field!([{"", nil, "C3", "C4"}, {{"S1", "S2", "S3"}}], @separators) === "^\"\"^C3^C4~S1&S2&S3"
    assert encode_field!([{"C1", "C2"}, {{"S1", "S2"}, "C3", "", nil, "C4"}], @separators) === "C1^C2~S1&S2^C3^^\"\"^C4"
    assert encode_field!([{{"S1", "S2"}}, {"C1", "C2", "", nil}], @separators) === "S1&S2~C1^C2^^\"\""
    assert encode_field!([nil, {nil, {"S1", "S2"}, "C3", ""}], @separators, true) === "\"\"~\"\"^S1&S2^C3"
    assert encode_field!([nil, {nil, {"S1", "S2"}, "C3", ""}], @separators, false) === "\"\"~\"\"^S1&S2^C3^"
  end

  test "encode null value" do
    assert encode_value!(nil, :string) === "\"\""
    assert encode_value!(nil, :integer) === "\"\""
    assert encode_value!(nil, :float) === "\"\""
    assert encode_value!(nil, :date) === "\"\""
    assert encode_value!(nil, :datetime) === "\"\""
  end

  test "encode empty value" do
    assert encode_value!("", :string) === ""
    assert encode_value!("", :integer) === ""
    assert encode_value!("", :float) === ""
    assert encode_value!("", :date) === ""
    assert encode_value!("", :datetime) === ""
  end

  test "encode string value" do
    assert encode_value!("ABC", :string) === "ABC"
    assert encode_value!("1.0", :string) === "1.0"
  end

  test "encode integer value" do
    assert encode_value!(100, :integer) === "100"
    assert_raise ArgumentError, fn -> encode_value!(100.0, :integer) end
    assert_raise ArgumentError, fn -> encode_value!("ABC", :integer) end
  end

  test "encode float value" do
    assert encode_value!(100.0, :float) === "100.0"
    assert_raise ArgumentError, fn -> encode_value!(100, :float) end
    assert_raise ArgumentError, fn -> encode_value!("ABC", :float) end
  end

  test "encode date value" do
    assert encode_value!(~D[2012-08-23], :date) === "20120823"
    assert encode_value!(~N[2012-08-23 10:32:11], :date) === "20120823"
    assert_raise ArgumentError, fn -> encode_value!("ABC", :date) end
  end

  test "encode datetime value" do
    assert encode_value!(~N[2012-08-23 10:32:11], :datetime) === "20120823103211"
    assert encode_value!(~N[2012-08-23 10:32:00], :datetime) === "201208231032"
    assert encode_value!(~D[2012-08-23], :datetime) === "201208230000"
    assert_raise ArgumentError, fn -> encode_value!("ABC", :datetime) end
  end

  test "escape value" do
    str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%*()_+_={}[]:;\"'<>?,./"
    assert escape(str, @separators, ?\\) === str
    assert escape("ABC\\DEF\\GHI", @separators, ?\\) === "ABC\\E\\DEF\\E\\GHI"
    assert escape("ABC|DEF|GHI", @separators, ?\\) === "ABC\\F\\DEF\\F\\GHI"
    assert escape("ABC^DEF^", @separators, ?\\) === "ABC\\S\\DEF\\S\\"
    assert escape("&DEF&GHI", @separators, ?\\) === "\\T\\DEF\\T\\GHI"
    assert escape("~ABC~DEF~", @separators, ?\\) === "\\R\\ABC\\R\\DEF\\R\\"
    assert escape("|ABC^DEF&GHI~", @separators, ?\\) === "\\F\\ABC\\S\\DEF\\T\\GHI\\R\\"
  end

  test "unescape value" do
    str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%*()_+_={}[]:;\"'<>?,./"
    assert unescape(str, @separators, ?\\) === str
    assert unescape("ABC\\E\\DEF\\E\\GHI", @separators, ?\\) === "ABC\\DEF\\GHI"
    assert unescape("ABC\\F\\DEF\\F\\GHI", @separators, ?\\) === "ABC|DEF|GHI"
    assert unescape("ABC\\S\\DEF\\S\\", @separators, ?\\) === "ABC^DEF^"
    assert unescape("\\T\\DEF\\T\\GHI", @separators, ?\\) === "&DEF&GHI"
    assert unescape("\\R\\ABC\\R\\DEF\\R\\", @separators, ?\\) === "~ABC~DEF~"
    assert unescape("\\F\\ABC\\S\\DEF\\T\\GHI\\R\\JKL\\E\\MNO", @separators, ?\\) === "|ABC^DEF&GHI~JKL\\MNO"
  end
end
