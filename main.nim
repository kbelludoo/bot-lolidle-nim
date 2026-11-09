import std/[os, asyncdispatch, strutils]
import config, telemetry, bot, server

proc formatNumber*(n: int64): string =
  if n < 1000:
    return $n
  elif n < 1_000_000:
    return formatFloat(n.float / 1000.0, ffDecimal, 1) & "k"
  else:
    return formatFloat(n.float / 1_000_000.0, ffDecimal, 2) & "kk"

proc main() =
  echo "================================================================================"
  echo "       ⚡ LOL IDLE NATIVE NIM BOT (ZERO-GC & ALTA PERFORMANCE) ⚡              "
  echo "================================================================================"

  var configPath = "accounts.json"
  var i = 1
  while i <= paramCount():
    let arg = paramStr(i)
    if (arg == "-config" or arg == "--config") and i + 1 <= paramCount():
      configPath = paramStr(i + 1)
      i += 2
    else:
      i += 1

  var accounts = loadAccounts(configPath)
  if accounts.len == 0:
    echo "⚠️ Nenhuma conta encontrada em '", configPath, "'. Criando template..."
    accounts = @[defaultAccount("acc-1", "Personagem Principal")]

  let targetAcc = getEnv("ACCOUNT", "")
  var activeAccounts: seq[AccountConfig] = @[]
  for a in accounts:
    if not a.enabled and a.id != targetAcc:
      continue
    if targetAcc.len > 0 and a.id != targetAcc:
      continue
    activeAccounts.add(a)

  if activeAccounts.len == 0:
    activeAccounts = accounts

  let portStr = getEnv("PORT", "3005")
  let port = try: parseInt(portStr) except CatchableError: 3005

  let state = newTelemetryState(port)

  for acc in activeAccounts:
    let tAcc = newAccountTelemetry(acc.id, acc.name)
    state.accounts.add(tAcc)
    asyncCheck initAccount(acc, tAcc)
    asyncCheck runBotLoop(acc, tAcc)

  # Start HTTP server
  asyncCheck runServer(state, port)

  # Ticker Task
  asyncCheck (proc() {.async.} =
    var tick = 0
    while true:
      await sleepAsync(4000)
      tick.inc()
      var totalKills: int64 = 0
      var totalGold: int64 = 0
      var totalExp: int64 = 0

      for a in state.accounts:
        totalKills += a.kills
        totalGold += a.gold
        totalExp += a.exp

      echo "[Console Ticker #", tick, "] Contas: ", state.accounts.len,
           " | Kills: ", totalKills,
           " | Essência Azul: ", formatNumber(totalGold),
           " | Exp: ", formatNumber(totalExp)
  )()

  echo "Bot operacional na porta ", port, ". Pressione Ctrl+C para encerrar."
  runForever()

when isMainModule:
  main()
