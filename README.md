# bot-lolidle-nim ⚡

LoL Idle (Runeterra) Native Multi-Bot reescrito em **Nim 2.2** com 100% de paridade com Go e Rust.

## Recursos
- **Runeterra Arena Walk:** Patrulhamento contínuo em órbita com cálculo trigonométrico FNV-1a.
- **Roteamento Dinâmico de Zonas:** Transição automática de rotas por nível do personagem.
- **Pacing Orgânico & Jitter:** Delays humanos aleatórios ($\pm 20\%$) em todas as ações.
- **Telemetria HTTP na Porta 3005:** Endpoint `/api/status` e Web Dashboard.

## Compilação Cruzada (Linux x86_64 via Zig)
```powershell
nim c --os:linux --cpu:amd64 --gcc.exe:zigcc-linux-gnu.bat --gcc.linkerexe:zigcc-linux-gnu.bat -d:ssl -d:release -o:bot-lolidle-linux-nim main.nim
```
