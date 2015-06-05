# HL7 Parser for Elixir

## Overview

Health Level 7 ([HL7](http://www.hl7.org/)) is a protocol (and an organization) designed to model and transfer health-related data electronically.

This parser has support for the HL7 version 2.x syntax. It was tested using v2.4-compliant data, but it should also work with any v2.x messages. It doesn't support the XML mappings that were created for HL7 v3.x, though.

It also has support for custom [segment](lib/ex_hl7/segment.ex) and [composite](lib/ex_hl7/composite.ex) field definitions though an easy-to-use DSL built on top of Elixir macros.

The parser was designed to make the interaction with HL7 as smooth as possible, but its use requires at least moderate knowledge of the HL7 messaging standards.

## Example

This is a basic example of a pre-authorization request with referral to another provider (`RQA^I08`) that shows how to use the parser. For more information, please check the rest of the sections below.

```elixir
defmodule Authorizer do
  alias HL7.Segment.AUT
  alias HL7.Segment.MSA
  alias HL7.Segment.MSH
  alias HL7.Segment.PRD

  alias HL7.Composite.CE
  alias HL7.Composite.CM_MSH
  alias HL7.Composite.CP
  alias HL7.Composite.EI
  alias HL7.Composite.MO

  def authorize(req) do
    message_type = HL7.segment(req, "MSH").message_type
    authorize(req, message_type.id, message_type.trigger_event)
  end

  def authorize(msg, "RQA", "I08") do
    msh = HL7.segment(msg, "MSH")
    msh = %MSH{msh |
            sending_application: msh.receiving_application,
            sending_facility: msh.receiving_facility,
            receiving_application: msh.sending_application,
            receiving_facility: msh.sending_facility,
            message_datetime: :calendar.universal_time(),
            # RPA^I08
            message_type: %CM_MSH{msh.message_type | id: "RPA"},
            # Kids, don't do this at home
            message_control_id: Base.encode64(:crypto.rand_bytes(6)),
            accept_ack_type: "ER",
            application_ack_type: "ER"
          }
    msa = %MSA{
            ack_code: "AA",
            message_control_id: msh.message_control_id
          }
    aut = %AUT{
            plan: %CE{id: "PPO"},
            company: %CE{id: "WA02"},
            company_name: "WSIC (WA State Code)",
            effective_date: {1994, 1, 10},
            expiration_date: {1994, 05, 10},
            authorization: %EI{id: "123456789"},
            reimbursement_limit: %CP{price: %MO{quantity: 175.0, denomination: "USD"}},
            requested_treatments: 1
          }
    msg = HL7.replace(msg, "MSH", msh)
    msg = HL7.insert_after(msg, "MSH", msa)
    HL7.insert_after(msg, "PR1", 0, aut)
  end

  def patient(pid) do
    name = pid.patient_name
    "Patient: #{name.given_name} #{name.family_name}"
  end

  def practice([dg1, pr1]) do
    """
    Diagnosed with: #{dg1.description}
    Treatment: #{pr1.description}
    """
  end

  def providers(prds), do:
    providers(prds, [])

  def providers([%PRD{role: role, name: name, address: address} | tail], acc) do
    info = """
    #{role_label(role.id)}:
      #{name.prefix} #{name.given_name} #{name.family_name}
      #{address.street_address}
      #{address.city}, #{address.state} #{address.postal_code}
    """
    providers(tail, [info | acc])
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

# MSH|^~\\&|MSC|EWHIN|BLAKEMD|EWHIN|19940110154812||RPA^I08|MSC2112|P|2.4|||ER|ER
# MSA|AA|BLAKEM7888
# PRD|RP|BLAKE^BEVERLY^^^DR^MD|N. 12828 NEWPORT HIGHWAY^^MEAD^WA^99021| ^^^BLAKEMD&EWHIN^^^^^BLAKE MEDICAL CENTER|BLAKEM7899
# PRD|RT|WSIC||^^^MSC&EWHIN^^^^^WASHINGTON STATE INSURANCE COMPANY
# PID|||402941703^9^M10||BROWN^CARY^JOE||19600301||||||||||||402941703
# IN1|1|PPO|WA02|WSIC (WA State Code)|11223 FOURTH STREET^^MEAD^WA^99021^USA|ANN MILLER|(509)333-1234|987654321||||19901101||||BROWN^CARY^JOE|1|19600309|N. 12345 SOME STREET^^MEAD^WA^99021^USA|||||||||||||||||402941703||||||01|M
# DG1|1|I9|569.0|RECTAL POLYP|19940106103500|0
# PR1|1|C4|45378|Colonoscopy|19940110105309|00
# AUT|PPO|WA02|WSIC (WA State Code)|19940110|19940510|123456789|175.0&USD|1

```

## Requirements

This application was developed and tested using Elixir 1.0.4 (and Erlang 17.5) but there shouldn't be any special dependency that prevents it from working with other versions.

There are no dependencies on external projects. The parser will make use of the [Logger](http://elixir-lang.org/docs/stable/logger/) application included in Elixir to output warnings when reading or writing to fields that are not present in the corresponding segment's definition.

## Installation

You can use *ex_hl7* in your projects by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [{:ex_hl7, "~> 0.1.0"},
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

## Reading Messages

## Writing Messages

## Retrieving Segments

## Using Segments

## Using Composite Fields

## Limitations