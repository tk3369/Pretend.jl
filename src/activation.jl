"""
    TESTING

Master switch to enable testing mode.  The default is
testing mode.  Users of this package should call
`Pretend.enable_product()` in the module.
"""
const TESTING = Ref{Bool}(true)

function enable_testing()
    TESTING[] = true
end

function enable_production()
    TESTING[] = false
end
