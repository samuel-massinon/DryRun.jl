module DryRun

using Mocking

export @dryer

include("dryer.jl")

# Create the initial definition of `activated` which defaults DryRun to be disabled
activated() = false

"""
    DryRun.activate()

Enable `@mock` call sites to allow for calling patches instead of the original function.
"""
function activate()
    # Avoid redefining `activated` when it's already set appropriately
    !activated() && @eval activated() = true
    return nothing
end

"""
    DryRun.deactivate()

Disable `@mock` call sites to only call the original function.
"""
function deactivate()
    # Avoid redefining `activated` when it's already set appropriately
    activated() && @eval activated() = false
    return nothing
end


const NULLIFIED = Ref{Bool}(false)

"""
    DryRun.nullify()

Force any packages loaded after this point to treat the `@mock` macro as a no-op. Doing so
will maximize performance by eliminating any runtime checks taking place at the `@mock` call
sites but will break any tests that require patches to be applied.

Note to ensure that all `@mock` macros are inoperative be sure to call this function before
loading any packages which depend on DryRun.jl.
"""
function nullify()
    global NULLIFIED[] = true
    return nothing
end

end # module
