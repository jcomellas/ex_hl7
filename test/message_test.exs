Code.require_file "test_helper.exs", __DIR__

defmodule HL7.Message.Test do
  use ExUnit.Case

  test "Manually generate HL7 message" do
    alias HL7.Segment.{MSH,PID,PR1,PRD}
    alias HL7.Composite.{CE,CM_MSH_9,CM_PRD_7,CX,HD,FN,XAD,XPN}

    msh = %MSH{
      field_separator: "|",
      encoding_chars: "^~\\&",
      sending_app: %HD{namespace_id: "CLIENTHL7"},
      sending_facility: %HD{namespace_id: "CLI01020304"},
      receiving_app: %HD{namespace_id: "SERVHL7"},
      receiving_facility: %HD{namespace_id: "PREPAGA", universal_id: "112233", universal_id_type: "IIN"},
      message_datetime: {{2012, 2, 1}, {10, 11, 55}},
      message_type: %CM_MSH_9{id: "ZQA", trigger_event: "Z02", structure: "ZQA_Z02"},
      message_control_id: "00XX20120201101155",
      processing_id: "P",
      version: "2.4",
      accept_ack_type: "ER",
      app_ack_type: "SU",
      country_code: "ARG"
    }
    prd = %PRD{
      role: [%CE{id: "PS"}, %CE{id: "4600", coding_system: "HL70454"}],
      address: %XAD{state: "B"},
      id: %CM_PRD_7{id: "30123456789", id_type: "CU"}
    }
    pid = %PID{
      set_id: 0,
      patient_id: %CX{
        id: "1234567890ABC",
        assigning_authority: %HD{universal_id: "112233", universal_id_type: "IIN"},
        id_type: "HC"
      },
      patient_name: %XPN{family_name: %FN{surname: "unknown"}}
    }
    pr1 = %PR1{
      set_id: 1,
      procedure: %CE{id: "903401", coding_system: "99DH"}
    }
    trim =
      "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\r" <>
      "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\r" <>
      "PR1|1||903401^^99DH\r"
    gen = HL7.write([msh, prd, pid, pr1], output_format: :wire, trim: true)
    assert trim === IO.iodata_to_binary(gen)
  end

  test "Read/write complete trimmed request in wire format" do
    orig =
      "MSH|^~\\&|CLIENTHL7|CLI01020304^|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\r" <>
      "PRD|PS^^~4600^^HL70454||^^^B^||||30123456789^CU^\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown^\r" <>
      "PR1|1||903401^^99DH\r" <>
      "AUT||112233^||||||1|0\r" <>
      "PR1|2||904620^^99DH\r" <>
      "AUT||112233^||||||1|0\r"
    trim =
      "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\r" <>
      "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\r" <>
      "PR1|1||903401^^99DH\r" <>
      "AUT||112233||||||1|0\r" <>
      "PR1|2||904620^^99DH\r" <>
      "AUT||112233||||||1|0\r"
    {:ok, msg} = HL7.read(orig, input_format: :wire, trim: true)
    gen = HL7.write(msg, output_format: :wire, trim: true)
    assert trim === IO.iodata_to_binary(gen)
  end

  test "Read/write complete trimmed request in stdio format" do
    orig =
      """
      MSH|^~\\&|CLIENTHL7|CLI01020304^|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG
      PRD|PS^^~4600^^HL70454||^^^B^||||30123456789^CU^
      PID|0||1234567890ABC^^^&112233&IIN^HC||unknown^
      PR1|1||903401^^99DH
      AUT||112233^||||||1|0
      PR1|2||904620^^99DH
      AUT||112233^||||||1|0
      """
    trim =
      """
      MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG
      PRD|PS~4600^^HL70454||^^^B||||30123456789^CU
      PID|0||1234567890ABC^^^&112233&IIN^HC||unknown
      PR1|1||903401^^99DH
      AUT||112233||||||1|0
      PR1|2||904620^^99DH
      AUT||112233||||||1|0
      """
    {:ok, msg} = HL7.read(orig, input_format: :text, trim: true)
    gen = HL7.write(msg, output_format: :text, trim: true)
    assert trim === IO.iodata_to_binary(gen)
  end

  # test "Read trimmed request in wire format and write it untrimmed in stdio format" do
  #   trim =
  #     "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\r" <>
  #     "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\r" <>
  #     "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\r" <>
  #     "PR1|1||903401^^99DH\r" <>
  #     "AUT||112233||||||1|0\r" <>
  #     "PR1|2||904620^^99DH\r" <>
  #     "AUT||112233||||||1|0\r"
  #   full =
  #     """
  #     MSH|^~\\&|CLIENTHL7^^|CLI01020304^^|SERVHL7^^|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG|
  #     PRD|PS^^^^^~4600^^HL70454^^^||^^^B&&^^^^^||||30123456789^CU^
  #     PID|0||1234567890ABC^^^&112233&IIN^HC^&&^^||unknown^^^^^^^^&&&&&^&^
  #     PR1|1||903401^^99DH^^^|||
  #     AUT||112233^^^^^||||||1|0|
  #     PR1|2||904620^^99DH^^^|||
  #     AUT||112233^^^^^||||||1|0|
  #     """
  #   {:ok, msg} = HL7.read(trim, input_format: :wire, trim: true)
  #   gen = HL7.write(msg, output_format: :text, trim: false)
  #   assert full === IO.iodata_to_binary(gen)
  # end

  test "Read/write complete trimmed response in wire format" do
    orig =
      "MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG\r" <>
      "MSA|AA|00XX20120201101155\r" <>
      "AUT|4^Cart. 4|112233||20120201094256||4928307\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "NTE|1|||\r"
    trim =
      "MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG\r" <>
      "MSA|AA|00XX20120201101155\r" <>
      "AUT|4^Cart. 4|112233||20120201094256||4928307\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "NTE|1\r"
    {:ok, msg} = HL7.read(orig, input_format: :wire, trim: true)
    gen = HL7.write(msg, output_format: :wire, trim: true)
    assert trim === IO.iodata_to_binary(gen)
  end

  test "Read/write complete trimmed response in stdio format" do
    orig =
      """
      MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG
      MSA|AA|00XX20120201101155
      AUT|4^Cart. 4|112233||20120201094256||4928307
      PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU
      PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P
      IN1|1|4^Cart. 4|112233
      ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador
      PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||
      OBX|1||||||||||F
      AUT||112233||||||1|1
      PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||
      OBX|2||||||||||F
      AUT||112233||||||1|1
      NTE|1|||
      """
    trim =
      """
      MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG
      MSA|AA|00XX20120201101155
      AUT|4^Cart. 4|112233||20120201094256||4928307
      PRD|PS~46.00^Radiologia General|Prestador Radiologico|^^^B||||30123456789^CU
      PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P
      IN1|1|4^Cart. 4|112233
      ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador
      PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH
      OBX|1||||||||||F
      AUT||112233||||||1|1
      PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH
      OBX|2||||||||||F
      AUT||112233||||||1|1
      NTE|1
      """
    {:ok, msg} = HL7.read(orig, input_format: :text, trim: true)
    gen = HL7.write(msg, output_format: :text, trim: true)
    assert trim === IO.iodata_to_binary(gen)
  end

  test "Read partial response in wire format" do
    part1 =
      "MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG\r" <>
      "MSA|AA|00XX20120201101155\r" <>
      "AUT|4^Cart. 4|112233||20120201094256||4928307\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112"
    part2 =
      "233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "NTE|1|||\r"
    {:incomplete, {function, rest}} = HL7.read(part1, input_format: :wire, trim: true)
    rest = rest <> part2
    {:ok, msg} = function.(rest)
    assert HL7.segment(msg, "MSH") !== nil
  end

  test "Retrieve segments from message" do
    buf =
      "MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG\r" <>
      "MSA|AA|00XX20120201101155\r" <>
      "AUT|4^Cart. 4|112233||20120201094256||4928307\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "NTE|1|||\r"
    reader = HL7.Reader.new(input_format: :wire, trim: true)
    {:ok, msg} = HL7.Message.read(reader, buf)
    # Check the number of segment
    assert HL7.Message.segment_count(msg, "AUT") === 3
    # Try to retrieve segments that are not present
    assert nil === HL7.Message.segment(msg, "PV1")
    assert nil === HL7.Message.segment(msg, "XXX")
    # Retrieve segment from message with implicit position
    aut = HL7.Message.segment(msg, "AUT")
    assert aut !== nil
    assert aut.plan.id === "4"
    assert aut.plan.text === "Cart. 4"
    assert aut.authorization.id === "4928307"
    # Retrieve segment from message with explicit position
    pr1 = HL7.Message.segment(msg, "PR1", 0)
    assert pr1 !== nil
    assert pr1.set_id === 1
    assert pr1.procedure.id === "90.34.01"
    assert pr1.procedure.text === "RESONANCIA MAGNETICA NUCLEAR"
    pr1 = HL7.Message.segment(msg, "PR1", 1)
    assert pr1 !== nil
    assert pr1.set_id === 2
    assert pr1.procedure.id === "90.46.20"
    assert pr1.procedure.text === "GADOLINEO EN AMBULATORIO."
    # Retrieve paired segments from message with explicit position
    segments = HL7.Message.paired_segments(msg, ["PR1", "OBX", "AUT"], 0)
    assert length(segments) === 3
    [pr1, obx, aut] = segments
    assert HL7.segment_id(pr1) === "PR1"
    assert pr1.set_id === 1
    assert HL7.segment_id(obx) === "OBX"
    assert obx.set_id === 1
    assert HL7.segment_id(aut) === "AUT"
    assert aut.requested_treatments === 1
    segments = HL7.Message.paired_segments(msg, ["PR1", "OBX", "AUT"], 1)
    assert length(segments) === 3
    [pr1, obx, aut] = segments
    assert HL7.segment_id(pr1) === "PR1"
    assert pr1.set_id === 2
    assert HL7.segment_id(obx) === "OBX"
    assert obx.set_id === 2
    assert HL7.segment_id(aut) === "AUT"
    assert aut.requested_treatments === 1
    # Try to retrieve inexistent paired segments
    assert [] === HL7.Message.paired_segments(msg, ["PR1", "OBX", "AUT"], 2)
    # Retrieve partial paired segments
    segments = HL7.Message.paired_segments(msg, ["PR1", "AUT"], 1)
    assert length(segments) === 1
    [pr1] = segments
    assert HL7.segment_id(pr1) === "PR1"
    assert pr1.set_id === 2
    # Process all paired segments
    acc = HL7.reduce_paired_segments(msg, ["PR1", "OBX", "AUT"], 0, [], fn paired_segments, index, acc0 ->
      value =
        for segment <- paired_segments do
          case HL7.segment_id(segment) do
            "PR1" -> {index, "PR1", segment.set_id, segment.procedure.id}
            "OBX" -> {index, "OBX", segment.set_id}
            "AUT" -> {index, "AUT"}
          end
        end
      [value | acc0]
    end)
    assert [[{0, "PR1", 1, "90.34.01"}, {0, "OBX", 1}, {0, "AUT"}],
            [{1, "PR1", 2, "90.46.20"}, {1, "OBX", 2}, {1, "AUT"}]] === Enum.reverse(acc)
  end

  test "Delete/Insert/Replace segments into a message" do
    alias HL7.Segment.OBX
    alias HL7.Segment.NTE
    buf =
      "MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG\r" <>
      "MSA|AA|00XX20120201101155\r" <>
      "AUT|4^Cart. 4|112233||20120201094256||4928307\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "NTE|1|||\r"
    {:ok, msg} = HL7.read(buf, input_format: :wire, trim: true)
    assert HL7.segment(msg, "OBX", 1) !== nil
    assert HL7.segment(msg, "OBX", 0) !== nil
    msg = HL7.delete(msg, "OBX", 1)
    msg = HL7.delete(msg, "OBX", 0)
    assert HL7.segment(msg, "OBX") === nil
    msg = HL7.insert_after(msg, "PR1", 0, %OBX{set_id: 1, observation_status: "F"})    
    assert HL7.segment(msg, "OBX", 0) !== nil
    msg = HL7.insert_before(msg, "AUT", 2, %OBX{set_id: 2, observation_status: "F"})    
    assert HL7.segment(msg, "OBX", 1) !== nil
    assert length(HL7.paired_segments(msg, ["PR1", "OBX"], 0)) === 2
    assert length(HL7.paired_segments(msg, ["PR1", "OBX"], 1)) === 2
    msg = HL7.replace(msg, "NTE", 0, [%NTE{set_id: 1, comment: "First"},
                                      %NTE{set_id: 2, comment: "Second"}])
    assert HL7.segment(msg, "NTE", 0).comment === "First"
    assert HL7.segment(msg, "NTE", 1).comment === "Second"
  end

  @vertical_tab 0x0b
  @file_separator 0x1c
  @carriage_return 0x0d

  test "Add/remove MLLP framing to encoded HL7 message" do
    buf =
      "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\r" <>
      "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\r" <>
      "PR1|1||903401^^99DH\r"
    # Add/remove MLLP framing to binary.
    mllp_buf = IO.iodata_to_binary([@vertical_tab, buf, @file_separator, @carriage_return])
    incomplete_buf = [@vertical_tab, buf]
    {:ok, msg} = HL7.read(buf, input_format: :wire, trim: true)
    msg_buf = HL7.write(msg, output_format: :wire, trim: true)
    mllp_msg_buf = HL7.to_mllp(msg_buf)
    assert buf === HL7.from_mllp!(mllp_buf)
    assert IO.iodata_to_binary(mllp_buf) === IO.iodata_to_binary(HL7.to_mllp(buf))
    assert :incomplete === HL7.from_mllp(incomplete_buf)
    assert {:error, :bad_mllp_framing} === HL7.from_mllp(buf)
    assert mllp_buf === IO.iodata_to_binary(HL7.to_mllp(buf))
    assert msg_buf === HL7.from_mllp!(mllp_msg_buf)
  end
end
