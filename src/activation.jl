const MOCKING = Ref{Bool}(true)

function activate()
    MOCKING[] = true
end

function deactivate()
    MOCKING[] = false
end
