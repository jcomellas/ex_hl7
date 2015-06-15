defmodule HL7.Segment do
  @moduledoc "Generic functions used by HL7 segment macros"
  require Logger

  @type t          :: map
  @type descriptor :: {name :: atom, HL7.Type.sequence, HL7.Type.value_type, length :: pos_integer}

  @spec id(t) :: HL7.Type.segment_id
  def id(segment) when is_map(segment), do: Map.get(segment, :__segment__)
  def id(_segment), do: nil

  @spec module(HL7.Type.segment_id) :: module
  def module(id) when is_binary(id), do: Module.concat([HL7.Segment, id])

  @spec new(HL7.Type.segment_id) :: {module, t}
  def new(segment_id) do
    module = module(segment_id)
    {module, apply(module, :new, [])}
  end

  @spec get_field(t, descriptor, HL7.Type.sequence) :: HL7.Type.field
  def get_field(segment, descriptor, seq) when seq <= tuple_size(descriptor) do
    case :erlang.element(seq, descriptor) do
      {name, _seq, type, _length} ->
        field = Map.get(segment, name)
        if is_list(field) do
          Enum.map(field, &HL7.Composite.maybe_encode_value(&1, type))
        else
          HL7.Composite.maybe_encode_value(field, type)
        end
      nil ->
        ""
    end
  end
  def get_field(_segment, _descriptor, _seq) do
    Logger.warn("Retrieving field with out-of-bounds sequence #{_seq} from " <>
                "HL7 segment #{inspect Map.get(_segment, :__segment__)}")
    ""
  end

  @spec put_field(t, descriptor, HL7.Type.sequence, HL7.Type.field) :: t
  def put_field(segment, descriptor, seq, value) when seq <= tuple_size(descriptor) do
    case :erlang.element(seq, descriptor) do
      {name, _seq, type, _length} ->
        field = if is_list(value) do
                  # Convert each of the repetitions of the field
                  Enum.map(value, &HL7.Composite.maybe_decode_value(&1, type))
                else
                  HL7.Composite.maybe_decode_value(value, type)
                end
        Map.put(segment, name, field)
      nil ->
        # TODO: should we show a warning when trying to set a field we don't know about?
        if value !== "" do
          Logger.warn("Tried to put value #{inspect value} into field with unknown " <>
                      "sequence #{seq} into HL7 segment #{inspect Map.get(segment, :__segment__)}")
        end
        segment
    end
  end
  def put_field(segment, _descriptor, _seq, value) do
    # TODO: should we show a warning when trying to set a field we don't know about?
    if value !== "" do
      Logger.warn("Tried to put value #{inspect value} into field with out-of-bounds " <>
                  "sequence #{_seq} into HL7 segment #{inspect Map.get(segment, :__segment__)}")
    end
    segment
  end
end

use HL7.Segment.Def

defmodule HL7.Segment.AUT do
  @moduledoc "11.6.2 AUT - authorization information segment"
  alias HL7.Composite.CE
  alias HL7.Composite.CP
  alias HL7.Composite.EI

  segment "AUT" do
    field :plan,                       seq:  1, type: CE,        length: 32
    field :company,                    seq:  2, type: CE,        length: 58
    field :company_name,               seq:  3, type: :string,   length: 45
    field :effective_date,             seq:  4, type: :datetime, length: 14
    field :expiration_date,            seq:  5, type: :datetime, length: 14
    field :authorization,              seq:  6, type: EI,        length: 20
    field :reimbursement_limit,        seq:  7, type: CP,        length: 25
    field :requested_treatments,       seq:  8, type: :integer,  length:  2
    field :authorized_treatments,      seq:  9, type: :integer,  length:  2
    field :process_date,               seq: 10, type: :date,     length:  8
  end
end

