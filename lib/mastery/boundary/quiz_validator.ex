defmodule Mastery.Boundary.QuizValidator do
  import Mastery.Boundary.Validator

  def errors(fields) when is_map(fields) do
    []
    |> require(fields, :title, &validate_title/1)
    |> optional(fields, :mastery, &validate_mastery/1)
  end

  def errors(_fields), do: [{nil, "A Map of fields is required"}]

  def validate_title(title), do: validate_string(title)

  def validate_mastery(mastery) when is_integer(mastery) do
    check(mastery >= 1, {:error, "must be greater than zero"})
  end

  def validate_mastery(_mastery), do: {:error, "must be an integer"}

  def validate_answer(answer), do: validate_string(answer)

  defp validate_string(string) when is_binary(string) do
    check(String.match?(string, ~r{\S}), {:error, "can't be blank"})
  end

  defp validate_string(_string), do: {:error, "must be a binary"}
end
