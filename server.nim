import std/[asynchttpserver, asyncdispatch, json, strutils]
import telemetry

const IndexHtml = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>LoL Idle - Native Nim Engine</title>
    <style>
        body { background: #0b0f17; color: #f0f6fc; font-family: monospace; padding: 20px; }
        .card { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 16px; margin-bottom: 12px; }
        .tag { background: #238636; color: white; padding: 2px 8px; border-radius: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h2>⚡ LoL Idle (Runeterra) <span class="tag">ONLINE</span></h2>
        <p>Native Nim Zero-GC ORC • High-Performance Multi-Bot Engine</p>
        <div id="stats">Carregando telemetria...</div>
    </div>
    <script>
        setInterval(async () => {
            const res = await fetch('/api/status');
            const data = await res.json();
            document.getElementById('stats').innerHTML = `
                <b>Engine:</b> ${data.engine}<br>
                <b>Uptime:</b> ${data.uptime_sec}s<br>
                <b>Contas:</b> ${data.total_accounts}
            `;
        }, 3000);
    </script>
</body>
</html>"""

proc runServer*(state: TelemetryState, port: int) {.async.} =
  var server = newAsyncHttpServer()

  proc cb(req: Request) {.async, gcsafe.} =
    let path = req.url.path
    var headers = newHttpHeaders([
      ("Access-Control-Allow-Origin", "*"),
      ("Access-Control-Allow-Methods", "GET, POST, OPTIONS"),
      ("Access-Control-Allow-Headers", "Content-Type, Authorization")
    ])

    if req.reqMethod == HttpOptions:
      await req.respond(Http200, "", headers)
      return

    if path == "/api/status" or path == "/status.json":
      headers.add("Content-Type", "application/json; charset=utf-8")
      let body = $state.toJson()
      await req.respond(Http200, body, headers)
    elif path == "/" or path == "":
      headers.add("Content-Type", "text/html; charset=utf-8")
      await req.respond(Http200, IndexHtml, headers)
    else:
      await req.respond(Http404, "Not Found", headers)

  echo "🌐 [Web Server] Telemetria LoL Idle Nim ativa em http://0.0.0.0:", port
  await server.serve(Port(port), cb, "0.0.0.0")