defmodule HL7.Segment.DG1 do
  @moduledoc "6.5.2 DG1 - diagnosis segment"
  alias HL7.Composite.CE

  segment "DG1" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :coding_method,              seq:  2, type: :string,   length:  2
    field :diagnosis,                  seq:  3, type: CE,        length: 64
    field :description,                seq:  4, type: :string,   length: 40
    field :diagnosis_datetime,         seq:  5, type: :datetime, length: 40
    field :diagnosis_type,             seq:  6, type: :string,   length:  2
    field :category,                   seq:  7, type: CE,        length: 250
    field :related_group,              seq:  8, type: CE,        length: 250
    field :approval_indicator,         seq:  9, type: :string,   length: 1
  end
end

defmodule HL7.Segment.DSC do
  @moduledoc "2.16.4 DSC - continuation pointer segment"
  segment "DSC" do
    field :continuation_pointer,       seq:  1, type: :string,   length: 15
  end
end

defmodule HL7.Segment.DSP do
  @moduledoc "5.5.1 DSP - display data segment"
  segment "DSP" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :display_level,              seq:  2, type: :string,   length:  4
    field :data_line,                  seq:  3, type: :string,   length: 40
    field :break_point,                seq:  4, type: :string,   length:  2
    field :result_id,                  seq:  5, type: :string,   length: 20
  end
end

defmodule HL7.Segment.ERR do
  @moduledoc "2.16.5 ERR - error segment"
  alias HL7.Composite.CM_ERR

  segment "ERR" do
    field :error_info,                 seq:  1, type: CM_ERR,    length: 80
  end
end

defmodule HL7.Segment.EVN do
  @moduledoc "3.4.1 EVN - event type segment"
  segment "EVN" do
    field :recorded_datetime,          seq:  2, type: :datetime, length: 14
    field :planned_event_datetime,     seq:  3, type: :datetime, length: 14
    field :event_reason_code,          seq:  4, type: :string,   length:  3
  end
end

defmodule HL7.Segment.IN1 do
  @moduledoc "6.5.6 IN1 - insurance segment"
  alias HL7.Composite.CE
  alias HL7.Composite.CX
  alias HL7.Composite.CM_IN1

  segment "IN1" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :plan,                       seq:  2, type: CE,        length: 51
    field :company,                    seq:  3, type: CX,        length: 48
    field :authorization,              seq: 14, type: CM_IN1,    length: 29
  end
end

defmodule HL7.Segment.MSA do
  @moduledoc "2.16.8 MSA - message acknowledgment segment"
  alias HL7.Composite.CE

  segment "MSA" do
    field :ack_code,                   seq:  1, type: :string,   length:  2
    field :message_control_id,         seq:  2, type: :string,   length: 20
    field :text_message,               seq:  3, type: :string,   length: 80
    field :error_condition,            seq:  6, type: CE,        length: 51
  end
end

defmodule HL7.Segment.MSH do
  @moduledoc "2.16.9 MSH - message header segment"
  alias HL7.Composite.HD
  alias HL7.Composite.CM_MSH

  segment "MSH" do
    field :field_separator,            seq:  1, type: :string,   length:  1
    field :encoding_chars,             seq:  2, type: :string,   length:  4
    field :sending_application,        seq:  3, type: HD,        length: 12
    field :sending_facility,           seq:  4, type: HD,        length: 54
    field :receiving_application,      seq:  5, type: HD,        length: 12
    field :receiving_facility,         seq:  6, type: HD,        length: 54
    field :message_datetime,           seq:  7, type: :datetime, length: 14
    field :security,                   seq:  8, type: :string,   length: 40
    field :message_type,               seq:  9, type: CM_MSH,    length: 15
    field :message_control_id,         seq: 10, type: :string,   length: 20
    field :processing_id,              seq: 11, type: :string,   length:  3
    field :version,                    seq: 12, type: :string,   length:  8
    field :sequence_number,            seq: 13, type: :integer,  length: 15
    field :continuation_pointer,       seq: 14, type: :string,   length: 180
    field :accept_ack_type,            seq: 15, type: :string,   length:  2
    field :application_ack_type,       seq: 16, type: :string,   length:  2
    field :country_code,               seq: 17, type: :string,   length:  3
    field :char_set,                   seq: 18, type: :string,   length: 10
  end
