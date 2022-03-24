using DryRun
DryRun.activate()

f_return_value = :test

function f(foo, bar; baz)
    return f_return_value
end

function test_dryer(foo, bar; baz)
    return @dryer f(foo, bar)
end

# original_stdout = stdout
# rd, wr = redirect_stdout()
value = test_dryer(:foo, :bar, baz=:baz)

macro dryer(expr)

    isa(expr, Expr) || error("argument is not an expression")
    expr.head == :do && (expr = rewrite_do(expr))
    expr.head == :call || error("expression is not a function call")

    target = expr.args[1]
    args = filter(!Mocking.iskwarg, expr.args[2:end])
    kwargs = Mocking.extract_kwargs(expr)

    args_var = gensym("args")
    alternate_var = gensym("alt")

    # Due to how world-age works (see Julia issue #265 and PR #17057) when
    # `Mocking.activated` is overwritten then all dependent functions will be recompiled.
    # When `Mocking.activated() == false` then Julia will optimize the
    # code below to have zero-overhead by only executing the original expression.
    result = quote
        # if Mocking.activated()
            local $args_var = tuple($(args...))
            local $alternate_var = Mocking.get_alternate($target, $args_var...)
            println($target, "(", $(args...), ";", $(kwargs...), ")")
        # else
            # $target($(args...); $(kwargs...))
        # end
    end

    return esc(result)
end

# macro dryer(expr)
#     result = quote
#         if DryRun.activated()
#             println($(build_expr(expr)))
#         else
#             $expr
#         end
#     end
#     esc(result)
# end

macro dryer_stub(expr, stub_value)
    if DryRun.activated()
        println(expr)
        return stub_value
    else
        return esc(expr)
    end
end

function build_expr(expr)
    if isa(expr, Symbol)
        if isdefined(Main, expr)
            eval(expr)
        else
            expr
        end
    elseif isa(expr, QuoteNode)
        expr
    elseif isa(expr, String)
        expr
    else
        if expr.head == :kw
            expr.args[2] = build_expr(expr.args[2])
            expr
        else
            expr.args[1:end] .= build_expr.(expr.args)
            expr
        end
    end
end
