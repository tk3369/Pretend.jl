using Test
using Pretend
Pretend.activate()

# Mocking.jl example
@mockable open(f,io) = Base.open(f,io)
@mockable read(fp, n) = Base.read(fp, n)

function randdev(n::Integer)
    open("/dev/urandom") do fp
        reverse(read(fp, n))
    end
end

# patch `read` to test properly
# patch `open` to avoid opening any file
@test apply(read => (fp,n) -> [UInt8(i) for i in 1:n],
            open => (f,io) -> f(io)) do
    randdev(5)
end == [0x05, 0x04, 0x03, 0x02, 0x01]

# outside test it's a no-op
@test randdev(5) != [0x05, 0x04, 0x03, 0x02, 0x01]
