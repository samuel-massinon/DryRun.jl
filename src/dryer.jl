

macro dryer(expr)

    isa(expr, Expr) || error("argument is not an expression")
    expr.head == :do && (expr = rewrite_do(expr))
    expr.head == :call || error("expression is not a function call")

    target = expr.args[1]
    args = filter(!Mocking.iskwarg, expr.args[2:end])
    kwargs = Mocking.extract_kwargs(expr)

    args_var = gensym("args")
    alternate_var = gensym("alt")

    result = quote
        if DryRun.activated()
            # println($target, "(", $(args...), ";", $(kwargs...), ")")
            # println($target, "(", (join(repr.(($(args...),)), ", ")), ";", $(kwargs...), ")")
            println($target, "(", (join(repr.(($(args...),)), ", ")), ")")
        else
            $target($(args...); $(kwargs...))
        end
    end

    return esc(result)
end
