defmodule Mastery do
  alias Mastery.Boundary.{QuizSession, QuizManager, Proctor}
  alias Mastery.Boundary.{TemplateValidator, QuizValidator}
  alias Mastery.Core.Quiz

  @persistence_fn Application.get_env(:mastery, :persistence_fn)

  @doc """
  Builds a quiz on the (hopefully) already-started QuizManager from the provided quiz fields.
  """
  def build_quiz(fields) do
    with :ok <- QuizValidator.errors(fields),
         :ok <- GenServer.call(QuizManager, {:build_quiz, fields}),
         do: :ok,
         else: (error -> error)
  end

  @doc """
  Takes a title and some Template fields, and adds a corresponding template to a quiz with the
  provided title.
  """
  def add_template(title, fields) do
    with :ok <- TemplateValidator.errors(fields),
         :ok <- GenServer.call(QuizManager, {:add_template, title, fields}),
         do: :ok,
         else: (error -> error)
  end

  @doc """
  Given a Quiz title and an email address, starts a new QuizSession for the corresponding Quiz.
  """
  def take_quiz(title, email) do
    with %Quiz{} = quiz <- QuizManager.lookup_quiz_by_title(title),
         {:ok, _} <- QuizSession.take_quiz(quiz, email) do
      {title, email}
    else
      error -> error
    end
  end

  @doc """
  Selects a question for a given QuizSession
  """
  def select_question(name) do
    QuizSession.select_question(name)
  end

  @doc """
  Given a QuizSession and a provided answer, submits that answer to the session.
  """
  def answer_question(name, answer, persistence_fn \\ @persistence_fn) do
    with :ok <- QuizValidator.validate_answer(answer),
         :ok <- QuizSession.answer_question(name, answer, persistence_fn),
         do: :ok,
         else: (error -> error)
  end

  def schedule_quiz(quiz, templates, start_at, end_at) do
    with :ok <- QuizValidator.errors(quiz),
         true <- Enum.all?(templates, &(:ok == TemplateValidator.errors(&1))),
         :ok <- Proctor.schedule_quiz(quiz, templates, start_at, end_at),
         do: :ok,
         else: (error -> error)
  end
end
