defmodule Mix.Tasks.Surface.Init.Patchers.MixExs do
  @moduledoc false

  # Common patches for `mix.exs`

  import Mix.Tasks.Surface.Init.ExPatcher

  def add_compiler(code, compiler) do
    code
    |> parse_string!()
    |> enter_defmodule()
    |> enter_def(:project)
    |> find_keyword_value(:compilers)
    |> halt_if(
      fn patcher -> node_to_string(patcher) == "[:gettext] ++ Mix.compilers() ++ [#{compiler}]" end,
      :already_patched
    )
    |> halt_if(&find_code_containing(&1, compiler), :maybe_already_patched)
    |> append_child(" ++ [#{compiler}]")
  end

  def add_dep(code, dep, opts) do
    code
    |> parse_string!()
    |> enter_defmodule()
    |> enter_defp(:deps)
    |> halt_if(&find_list_item_containing(&1, "{#{dep}, "), :already_patched)
    |> append_list_item(~s({#{dep}, #{opts}}), preserve_indentation: true)
  end

  def append_def(code, def, body) do
    code
    |> parse_string!()
    |> enter_defmodule()
    |> halt_if(&find_def(&1, def), :already_patched)
    |> last_child()
    |> replace_code(
      &"""
      #{&1}

        def #{def} do
      #{body}
        end\
      """
    )
  end

  def add_elixirc_paths_entry(code, env, body, already_pached_text) do
    code
    |> parse_string!()
    |> enter_defmodule()
    |> halt_if(
      fn patcher ->
        patcher
        |> find_defp_with_args(:elixirc_paths, &match?([^env], &1))
        |> body()
        |> find_code(already_pached_text)
      end,
      :already_patched
    )
    |> halt_if(
      fn patcher -> find_defp_with_args(patcher, :elixirc_paths, &match?([^env], &1)) end,
      :maybe_already_patched
    )
    |> find_code(~S|defp elixirc_paths(_), do: ["lib"]|)
    |> replace(&"defp elixirc_paths(#{env}), do: #{body}\n  #{&1}")
  end
end
