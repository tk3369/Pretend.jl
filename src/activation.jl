"""
    activated()

Returns true if the Pretend framework is enabled. The default setting is OFF so
that the mocking code is optimized aways by the compiler.
"""
activated() = false

"""
    activate()

Activate the Pretend framework. Normally, it is called at the beginning of a test script.
"""
activate() = @eval(activated() = true)

"""
    deactivate()

Deactivate the Pretend framework. It is not commonly used because it is already the
default setting.
"""
deactivate() = @eval(activated() = false)
