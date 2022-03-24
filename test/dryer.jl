using DryRun

@testset "@dryer deactivated" begin
    DryRun.deactivate()

    f_return_value = :test

    function f(foo, bar)
        return f_return_value
    end

    function test_dryer(foo, bar)
        return @dryer f(foo, bar)
    end

    value = test_dryer(:foo, 378)

    @test value == f_return_value

end

@testset "@dryer activated" begin
    DryRun.activate()

    f_return_value = :test

    function f(foo, bar)
        return f_return_value
    end

    function test_dryer(foo, bar)
        return @dryer f(foo, bar)
    end

    mktemp() do path, io
        redirect_stdout(io) do
            value = test_dryer(:foo, 378)
        end

        seekstart(io)
        captured = read(io, String)
        @test captured == "f(:foo, 378)\n"
    end

end
