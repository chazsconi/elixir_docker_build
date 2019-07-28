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

  @doc "Create a new dockerfile from the `config`"
  def new(%Config{} = config) do
    %DF{config: config}
  end

  @doc "Docker `FROM source`"
  def from(%DF{} = df, source) do
    df
    |> add_line("FROM", source)
  end

  @doc "Docker `RUN arg`.  If a list of `args` is given they are joined with `&&`"
  def run(df, arg_or_args)

  def run(%DF{} = df, args) when is_list(args) do
    df
    |> run(Enum.join(args, " && "))
  end

  def run(%DF{} = df, arg), do: add_line(df, "RUN", arg)

  @doc "Docker `COPY arg`"
  def copy(%DF{} = df, arg), do: add_line(df, "COPY", arg)

  @doc "Docker `WORKDIR arg`"
  def workdir(%DF{} = df, arg), do: add_line(df, "WORKDIR", arg)

  @doc "Docker `ENV arg`"
  def env(%DF{} = df, arg), do: add_line(df, "ENV", arg)

  @doc "Docker `CMD arg`.  If a list of `args` is given the the list is passed to `CMD`"
  def cmd(df, arg_or_args)

  def cmd(%DF{} = df, args) when is_list(args) do
    df
    |> cmd(inspect(args))
  end

  def cmd(%DF{} = df, arg), do: add_line(df, "CMD", arg)

  @doc "Docker `ENTRYPOINT arg`.  If a list of `args` is given the the list is passed to `ENTRYPOINT`"
  def entrypoint(df, arg_or_args)

  def entrypoint(%DF{} = df, args) when is_list(args) do
    df
    |> entrypoint(inspect(args))
  end

  def entrypoint(%DF{} = df, arg), do: add_line(df, "ENTRYPOINT", arg)

  defimpl String.Chars do
    @doc "Outputs the dockerfile as a String"
    def to_string(%DF{instructions: instructions}) do
      instructions
      |> Enum.map(fn {instruction, arg} -> "#{instruction} #{arg}" end)
      |> Enum.join("\n")
    end
  end
end
