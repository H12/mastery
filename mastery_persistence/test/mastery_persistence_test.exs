defmodule MasteryPersistenceTest do
  use ExUnit.Case
  alias MasteryPersistence.{Response, Repo}

  defp checkout_and_clean_repo do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    # Clear out Responses to account for other test suites
    Repo.delete_all(Response)
  end

  setup do
    checkout_and_clean_repo()

    response = %{
      quiz_title: :simple_addition,
      template_name: :single_digit_addition,
      question: "3 + 4",
      email: "student@example.com",
      answer: "7",
      correct: true,
      timestamp: DateTime.utc_now()
    }

    {:ok, %{response: response}}
  end

  test "responses are recorded", %{response: response} do
    assert Repo.aggregate(Response, :count, :id) == 0
    assert :ok = MasteryPersistence.record_response(response)

    assert Repo.all(Response)
           |> Enum.map(fn r -> r.email end) == [response.email]
  end

  test "a function can be run in the saving transaction", %{response: response} do
    assert response.answer == MasteryPersistence.record_response(response, fn r -> r.answer end)
  end

  test "an error in the function rolls back the save", %{response: response} do
    assert Repo.aggregate(Response, :count, :id) == 0

    assert_raise RuntimeError, fn ->
      MasteryPersistence.record_response(response, fn _r -> raise "oops" end)
    end

    assert Repo.aggregate(Response, :count, :id) == 0
  end

  test "simple reporting", %{response: response} do
    MasteryPersistence.record_response(response)
    MasteryPersistence.record_response(response)

    response
    |> Map.put(:email, "other_#{response.email}")
    |> MasteryPersistence.record_response()

    assert MasteryPersistence.report(response.quiz_title) == %{
             response.email => 2,
             "other_#{response.email}" => 1
           }
  end
end
