import std/[times, json]
import circuit_breaker

type
  AccountTelemetry* = ref object
    id*: string
    name*: string
    running*: bool
    kills*: int64
    gold*: int64
    exp*: int64
    level*: int
    fatigue*: float
    cb*: CircuitBreaker

  TelemetryState* = ref object
    port*: int
    startTime*: float
    accounts*: seq[AccountTelemetry]

proc newAccountTelemetry*(id, name: string): AccountTelemetry =
  result = AccountTelemetry(
    id: id,
    name: name,
    running: true,
    kills: 0,
    gold: 0,
    exp: 0,
    level: 1,
    fatigue: 0.0,
    cb: newCircuitBreaker(id)
  )

proc newTelemetryState*(port: int): TelemetryState =
  result = TelemetryState(
    port: port,
    startTime: epochTime(),
    accounts: @[]
  )

proc toJson*(s: TelemetryState): JsonNode =
  let elapsed = int(epochTime() - s.startTime)
  var accNodes = newJArray()
  for a in s.accounts:
    accNodes.add(%*{
      "id": a.id,
      "name": a.name,
      "running": a.running,
      "kills": a.kills,
      "gold": a.gold,
      "exp": a.exp,
      "cb_state": $a.cb.state,
      "fatigue": a.fatigue
    })

  result = %*{
    "game": "LoL Idle (Runeterra)",
    "engine": "Native Nim Zero-GC ORC",
    "uptime_sec": elapsed,
    "total_accounts": s.accounts.len,
    "port": s.port,
    "accounts": accNodes
  }
