defmodule DockerBuild.Code do
  @moduledoc "Loads extra source code"
  def require_all(paths) when is_list(paths) do
    for path <- paths do
      for file <- list_all_files(path) do
        Code.require_file(file)
      end
    end
  end

  defp list_all_files(filepath) do
    expand(File.ls(filepath), filepath)
  end

  defp expand({:ok, files}, path) do
    files
    |> Enum.flat_map(&list_all_files("#{path}/#{&1}"))
  end

  defp expand({:error, _}, path) do
    if String.ends_with?(path, ".ex") do
      [path]
    else
      []
    end
  end
end
