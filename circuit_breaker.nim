import std/[times]

type
  CircuitState* = enum
    csClosed = "Closed", csHalfOpen = "HalfOpen", csOpen = "Open"

  CircuitBreaker* = ref object
    id*: string
    state*: CircuitState
    failureCount*: int
    maxFailures*: int
    baseCooldownSec*: int
    maxCooldownSec*: int
    lastFailureTime*: float
    cooldownSec*: int

proc newCircuitBreaker*(id: string, maxFailures = 2, baseCooldown = 900, maxCooldown = 3600): CircuitBreaker =
  result = CircuitBreaker(
    id: id,
    state: csClosed,
    failureCount: 0,
    maxFailures: maxFailures,
    baseCooldownSec: baseCooldown,
    maxCooldownSec: maxCooldown,
    lastFailureTime: 0.0,
    cooldownSec: baseCooldown
  )

proc canExecute*(cb: CircuitBreaker): bool =
  case cb.state
  of csClosed:
    return true
  of csHalfOpen:
    return true
  of csOpen:
    let elapsed = epochTime() - cb.lastFailureTime
    if elapsed >= cb.cooldownSec.float:
      cb.state = csHalfOpen
      return true
    return false

proc recordSuccess*(cb: CircuitBreaker) =
  cb.failureCount = 0
  cb.cooldownSec = cb.baseCooldownSec
  cb.state = csClosed

proc recordFailure*(cb: CircuitBreaker) =
  cb.failureCount.inc()
  cb.lastFailureTime = epochTime()
  if cb.failureCount >= cb.maxFailures:
    cb.state = csOpen
    cb.cooldownSec = min(cb.cooldownSec * 2, cb.maxCooldownSec)
    echo "🚨 [CircuitBreaker] Conta ", cb.id, " desarmada por ", cb.cooldownSec, "s."
