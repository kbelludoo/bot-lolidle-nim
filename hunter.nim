import std/[math]

const
  ArenaBaseX* = 125.0
  ArenaBaseY* = 475.0
  ArenaRaio* = 3.0
  ArenaVel* = 0.6

proc getBestZone*(level: int): string =
  case level
  of 0..5: "rota-inf"
  of 6..10: "rota-sup"
  of 11..15: "lobos"
  of 16..20: "azul"
  of 21..25: "vermelho"
  of 26..32: "rio"
  of 33..40: "dragao"
  else: "barao"

proc round2*(v: float): float =
  return (v * 100.0).round / 100.0

proc fnv1aHash*(s: string, seed: uint32): uint32 =
  var h = seed
  for ch in s:
    h = h xor uint32(ord(ch))
    h = h * 16777619'u32
    h = h xor (h shr 13)
  return h

proc arenaOffset*(name: string): (float, float) =
  let dx = ((fnv1aHash(name, 2166136261'u32) mod 7'u32).float - 3.0) * 0.8
  let dy = ((fnv1aHash(name, 2166136262'u32) mod 7'u32).float - 3.0) * 0.8
  return (dx, dy)

proc calculatePatrolPos*(baseX, baseY, elapsedSecs: float, name: string): (float, float) =
  let (ox, oy) = arenaOffset(name)
  let ang = ArenaVel * elapsedSecs
  let x = baseX + ArenaRaio * cos(ang) + ox
  let y = baseY + ArenaRaio * sin(ang) + oy
  return (round2(x), round2(y))
