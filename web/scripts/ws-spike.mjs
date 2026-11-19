// WebSocket endurance check for the hosting platform.
// Usage: node scripts/ws-spike.mjs https://<host> [minutes=30]
// Connects to /hubs/ping, pings every 10 s and reports transport, latency and any disconnects.
import * as signalR from '@microsoft/signalr'

const [base, minutesArg = '30'] = process.argv.slice(2)
if (!base) {
  console.error('Usage: node scripts/ws-spike.mjs https://<host> [minutes]')
  process.exit(2)
}
const minutes = Number(minutesArg)
const started = Date.now()
const events = []
const log = (msg) => {
  const line = `[${new Date().toISOString()}] ${msg}`
  events.push(line)
  console.log(line)
}

const connection = new signalR.HubConnectionBuilder()
  .withUrl(new URL('/hubs/ping', base).toString())
  .withAutomaticReconnect([0, 1000, 2000, 5000, 10000, 10000, 10000])
  .configureLogging(signalR.LogLevel.Warning)
  .build()

let disconnects = 0
let pings = 0
let failures = 0
const latencies = []
const connectionIds = new Set()

connection.onreconnecting((err) => {
  disconnects++
  log(`reconnecting (${err?.message ?? 'no error'})`)
})
connection.onreconnected((id) => log(`reconnected as ${id}`))
connection.onclose((err) => log(`closed (${err?.message ?? 'no error'})`))

await connection.start()
const transport = connection.connection?.transport?.constructor?.name ?? 'unknown'
log(`connected, transport=${transport}, id=${connection.connectionId}`)

const timer = setInterval(async () => {
  const sent = Date.now()
  try {
    const reply = await connection.invoke('Ping', sent)
    pings++
    latencies.push(Date.now() - sent)
    connectionIds.add(reply.connectionId)
  } catch (err) {
    failures++
    log(`ping failed: ${err.message}`)
  }
}, 10_000)

await new Promise((resolve) => setTimeout(resolve, minutes * 60_000))
clearInterval(timer)
await connection.stop()

latencies.sort((a, b) => a - b)
const pct = (p) => latencies[Math.min(latencies.length - 1, Math.floor((p / 100) * latencies.length))] ?? NaN
console.log('\n=== Summary ===')
console.log(JSON.stringify({
  target: base,
  minutes: Math.round((Date.now() - started) / 60000),
  transport,
  pings,
  failures,
  disconnects,
  distinctConnections: connectionIds.size,
  latencyMs: { p50: pct(50), p95: pct(95), max: latencies.at(-1) },
}, null, 2))
process.exit(failures > 0 ? 1 : 0)