end

defmodule HL7.Segment.NTE do
  @moduledoc "2.16.10 NTE - notes and comments segment"
  segment "NTE" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :comment_source,             seq:  2, type: :string,   length:  8
    field :comment,                    seq:  3, type: :string,   length: 512
  end
end

defmodule HL7.Segment.OBX do
  @moduledoc "7.4.2 OBX - observation/result segment"
  alias HL7.Composite.CE

  segment "OBX" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :value_type,                 seq:  2, type: :string,   length: 10
    field :observation_id,             seq:  3, type: CE,        length: 24
    field :observation_sub_id,         seq:  4, type: :string,   length: 20
    field :observation_value,          seq:  5, type: CE,        length: 24
    field :observation_status,         seq: 11, type: :string,   length:  1
  end
end

defmodule HL7.Segment.PID do
  @moduledoc "3.4.2 PID - patient identification segment"
  alias HL7.Composite.CX
  alias HL7.Composite.XPN

  segment "PID" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :patient_id,                 seq:  3, type: CX,        length: 48
    field :alt_patient_id,             seq:  4, type: CX,        length: 48
    field :patient_name,               seq:  5, type: XPN,       length: 51
  end
end

defmodule HL7.Segment.PR1 do
  @moduledoc "6.5.4 PR1 - procedures segment"
  alias HL7.Composite.CE

  segment "PR1" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :coding_method,              seq:  2, type: :string,   length:  3
    field :procedure,                  seq:  3, type: CE,        length: 56
    field :description,                seq:  4, type: :string,   length: 40
    field :datetime,                   seq:  5, type: :datetime, length: 14
    field :functional_type,            seq:  6, type: :string,   length:  2
  end
end

defmodule HL7.Segment.PRD do
  @moduledoc "11.6.3 PRD - provider data segment"
  alias HL7.Composite.CE
  alias HL7.Composite.XAD
  alias HL7.Composite.XPN
  alias HL7.Composite.PL
  alias HL7.Composite.CM_PRD

  segment "PRD" do
    field :role,                       seq:  1, type: CE,        length:  44
    field :name,                       seq:  2, type: XPN,       length:  71
    field :address,                    seq:  3, type: XAD,       length: 121
    field :location,                   seq:  4, type: PL,        length: 121
    field :id,                         seq:  7, type: CM_PRD,    length: 121
  end
end

defmodule HL7.Segment.PV1 do
  @moduledoc "3.4.3 PV1 - patient visit segment"
  alias HL7.Composite.PL
  alias HL7.Composite.XCN

  segment "PV1" do
    field :set_id,                     seq:  1, type: :integer,  length:  4
    field :patient_class,              seq:  2, type: :string,   length:  1
    field :assigned_patient_location,  seq:  3, type: PL,        length: 32
    field :admission_type,             seq:  4, type: :string,   length: 34
    field :attending_doctor,           seq:  7, type: XCN,       length: 94
    field :referring_doctor,           seq:  8, type: XCN,       length: 94
    field :hospital_service,           seq: 10, type: :string,   length: 99
    field :readmission_indicator,      seq: 13, type: :string,   length:  2
    field :bad_debt_transfer_amount,   seq: 32, type: :float,    length: 12
    field :bad_debt_recovery_amount,   seq: 33, type: :float,    length: 12
    field :discharge_diposition,       seq: 36, type: :string,   length:  3
    field :admit_datetime,             seq: 44, type: :datetime, length: 12
    field :discharge_datetime,         seq: 45, type: :datetime, length: 12
    field :current_patient_balance,    seq: 46, type: :float,    length: 12
    field :total_charges,              seq: 47, type: :float,    length: 12
    field :total_adjustments,          seq: 48, type: :float,    length: 12
    field :total_payments,             seq: 49, type: :float,    length: 12
    field :visit_indicator,            seq: 51, type: :string,   length:  1
  end
