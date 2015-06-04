Code.require_file "test_helper.exs", __DIR__

defmodule HL7.Message.Test do
  use ExUnit.Case

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

  test "Read trimmed request in wire format and write it untrimmed in stdio format" do
    trim =
      "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\r" <>
      "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\r" <>
      "PR1|1||903401^^99DH\r" <>
      "AUT||112233||||||1|0\r" <>
      "PR1|2||904620^^99DH\r" <>
      "AUT||112233||||||1|0\r"
    full =
      """
      MSH|^~\\&|CLIENTHL7^^|CLI01020304^^|SERVHL7^^|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG|
      PRD|PS^^^^^~4600^^HL70454^^^||^^^B&&^^^^^||||30123456789^CU^
      PID|0||1234567890ABC^^^&112233&IIN^HC^&&^^||unknown^^^^^^^^&&&&&^&^
      PR1|1||903401^^99DH^^^|||
      AUT||112233^^^^^||||||1|0|
      PR1|2||904620^^99DH^^^|||
      AUT||112233^^^^^||||||1|0|
      """
    {:ok, msg} = HL7.read(trim, input_format: :wire, trim: true)
    gen = HL7.write(msg, output_format: :text, trim: false)
    assert full === IO.iodata_to_binary(gen)
  end

  test "Read/write complete trimmed response in wire format" do
    orig =
      "MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG\r" <>
      "MSA|AA|00XX20120201101155\r" <>
      "AUT|4^Cart. 4|112233||20120201094256||4928307\r" <>
      "ZAU||4928307|B001^AUTORIZADA\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0&$^\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0&$^\r" <>
      "NTE|1|||\r"
    trim =
      "MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG\r" <>
      "MSA|AA|00XX20120201101155\r" <>
      "AUT|4^Cart. 4|112233||20120201094256||4928307\r" <>
      "ZAU||4928307|B001^AUTORIZADA\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0.0&$\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0.0&$\r" <>
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
      ZAU||4928307|B001^AUTORIZADA
      PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU
      PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P
      IN1|1|4^Cart. 4|112233
      ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador
      PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||
      OBX|1||||||||||F
      AUT||112233||||||1|1
      ZAU|||B004^PRESTACION AUTORIZADA|||0&$^
      PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||
      OBX|2||||||||||F
      AUT||112233||||||1|1
      ZAU|||B004^PRESTACION AUTORIZADA|||0&$^
      NTE|1|||
      """
    trim =
      """
      MSH|^~\\&|SERVHL7|^112233^IIN|CLIENTHL7|CLI01020304|20120201094257||ZPA^Z02^ZPA_Z02|7745168|P|2.4|||AL|NE|ARG
      MSA|AA|00XX20120201101155
      AUT|4^Cart. 4|112233||20120201094256||4928307
      ZAU||4928307|B001^AUTORIZADA
      PRD|PS~46.00^Radiologia General|Prestador Radiologico|^^^B||||30123456789^CU
      PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P
      IN1|1|4^Cart. 4|112233
      ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador
      PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH
      OBX|1||||||||||F
      AUT||112233||||||1|1
      ZAU|||B004^PRESTACION AUTORIZADA|||0.0&$
      PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH
      OBX|2||||||||||F
      AUT||112233||||||1|1
      ZAU|||B004^PRESTACION AUTORIZADA|||0.0&$
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
      "ZAU||4928307|B001^AUTORIZADA\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112"
    part2 =
      "233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0&$^\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0&$^\r" <>
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
      "ZAU||4928307|B001^AUTORIZADA\r" <>
      "PRD|PS~46.00^Radiologia General|Prestador Radiologico^|^^^B||||30123456789^CU\r" <>
      "PID|1||1234567890ABC^^^^HC||PEREZ^PEPE P\r" <>
      "IN1|1|4^Cart. 4|112233\r" <>
      "ZIN|Y|EXNT^EXENTO|01002^Contraste a cargo del prestador~01004^Mat. Rad. a cargo del prestador\r" <>
      "PR1|1||90.34.01^RESONANCIA MAGNETICA NUCLEAR^99DH||\r" <>
      "OBX|1||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0&$^\r" <>
      "PR1|2||90.46.20^GADOLINEO EN AMBULATORIO.^99DH||\r" <>
      "OBX|2||||||||||F\r" <>
      "AUT||112233||||||1|1\r" <>
      "ZAU|||B004^PRESTACION AUTORIZADA|||0&$^\r" <>
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
    segments = HL7.Message.paired_segments(msg, ["PR1", "OBX", "AUT", "ZAU"], 0)
    assert length(segments) === 4
    [pr1, obx, aut, zau] = segments
    assert HL7.segment_id(pr1) === "PR1"
    assert pr1.set_id === 1
    assert HL7.segment_id(obx) === "OBX"
    assert obx.set_id === 1
    assert HL7.segment_id(aut) === "AUT"
    assert aut.requested_treatments === 1
    assert HL7.segment_id(zau) === "ZAU"
    assert zau.authorization_status.id === "B004"
    segments = HL7.Message.paired_segments(msg, ["PR1", "OBX", "AUT", "ZAU"], 1)
    assert length(segments) === 4
    [pr1, obx, aut, zau] = segments
    assert HL7.segment_id(pr1) === "PR1"
    assert pr1.set_id === 2
    assert HL7.segment_id(obx) === "OBX"
    assert obx.set_id === 2
    assert HL7.segment_id(aut) === "AUT"
    assert aut.requested_treatments === 1
    assert HL7.segment_id(zau) === "ZAU"
    assert zau.authorization_status.id === "B004"
    # Try to retrieve inexistent paired segments
    assert [] === HL7.Message.paired_segments(msg, ["PR1", "OBX", "AUT", "ZAU"], 2)
    # Retrieve partial paired segments
    segments = HL7.Message.paired_segments(msg, ["PR1", "AUT"], 1)
    assert length(segments) === 1
    [pr1] = segments
    assert HL7.segment_id(pr1) === "PR1"
    assert pr1.set_id === 2
  end
end
