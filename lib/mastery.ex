defmodule Mastery do
  alias Mastery.Boundary.{QuizSession, QuizManager}
  alias Mastery.Boundary.{TemplateValidator, QuizValidator}
  alias Mastery.Core.Quiz

  @doc """
  Starts a new QuizManager process with the name "QuizManager"
  """
  def start_quiz_manager() do
    GenServer.start_link(QuizManager, %{}, name: QuizManager)
  end

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
         {:ok, session} <- GenServer.start_link(QuizSession, {quiz, email}) do
      session
    else
      error -> error
    end
  end

  @doc """
  Selects a question for a given QuizSession
  """
  def select_question(session) do
    GenServer.call(session, :select_question)
  end

  @doc """
  Given a QuizSession and a provided answer, submits that answer to the session.
  """
  def answer_question(session, answer) do
    with :ok <- QuizValidator.validate_answer(answer),
         :ok <- GenServer.call(session, {:answer_question, answer}),
         do: :ok,
         else: (error -> error)
  end
end