end

defmodule HL7.Segment.PV2 do
  @moduledoc "3.4.4 PV2 - patient visit - additional information segment"
  alias HL7.Composite.CE

  segment "PV2" do
    field :transfer_reason,            seq:  4, type: CE,        length: 94
  end
end

defmodule HL7.Segment.QAK do
  @moduledoc "5.5.2 QAK - query acknowledgment segment"
  alias HL7.Composite.CE

  segment "QAK" do
    field :query_tag,                  seq:  1, type: :string,   length: 32
    field :query_response_status,      seq:  2, type: :string,   length:  4
    field :query_name,                 seq:  3, type: CE,        length: 35
  end
end

# QPD_Q15
defmodule HL7.Segment.QPD do
  @moduledoc "5.5.3 QPD - query parameter definition - procedure totals"
  alias HL7.Composite.CE
  alias HL7.Composite.CM_QPD
  alias HL7.Composite.CX

  segment "QPD" do
    field :query_name,                 seq:  1, type: CE,        length: 51
    field :query_tag,                  seq:  2, type: :string,   length: 32
    field :provider,                   seq:  3, type: CM_QPD,    length: 20
    field :start_date,                 seq:  4, type: :datetime, length: 12
    field :end_date,                   seq:  5, type: :datetime, length: 12
    field :procedure,                  seq:  6, type: CE,        length: 39
    field :authorizer,                 seq:  7, type: CX,        length:  6
  end
end

defmodule HL7.Segment.RCP do
  @moduledoc "5.5.5 RCP - response control parameter segment"
  alias HL7.Composite.CE
  alias HL7.Composite.CQ

  segment "RCP" do
    field :query_priority,             seq:  1, type: :string,   length:  1
    field :quantity_limited_request,   seq:  2, type: CQ,        length: 14
    field :response_modality,          seq:  3, type: CE,        length: 10
    field :execution_datetime,         seq:  4, type: :datetime, length: 12
    field :sort_by,                    seq:  6, type: :string,   length: 512
  end
end

defmodule HL7.Segment.RF1 do
  @moduledoc "11.6.1 RF1 - referral information segment"
  alias HL7.Composite.CE
  alias HL7.Composite.EI

  segment "RF1" do
    field :referral_status,            seq:  1, type: CE,        length: 21
    field :referral_type,              seq:  3, type: CE,        length: 21
    field :originating_referral,       seq:  6, type: EI,        length: 15
    field :effective_datetime,         seq:  7, type: :datetime, length: 12
    field :expiration_datetime,        seq:  8, type: :datetime, length: 12
    field :process_datetime,           seq:  9, type: :datetime, length: 12
    field :referral_reason,            seq: 10, type: CE,        length: 21
  end
end

# Custom segments
defmodule HL7.Segment.ZAU do
  @moduledoc "Procedure authorization information"
  alias HL7.Composite.CE
  alias HL7.Composite.CP
  alias HL7.Composite.EI

  segment "ZAU" do
    field :authorization,              seq:  1, type: EI,        length: 15
    field :payor_control,              seq:  2, type: EI,        length: 15
    field :authorization_status,       seq:  3, type: CE,        length: 20
    field :pre_authorization,          seq:  4, type: EI,        length: 15
    field :pre_authorization_date,     seq:  5, type: :date,     length:  8
    field :copay,                      seq:  6, type: CP,        length: 21
  end
end

defmodule HL7.Segment.ZIN do
  @moduledoc "Additional insurance information"
  alias HL7.Composite.CE

  segment "ZIN" do
    field :eligibility_indicator,      seq:  1, type: :string,   length:  1
    field :patient_vat_status,         seq:  2, type: CE,        length: 12
    field :coverage,                   seq:  3, type: CE,        length: 18
  end
end
