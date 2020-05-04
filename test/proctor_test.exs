defmodule ProctorTest do
  use ExUnit.Case

  alias Mastery.Examples.Math
  alias Mastery.Boundary.QuizSession

  @moduletag capture_log: true

  test "quizzes can be scheduled" do
    quiz = Math.quiz_fields() |> Map.put(:title, :timed_addition)
    now = DateTime.utc_now()
    email = "student@example.com"

    assert :ok ==
             Mastery.schedule_quiz(
               quiz,
               [Math.template_fields()],
               DateTime.add(now, 50, :millisecond),
               DateTime.add(now, 100, :millisecond),
               self()
             )

    refute Mastery.take_quiz(quiz.title, email)

    assert_receive {:started, :timed_addition}
    assert Mastery.take_quiz(quiz.title, email)

    assert_receive {:stopped, :timed_addition}
    assert [] == QuizSession.active_sessions_for(quiz.title)
  end

  test "multiple quizzes can be scheduled concurrently" do
    quiz_one = Math.quiz_fields() |> Map.put(:title, :timed_addition_one)
    quiz_two = Math.quiz_fields() |> Map.put(:title, :timed_addition_two)
    email = "student@example.com"
    now = DateTime.utc_now()

    assert :ok ==
             Mastery.schedule_quiz(
               quiz_one,
               [Math.template_fields()],
               DateTime.add(now, 50, :millisecond),
               DateTime.add(now, 100, :millisecond),
               self()
             )

    assert :ok ==
             Mastery.schedule_quiz(
               quiz_two,
               [Math.template_fields()],
               DateTime.add(now, 60, :millisecond),
               DateTime.add(now, 110, :millisecond),
               self()
             )

    assert_receive {:started, :timed_addition_one}
    assert_receive {:started, :timed_addition_two}
    assert Mastery.take_quiz(quiz_one.title, email)
    assert Mastery.take_quiz(quiz_two.title, email)

    assert_receive {:stopped, :timed_addition_one}
    assert [] == QuizSession.active_sessions_for(quiz_one.title)

    assert_receive {:stopped, :timed_addition_two}
    assert [] == QuizSession.active_sessions_for(quiz_two.title)
  end
end
