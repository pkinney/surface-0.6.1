defmodule SurfaceTest do
  use Surface.ConnCase

  doctest Surface, import: true

  import Surface

  describe "quote_surface" do
    test "generate AST" do
      [tag] =
        quote_surface line: 1 do
          ~F"<div>content</div>"
        end

      assert %Surface.AST.Tag{
               element: "div",
               children: [%Surface.AST.Literal{value: "content"}],
               meta: %{line: 1}
             } = tag
    end

    test "using heredocs" do
      [tag | _] =
        quote_surface line: 1 do
          ~F"""
          <div>content</div>
          """
        end

      assert %Surface.AST.Tag{
               element: "div",
               children: [%Surface.AST.Literal{value: "content"}],
               meta: %{line: 1}
             } = tag
    end
  end

  test "raise error when trying to unquote an undefined variable" do
    message = """
    code.ex:2: undefined variable "content".

    Available variable: "message"
    """

    assert_raise(CompileError, message, fn ->
      quote_surface line: 1, file: "code.ex" do
        ~F"""
        <div>
          {^content}
        </div>
        """
      end
    end)
  end

  test "raise error when trying to unquote expressions that are not variables" do
    message = """
    code.ex:2: cannot unquote `to_string(:abc)`.

    The expression to be unquoted must be written as `^var`, where `var` is an existing variable.
    """

    assert_raise(CompileError, message, fn ->
      quote_surface line: 1, file: "code.ex" do
        ~F"""
        <div>
          {^to_string(:abc)}
        </div>
        """
      end
    end)
  end

  test "raise error when not using the ~F sigil" do
    code = """
    quote_surface do
      "\""
      <div>
        {^to_string(:abc)}
      </div>
      "\""
    end
    """

    message = "code.exs:1: the code to be quoted must be wrapped in a `~F` sigil."

    assert_raise(CompileError, message, fn ->
      {{:module, _, _, _}, _} = Code.eval_string(code, [], %{__ENV__ | file: "code.exs", line: 1})
    end)
  end

  test "raise error when using {^...} outside `quote_surface`" do
    message = "code:2: cannot use tagged expression {^var} outside `quote_surface`"

    code =
      quote do
        ~F"""
        <div>
          {^content}
        </div>
        """
      end

    assert_raise(CompileError, message, fn ->
      compile_surface(code)
    end)
  end
end
