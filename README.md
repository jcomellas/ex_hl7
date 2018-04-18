# HL7 Parser for Elixir

## Overview

Health Level 7 ([HL7](http://www.hl7.org/)) is a protocol (and an organization) designed to model and transfer health-related data electronically.

This parser has support for the HL7 version 2.x syntax. It was tested using v2.4-compliant data, but it should also work with any v2.x messages. It doesn't support the XML mappings that were created for HL7 v3.x, though.

It also has support for custom [segment](lib/ex_hl7/segment.ex) and [composite](lib/ex_hl7/composite.ex) field definitions though an easy-to-use DSL built on top of Elixir macros.

The parser was designed to make the interaction with HL7 as smooth as possible, but its use requires at least moderate knowledge of the HL7 messaging standards.

## Requirements

This application was developed and tested using Elixir 1.0.4 (and Erlang 17.5) but there shouldn't be any special dependency that prevents it from working with later versions.

There are no dependencies on external projects. The parser will make use of the [Logger](http://elixir-lang.org/docs/stable/logger/) application included in Elixir to output warnings when reading or writing to fields that are not present in the corresponding segment's definition.

## Installation

You can use *ex_hl7* in your projects by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [{:ex_hl7, "~> 0.3.0"},
end
```
And then listing it as part of your application's dependencies:

```elixir
def application do
  [applications: [:ex_hl7]]
end
```

## Contributing

Only a small subset of the HL7 segments and composite fields are included in the project. You can always roll your own definitions in your project, but if you feel your changes would help others, please fork the repository, add whatever you need and send a pull-request.

## Encoding Rules

An HL7 message in its v2.x wire-format is actually a collection of concatenated segments, each terminated by a carriage-return (0x0d) character. Each segment is a collection of fields separated by a custom separator character (`|` by default). Depending on the type of the field, each field can have multiple optional repetitions (separated by `~` by default), can be made out of multiple components (separated by `^` by default) where each of them can also have subcomponents (separated by `&` by default).

This structure maps nicely to a k-ary tree. For example, given the following segment:

    OBX|1|CE|71020&IMP|1|.61^RUL^ACR~.212^Bronchopneumonia^ACR\r

We could represent it as the following subtree within a message:

```
segment                            OBX
                                    |
fields        [1]--[2]--------[3]---+------[4]------------[5]
              /     |          |            |               \
             1     "CE"        |           "1"               |
                               |                             |
components                    [0]                [0]--------[1]---------[2]
                               |                 /           |            \
                               |               0.61        "RUL"         "ACR"
                               |              0.212  "Bronchopneumonia"  "ACR"
subcomponents             [0]--+--[1]
                          /         \
                      "71020"      "IMP"
```
The field on sequence 5 contains two repetitions of a composite field.

*Note*: the indexes used for the fields are 1-based because this value is actually the sequence number assigned by HL7 to identify the field, whereas the indexes used for components and subcomponents are 0-based because this is the convention in Elixir.

The input and output of the high level functions used to read or write a message (e.g. `HL7.read/2`, `HL7.write/2`) is affected by a boolean argument named `trim`. This value changes the input and output from the lower level functions of the parser. If set to `true`, some trailing optional items and separators will be omitted from the decoded or encoded message.

For example, a field that was originally read as:

    504599^223344&&IIN&^~

Would be written in the following way when `trim` is set to `true`:

    504599^223344&&IIN

Both representations are correct, given that HL7 allows trailing items that are empty to be omitted.

## Single Value Fields

HL7 supports many types of single value (scalar, non-composite) fields. This parser maps all of them (including those that are identifiers in a table) to a few data types:

  * `nil`: the null value from HL7 (`"\"\""`).
  * `:string`: text value with no conversion performed on it. If the text contains characters that may overlap any message delimiter, it should be modified following the HL7 escaping rules (see `HL7.escape/2` and `HL7.unescape/2`).
  * `:integer`: integer number
  * `:float`: floating-point number with a dot (`.`) as decimal point; its text representation can be that of an integer (i.e. with no decimal point).
  * `:date`: date in the `YYYYMMDD` format that is represented as a `Date` struct.
  * `:datetime`: date/time in the `YYYYMMDD[hhmm[ss]]` format represented as a `NaiveDateTime` struct. If the time is not present, the hour, minutes and seconds will be set to `0`.

## Composite Fields

HL7 supports many types of composite fields and not all of them are included in this project, so to simplify their use there are some macros that help you easily define new ones.

This parser exposes composite fields as structs and, given the following definition from the HL7 standard:

    2.9.3 CE - coded element

    <identifier (ST)> ^ <text (ST)> ^ <name of coding system (IS)> ^
    <alternate identifier (ST)> ^ <alternate text (ST)> ^
    <name of alternate coding system (IS)>

They can be defined in the following way:

```elixir
use HL7.Composite.Def

defmodule HL7.Composite.CE do
  composite do
    component :id,                type: :string
    component :text,              type: :string
    component :coding_system,     type: :string
    component :alt_id,            type: :string
    component :alt_text,          type: :string
    component :alt_coding_system, type: :string
  end
end
```
This composite will be exposed as the following struct:

```elixir
defstruct :id, :text, :coding_system, :alt_id, :alt_text, :alt_coding_system
```

Each component has a name represented by an atom with the following properties:

  * `type`: atom corresponding to the data type of the value (see [single value fields](#single-value-fields)) or to a composite field's module name (e.g. `HL7.Composite.CE`).
  * `default`: optional default value; if not defined it will be set to an empty string (`""`) for scalar types and to an empty struct for composite types.

Composite fields can also be nested, and you can do it in the following way:

```elixir
use HL7.Composite.Def

alias HL7.Composite.CE

defmodule HL7.Composite.CQ do
  composite do
    component :quantity,          type: :integer
    component :units,             type: CE
  end
end
```

## Segments

As with composite fields, not all HL7 segments are provided with the project, so there is also a set of macros that help define new segments.

Segments are also exposed as structs and can be defined in this way:

```elixir
use HL7.Segment.Def

defmodule HL7.Segment.OBX do
  alias HL7.Composite.CE

  segment "OBX" do
    field :set_id,             seq:  1, type: :integer,  length:  4
    field :value_type,         seq:  2, type: :string,   length: 10, default: ""
    field :observation_id,     seq:  3, type: CE,        length: 24, default: %CE{}
    field :observation_sub_id, seq:  4, type: :string,   length: 20
    field :observation_value,  seq:  5, type: CE,        length: 24
    field :observation_status, seq: 11, type: :string,   length:  1
  end
end
```
This segment will be exposed as the following struct:

```elixir
defstruct :set_id, :value_type, :observation_id, :observation_sub_id,
          :observation_value, :observation_status
```


Each field has a name represented by an atom and has the following properties:

  * `seq`: sequence (1-based index) of the field in the segment.
  * `type`: atom corresponding to the data type of the value (see [single value fields](#single-value-fields)) or to a composite field's module name (e.g. `HL7.Composite.CE`).
  * `length`: maximum length of the serialized field.
  * `default`: optional default value; if not defined it will be set to an empty string (`""`) for all types when creating a new segment. When reading a segment from a buffer, it will be set to an empty string (`""`) for scalar types and to an empty struct for composite types.

*Note*: not all of the fields need to be defined in a segment. Segments can be "sparse" and the fields can be defined in an order that is not their sequence order. This means that if a segment containing an undefined field is parsed, that field will be lost when writing/serializing the segment back to its wire-format.

## Messages

A parsed HL7 message is represented as a list of segment structs, so you can use the functions from the `Enum` and `List` modules to retrieve data or modify them.

The `HL7` module has several functions that can be used with messages. The examples below assume that the following HL7 message is being used:

```elixir
buffer =
  "MSH|^~\\&|BLAKEMD|EWHIN|MSC|EWHIN|19940110105307||RQA^I08|BLAKEM7898|P|2.4|||NE|AL\r" <>
  "PRD|RP|BLAKE^BEVERLY^^^DR^MD|N. 12828 NEWPORT HIGHWAY^^MEAD^WA^99021| ^^^BLAKEMD&EWHIN^^^^^BLAKE MEDICAL CENTER|BLAKEM7899\r" <>
  "PRD|RT|WSIC||^^^MSC&EWHIN^^^^^WASHINGTON STATE INSURANCE COMPANY\r" <>
  "PID|||402941703^9^M10||BROWN^CARY^JOE||19600309||||||||||||402941703\r" <>
  "IN1|1|PPO|WA02|WSIC (WA State Code)|11223 FOURTH STREET^^MEAD^WA^99021^USA|ANN MILLER|509)333-1234|987654321||||19901101||||BROWN^CARY^JOE|1|19600309|N. 12345 SOME STREET^^MEAD^WA^99021^USA|||||||||||||||||402941703||||||01|M\r" <>
  "DG1|1|I9|569.0|RECTAL POLYP|19940106103500|0\r" <>
  "PR1|1|C4|45378|Colonoscopy|19940110105309|00\r"
```

You can read/parse a message from a binary in the following way:

```elixir
{:ok, message} = HL7.read(buffer)
```

Retrieve a specific repetition of a segment:

```elixir
alias HL7.Segment.PRD

%PRD{role: role} = prd = HL7.segment(message, "PRD", 1)
"PRD" = HL7.segment_id(prd)
"RT" = role.id
```
Insert segments:

```elixir
alias HL7.Segment.PR1
alias HL7.Segment.AUT
alias HL7.Composite.CE
alias HL7.Composite.EI

pr1 = HL7.segment(message, "PR1")
aut = %AUT{plan: %CE{id: "PPO"}, company: %CE{id: "WA02"},
           effective_date: ~D[1994-01-10],
           expiration_date: ~D[1994-05-10],
           authorization: %EI{id: "123456789"}}
message = HL7.insert_before(message, "PR1", 0, [pr1, aut])
message = HL7.insert_after(message, "PR1", 1, aut)
```

Replace segments:

```elixir
message = HL7.replace(message, "PR1", 0, %PR1{pr1 | set_id: 2})
```

Delete segments:

```elixir
message = HL7.delete(message, "PR1", 1)
message = HL7.delete(message, "AUT", 1)
```

Write a message into the HL7 wire format:

```elixir
iobuf = HL7.write(message, output_format: :wire, trim: true)
```

Write a message as text to standard output:

```elixir
IO.puts(HL7.write(message, output_format: :text, trim: true))
```

## Example

This is a basic example of a pre-authorization request with referral to another provider (`RQA^I08`) that shows how to use the parser. For more information, please check the rest of the sections above.

```elixir
defmodule Authorizer do
  require HL7.Composite

  alias HL7.Segment.AUT
  alias HL7.Segment.MSA
  alias HL7.Segment.MSH
  alias HL7.Segment.PID
  alias HL7.Segment.PRD

  alias HL7.Composite.CE
  alias HL7.Composite.CM_MSH_9
  alias HL7.Composite.CP
  alias HL7.Composite.EI
  alias HL7.Composite.MO

  def authorize(req) do
    message_type = HL7.segment(req, "MSH").message_type
    authorize(req, message_type.id, message_type.trigger_event)
  end

  def authorize(req, "RQA", "I08") do
    msh = HL7.segment(req, "MSH")
    msa = %MSA{
            ack_code: "AA",
            message_control_id: msh.message_control_id
          }
    msh = %MSH{msh |
            sending_app: msh.receiving_app,
            sending_facility: msh.receiving_facility,
            receiving_app: msh.sending_app,
            receiving_facility: msh.sending_facility,
            message_datetime: NaiveDateTime.utc_now(),
            # RPA^I08
            message_type: %CM_MSH_9{msh.message_type | id: "RPA"},
            # Kids, don't try this at home
            message_control_id: Base.encode32(:crypto.rand_bytes(5)),
            accept_ack_type: "ER",
            app_ack_type: "ER"
          }
    aut = %AUT{
            plan: %CE{id: "PPO"},
            company: %CE{id: "WA02"},
            company_name: "WSIC (WA State Code)",
            effective_date: ~D[1994-01-10],
            expiration_date: ~D[1994-05-10],
            authorization: %EI{id: "123456789"},
            reimbursement_limit: %CP{price: %MO{quantity: 175.0, denomination: "USD"}},
            requested_treatments: 1
          }
    req
    |> HL7.replace("MSH", msh)
    |> HL7.insert_after("MSH", msa)
    |> HL7.insert_after("PR1", 0, aut)
  end

  def patient(%PID{patient_name: name}) when is_map(name) do
    surname = if is_map(name.family_name) do
                name.family_name.surname
              else
                "<unknown>"
              end
    "Patient: #{name.given_name} #{surname}"
  end
  def patient(_pid) do
    nil
  end

  def practice([dg1, pr1]) do
    """
    Diagnosed with: #{dg1.description}
    Treatment: #{pr1.description}
    """
  end

  def providers(prds), do:
    providers(prds, [])

  def providers([%PRD{role: role, name: name, address: address} | tail], acc)
   when is_map(role) and is_map(name) and is_map(address) do
    surname = if is_map(name.family_name) do
                name.family_name.surname
              else
                "<unknown>"
              end
    info = """
    #{role_label(role.id)}:
      #{name.prefix} #{name.given_name} #{surname}
      #{address.street_address}
      #{address.city}, #{address.state} #{address.postal_code}
    """
    providers(tail, [info | acc])
  end
  def providers([_prd | tail], acc) do
    providers(tail, acc)
  end
  def providers([], acc) do
    Enum.reverse(acc)
  end

  def role_label("RP"), do: "By"
  def role_label("RT"), do: "And referred to"
end

import Authorizer

buf =
  "MSH|^~\\&|BLAKEMD|EWHIN|MSC|EWHIN|19940110105307||RQA^I08|BLAKEM7898|P|2.4|||NE|AL\r" <>
  "PRD|RP|BLAKE^BEVERLY^^^DR^MD|N. 12828 NEWPORT HIGHWAY^^MEAD^WA^99021| ^^^BLAKEMD&EWHIN^^^^^BLAKE MEDICAL CENTER|BLAKEM7899\r" <>
  "PRD|RT|WSIC||^^^MSC&EWHIN^^^^^WASHINGTON STATE INSURANCE COMPANY\r" <>
  "PID|||402941703^9^M10||BROWN^CARY^JOE||19600309||||||||||||402941703\r" <>
  "IN1|1|PPO|WA02|WSIC (WA State Code)|11223 FOURTH STREET^^MEAD^WA^99021^USA|ANN MILLER|509)333-1234|987654321||||19901101||||BROWN^CARY^JOE|1|19600309|N. 12345 SOME STREET^^MEAD^WA^99021^USA|||||||||||||||||402941703||||||01|M\r" <>
  "DG1|1|I9|569.0|RECTAL POLYP|19940106103500|0\r" <>
  "PR1|1|C4|45378|Colonoscopy|19940110105309|00\r"

{:ok, req} = HL7.read(buf, input_format: :wire)

# Print authorization request data
req |> HL7.segment("PID") |> patient |> IO.puts
req |> HL7.paired_segments(["DG1", "PR1"]) |> practice |> IO.puts
req |> Enum.filter(&(HL7.segment_id(&1) === "PRD")) |> providers |> IO.puts

# Create an authorized response and print it
req |> authorize |> HL7.write(output_format: :text, trim: true) |> IO.puts
```
