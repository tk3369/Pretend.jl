"""
    activated()

Returns true if the mocking framework is enabled. The default setting is OFF so
that the mocking code is optimized aways by the compiler.
"""
activated() = false

"""
    activate()

Activate the mocking framework. Use this at the beginning of the test suite.
"""
function activate()
    @eval activated() = true
    return nothing
end
