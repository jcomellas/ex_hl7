defmodule ASCII do
  @moduledoc """
  Module that checks properties of binaries that only contain ASCII characters.
  """

  @doc """
  Checks that the characters in the string are only alphanumeric ASCII characters.
  """
  @spec alphanumeric?(binary) :: boolean
  def alphanumeric?(value), do:
    is?(value, fn char -> (char >= ?A and char <= ?Z) or (char >= ?a and char <= ?z) or
                          (char >= ?0 and char <= ?9) end)

  @doc """
  Checks that the characters in the string are only upper-case alphanumeric
  ASCII characters.
  """
  @spec upper_alphanumeric?(binary) :: boolean
  def upper_alphanumeric?(value), do:
    is?(value, fn char -> (char >= ?A and char <= ?Z) or (char >= ?0 and char <= ?9) end)

  @doc """
  Checks that the characters in the string are only upper-case alphabetic
  ASCII characters.
  """
  @spec upper_alphabetic?(binary) :: boolean
  def upper_alphabetic?(value), do:
    is?(value, fn char -> (char >= ?A and char <= ?Z) end)

  @doc """
  Checks that the characters in the string are printable ASCII and ISO-8859-1
  (Latin 1) characters.
  """
  @spec printable?(binary) :: boolean
  def printable?(""), do:
    true
  def printable?(value), do:
    is?(value, fn char -> (char >= 0x20 and char <= 0x7e) or (char >= 0xa0 and char <= 0xff) end)

  @doc """
  Checks that the characters in the string comply with the function passed as argument.
  """
  @spec is?(binary, (byte -> boolean)) :: boolean 
  def is?(<<>>, _condition), do:
    false
  def is?(value, condition) when is_binary(value), do:
    _is?(value, condition)
  def is?(value, condition) when is_integer(value), do:
    condition.(value)

  def _is?(<<char, rest :: binary>>, condition) do
    case condition.(char) do
      true  -> _is?(rest, condition)
      false -> false
    end
  end
  def _is?(<<>>, _) do
    true
  end

  @doc "Remove all the spaces present to the right of the string."
  @spec rstrip(binary) :: binary
  def rstrip(str), do:
    rstrip(str, <<"\s\t\n\r\f\v">>)

  @doc "Remove all the `chars` present to the right of the string."
  @spec rstrip(binary, byte | binary) :: binary
  def rstrip(str, char) when is_integer(char), do:
    rstrip_char(str, char, byte_size(str) - 1)
  def rstrip(str, chars), do:
    rstrip_bin(str, chars, byte_size(str) - 1)

  defp rstrip_char(str, char, pos) do
    case str do
        <<head :: binary-size(pos), ^char>> ->
          rstrip_char(head, char, pos - 1)
        _ ->
          str
    end
  end

  defp rstrip_bin(str, chars, pos) do
    case str do
      <<head :: binary-size(pos), char>> ->
        if char in chars do
          rstrip_bin(head, chars, pos - 1)
        else
          str
        end
      _ ->
        str
    end
  end

end
