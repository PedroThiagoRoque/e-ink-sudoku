local Test = {}

function Test.equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

function Test.truthy(value, message)
    if not value then
        error(message or "expected truthy value", 2)
    end
end

function Test.falsy(value, message)
    if value then
        error(message or "expected falsy value", 2)
    end
end

function Test.run(cases)
    local passed = 0
    for name, case in pairs(cases) do
        case()
        passed = passed + 1
        io.write("ok - " .. name .. "\n")
    end
    io.write(string.format("%d tests passed\n", passed))
end

return Test

