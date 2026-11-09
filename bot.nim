import std/[httpclient, asyncdispatch, json, strutils, random, times]
import config, hunter, telemetry, circuit_breaker

proc newApiClient*(acc: AccountConfig): AsyncHttpClient =
  result = newAsyncHttpClient(userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
  result.headers = newHttpHeaders([
    ("Content-Type", "application/json"),
    ("X-Idioma", "pt")
  ])
  if acc.credentials.token.len > 0:
    result.headers.add("Authorization", "Bearer " & acc.credentials.token)

proc initAccount*(acc: AccountConfig, tAcc: AccountTelemetry) {.async.} =
  echo "Validando sessão e carregando dados reais do personagem via /api/eu..."
  let client = newApiClient(acc)
  let origin = if acc.credentials.origin.len > 0: acc.credentials.origin.strip(chars = {'/'}) else: "https://lolidle.com"
  try:
    let resp = await client.get(origin & "/api/eu")
    if resp.code == Http200:
      let body = await resp.body
      let j = parseJson(body)
      if j.hasKey("estado"):
        let est = j["estado"]
        if est.hasKey("nivel"): tAcc.level = est["nivel"].getInt(1)
        if est.hasKey("ouro"): tAcc.gold = est["ouro"].getBiggestInt(0)
        if est.hasKey("xp"): tAcc.exp = est["xp"].getBiggestInt(0)
        if est.hasKey("totais") and est["totais"].hasKey("abates"):
          tAcc.kills = est["totais"]["abates"].getBiggestInt(0)
  except CatchableError as e:
    echo "⚠️ [LoL Idle] Erro ao obter /api/eu: ", e.msg
  finally:
    client.close()

proc runBotLoop*(acc: AccountConfig, tAcc: AccountTelemetry) {.async.} =
  echo "🚀 Bot [", acc.name, "] (LoL Idle Runeterra) iniciado com sucesso."
  tAcc.running = true
  let startTime = epochTime()

  let origin = if acc.credentials.origin.len > 0: acc.credentials.origin.strip(chars = {'/'}) else: "https://lolidle.com"

  # Task 1: Walk / Patrol Loop
  asyncCheck (proc() {.async.} =
    while tAcc.running:
      let jitter = 0.85 + rand(0.3)
      await sleepAsync(int(500.0 * jitter))
      if acc.settings.arenaWalk:
        let elapsed = epochTime() - startTime
        let baseX = if acc.settings.arenaX != 0.0: acc.settings.arenaX else: ArenaBaseX
        let baseY = if acc.settings.arenaY != 0.0: acc.settings.arenaY else: ArenaBaseY
        let (x, y) = calculatePatrolPos(baseX, baseY, elapsed, acc.name)
        discard x
        discard y
        # Increments progression organically
        tAcc.kills.inc()
        tAcc.exp.inc(20)
        tAcc.gold.inc(5)
  )()

  # Task 2: Route Loop
  asyncCheck (proc() {.async.} =
    while tAcc.running:
      let jitter = 0.8 + rand(0.4)
      await sleepAsync(int(30000.0 * jitter))
      if acc.settings.autoRoute:
        let targetZone = if acc.settings.huntTarget.len > 0 and acc.settings.huntTarget != "auto":
          acc.settings.huntTarget
        else:
          getBestZone(tAcc.level)
        echo "🗺️ Nível ", tAcc.level, ": Rota de caça ativa -> ", targetZone
  )()

  # Task 3: Save Loop
  asyncCheck (proc() {.async.} =
    while tAcc.running:
      let jitter = 0.8 + rand(0.4)
      await sleepAsync(int(15000.0 * jitter))
      if acc.credentials.token.len > 0 and acc.credentials.token != "seu-token-de-sessao-ou-jwt":
        let client = newApiClient(acc)
        try:
          let payload = %*{
            "estado": {
              "nivel": tAcc.level,
              "ouro": tAcc.gold,
              "xp": tAcc.exp,
              "totais": { "abates": tAcc.kills }
            }
          }
          discard await client.post(origin & "/api/save", $payload)
          tAcc.cb.recordSuccess()
        except CatchableError as e:
          echo "⚠️ Erro ao salvar estado: ", e.msg
          tAcc.cb.recordFailure()
        finally:
          client.close()
  )()

  # Task 4: Daily Loop
  asyncCheck (proc() {.async.} =
    while tAcc.running:
      let jitter = 0.85 + rand(0.3)
      await sleepAsync(int(300000.0 * jitter))
      if acc.settings.autoDaily and acc.credentials.token.len > 0 and acc.credentials.token != "seu-token-de-sessao-ou-jwt":
        let client = newApiClient(acc)
        try:
          discard await client.post(origin & "/api/recompensas/diaria", "")
        except CatchableError:
          discard
        finally:
          client.close()
  )()
