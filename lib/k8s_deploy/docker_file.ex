defmodule K8SDeploy.Dockerfile do
  @moduledoc """
  Create a dockerfile
  """

  alias __MODULE__, as: DF
  alias K8SDeploy.Config
  defstruct instructions: [], config: %Config{}

  @doc "Adds an arbitary instruction"
  def add_line(%DF{instructions: instructions} = df, instuction, arg) do
    %DF{df | instructions: instructions ++ [{instuction, arg}]}
  end

  def new(%Config{} = config) do
    %DF{config: config}
  end

  def from(%DF{} = df, source) do
    df
    |> add_line("FROM", source)
  end

  def run(%DF{} = df, args) when is_list(args) do
    df
    |> run(Enum.join(args, " && "))
  end

  def run(%DF{} = df, arg), do: add_line(df, "RUN", arg)
  def copy(%DF{} = df, arg), do: add_line(df, "COPY", arg)
  def workdir(%DF{} = df, arg), do: add_line(df, "WORKDIR", arg)
  def env(%DF{} = df, arg), do: add_line(df, "ENV", arg)

  def cmd(%DF{} = df, args) when is_list(args) do
    df
    |> cmd(inspect(args))
  end

  def cmd(%DF{} = df, arg), do: add_line(df, "CMD", arg)

  def entrypoint(%DF{} = df, args) when is_list(args) do
    df
    |> entrypoint(inspect(args))
  end

  def entrypoint(%DF{} = df, arg), do: add_line(df, "ENTRYPOINT", arg)

  defimpl String.Chars do
    def to_string(%DF{instructions: instructions}) do
      instructions
      |> Enum.map(fn {instruction, arg} -> "#{instruction} #{arg}" end)
      |> Enum.join("\n")
    end
  end
end
