defmodule HL7.Segment.Default.Builder do
  @moduledoc """
  Builder for the default HL7 segments
  """
  require HL7.Segment.Default.AUT, as: AUT
  require HL7.Segment.Default.DG1, as: DG1
  require HL7.Segment.Default.DSC, as: DSC
  require HL7.Segment.Default.DSP, as: DSP
  require HL7.Segment.Default.ERR, as: ERR
  require HL7.Segment.Default.EVN, as: EVN
  require HL7.Segment.Default.IN1, as: IN1
  require HL7.Segment.Default.MSA, as: MSA
  require HL7.Segment.Default.MSH, as: MSH
  require HL7.Segment.Default.NTE, as: NTE
  require HL7.Segment.Default.OBX, as: OBX
  require HL7.Segment.Default.PID, as: PID
  require HL7.Segment.Default.PR1, as: PR1
  require HL7.Segment.Default.PRD, as: PRD
  require HL7.Segment.Default.PV1, as: PV1
  require HL7.Segment.Default.PV2, as: PV2
  require HL7.Segment.Default.QAK, as: QAK
  require HL7.Segment.Default.QPD, as: QPD
  require HL7.Segment.Default.RCP, as: RCP
  require HL7.Segment.Default.RF1, as: RF1
  require HL7.Segment.Default.ZAU, as: ZAU
  require HL7.Segment.Default.ZIN, as: ZIN

  @behaviour HL7.Segment.Builder

  @segment_ids %{
    AUT.id() => AUT,
    DG1.id() => DG1,
    DSC.id() => DSC,
    DSP.id() => DSP,
    ERR.id() => ERR,
    EVN.id() => EVN,
    IN1.id() => IN1,
    MSA.id() => MSA,
    MSH.id() => MSH,
    NTE.id() => NTE,
    OBX.id() => OBX,
    PID.id() => PID,
    PR1.id() => PR1,
    PRD.id() => PRD,
    PV1.id() => PV1,
    PV2.id() => PV2,
    QAK.id() => QAK,
    QPD.id() => QPD,
    RCP.id() => RCP,
    RF1.id() => RF1,
    ZAU.id() => ZAU,
    ZIN.id() => ZIN
  }

  def segment_module(segment_id), do: Map.fetch(@segment_ids, segment_id)

  def segment_spec(segment_id) do
    with {:ok, segment_mod} <- segment_module(segment_id) do
      {:ok, segment_mod.spec()}
    end
  end

  def new(segment_id) do
    with {:ok, segment_mod} <- segment_module(segment_id) do
      {:ok, {struct(segment_mod), segment_mod.spec()}}
    end
  end

  def new(segment_id, args) do
    with {:ok, segment_mod} <- segment_module(segment_id) do
      {:ok, {struct(segment_mod, args), segment_mod.spec()}}
    end
  end
end
