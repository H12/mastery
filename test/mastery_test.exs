defmodule MasteryTest do
  use ExUnit.Case
  use QuizBuilders
  alias MasteryPersistence.Repo
  alias Mastery.Examples.Math
  alias Mastery.Boundary.QuizSession
  alias MasteryPersistence.Response

  setup do
    enable_persistence()

    always_add_1_to_2 = [
      template_fields(generators: addition_generators([1], [2]))
    ]

    assert "" != ExUnit.CaptureLog.capture_log(fn -> :ok = start_quiz(always_add_1_to_2) end)

    :ok
  end

  defp enable_persistence() do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  defp response_count() do
    Repo.aggregate(Response, :count, :id)
  end

  defp start_quiz(fields) do
    now = DateTime.utc_now()
    ending = DateTime.add(now, 60)

    Mastery.schedule_quiz(Math.quiz_fields(), fields, now, ending)
  end

  defp take_quiz(email) do
    Mastery.take_quiz(Math.quiz().title, email)
  end

  defp select_question(session) do
    assert Mastery.select_question(session) == "1 + 2"
  end

  defp give_wrong_answer(session) do
    Mastery.answer_question(
      session,
      "wrong",
      &MasteryPersistence.record_response/2
    )
  end

  defp give_right_answer(session) do
    Mastery.answer_question(
      session,
      "3",
      &MasteryPersistence.record_response/2
    )
  end

  test "Take a quiz, manage lifecycle and persist responses" do
    session = take_quiz("yes_mathter@example.com")

    select_question(session)
    assert give_wrong_answer(session) == {"1 + 2", false}
    assert give_right_answer(session) == {"1 + 2", true}
    assert response_count() > 0

    assert give_right_answer(session) == :finished
    assert QuizSession.active_sessions_for(Math.quiz_fields().title) == []
  end

  test "Reports validation errors when building quizzes" do
    missing_title = Map.delete(Math.quiz_fields(), :title)
    invalid_title = Map.put(Math.quiz_fields(), :title, "tortle")
    invalid_mastery = Map.put(Math.quiz_fields(), :mastery, "3")

    assert [title: "is required"] == Mastery.build_quiz(missing_title)
    assert [title: "must be an atom"] == Mastery.build_quiz(invalid_title)
    assert [mastery: "must be an integer"] == Mastery.build_quiz(invalid_mastery)
  end

  test "Reports validation errors when adding templates" do
    Mastery.build_quiz(Math.quiz_fields())
    quiz_title = Math.quiz_fields().title
    bad_generators = template_fields(generators: %{"not an atom" => "not a list or function"})

    # Validates required fields are present
    assert [:name, :category, :raw, :generators, :checker] ==
             Mastery.add_template(quiz_title, []) |> Keyword.keys()

    # Validates template generators are the correct format
    assert [generators: {:error, "must be a string to list or function pair"}] ==
             Mastery.add_template(quiz_title, bad_generators)
  end

  test "Reports validation errors when scheduling quizzes" do
    missing_title = Map.delete(Math.quiz_fields(), :title)
    now = DateTime.utc_now()

    assert [title: "is required"] == Mastery.schedule_quiz(missing_title, [], now, now)
  end
end
