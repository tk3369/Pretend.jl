"""
    TESTING

Master switch to enable production/testing mode.  The default is
production mode.  Users of this package should call `Pretend.activate()`
in the main source code of the module.
"""
const TESTING = Ref{Bool}(false)

function activate()
    TESTING[] = true
end
