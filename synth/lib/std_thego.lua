function clamp(low, n, high) return math.min(math.max(n, low), high) end

function round(n, i) return math.floor(n * 10^i) / 10^i end