import std/[os, json]

type
  GameCredentials* = object
    email*: string
    password*: string
    sessionCookie*: string
    token*: string
    origin*: string

  GameSettings* = object
    huntTarget*: string
    autoHunt*: bool
    autoRoute*: bool
    autoSell*: bool
    autoHeal*: bool
    autoUpgrade*: bool
    autoDaily*: bool
    autoChests*: bool
    autoParty*: bool
    partyLeader*: string
    arenaWalk*: bool
    arenaX*: float
    arenaY*: float
    killRate*: float
    maxLevel*: int

  AccountConfig* = object
    id*: string
    name*: string
    enabled*: bool
    bindIP*: string
    proxy*: string
    credentials*: GameCredentials
    settings*: GameSettings

proc defaultAccount*(id, name: string): AccountConfig =
  result.id = id
  result.name = name
  result.enabled = true
  result.credentials.origin = "https://lolidle.com"
  result.settings.huntTarget = "selva-lobos"
  result.settings.autoHunt = true
  result.settings.autoRoute = true
  result.settings.autoSell = true
  result.settings.autoHeal = true
  result.settings.autoDaily = true
  result.settings.arenaWalk = true
  result.settings.arenaX = 125.0
  result.settings.arenaY = 475.0
  result.settings.killRate = 1.0

proc loadAccounts*(path: string): seq[AccountConfig] =
  result = @[]
  if fileExists(path):
    try:
      let txt = readFile(path)
      let j = parseJson(txt)
      if j.kind == JArray:
        for item in j:
          var acc = defaultAccount(item{"id"}.getStr("acc-1"), item{"name"}.getStr("Personagem Principal"))
          acc.enabled = item{"enabled"}.getBool(true)
          acc.bindIP = item{"bindIP"}.getStr("")
          acc.proxy = item{"proxy"}.getStr("")

          if item.hasKey("credentials"):
            let c = item["credentials"]
            acc.credentials.email = c{"email"}.getStr("")
            acc.credentials.password = c{"password"}.getStr("")
            acc.credentials.sessionCookie = c{"sessionCookie"}.getStr("")
            acc.credentials.token = c{"token"}.getStr("")
            acc.credentials.origin = c{"origin"}.getStr("https://lolidle.com")

          if item.hasKey("settings"):
            let s = item["settings"]
            acc.settings.huntTarget = s{"huntTarget"}.getStr(s{"hunt_target"}.getStr("selva-lobos"))
            acc.settings.autoHunt = s{"autoHunt"}.getBool(s{"auto_hunt"}.getBool(true))
            acc.settings.autoRoute = s{"autoRoute"}.getBool(s{"auto_route"}.getBool(true))
            acc.settings.autoSell = s{"autoSell"}.getBool(s{"auto_sell"}.getBool(true))
            acc.settings.autoHeal = s{"autoHeal"}.getBool(s{"auto_heal"}.getBool(true))
            acc.settings.autoDaily = s{"autoDaily"}.getBool(s{"auto_daily"}.getBool(true))
            acc.settings.arenaWalk = s{"arenaWalk"}.getBool(s{"arena_walk"}.getBool(true))
            acc.settings.arenaX = s{"arenaX"}.getFloat(s{"arena_x"}.getFloat(125.0))
            acc.settings.arenaY = s{"arenaY"}.getFloat(s{"arena_y"}.getFloat(475.0))
            acc.settings.killRate = s{"killRate"}.getFloat(s{"kill_rate"}.getFloat(1.0))

          result.add(acc)
    except CatchableError as e:
      echo "⚠️ Erro ao ler ", path, ": ", e.msg
