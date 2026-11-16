# Sight

Audience insights: live polls, quizzes, surveys and Q&A. A host builds activities; the audience joins anonymously with a code.

| Part | Tech |
| --- | --- |
| `web/` | React + Vite + TypeScript, react-i18next (English, Norwegian bokmål) |
| `api/` | .NET 10 / ASP.NET Core (serves the API, SignalR hub and the built SPA) |
| `infra/` | OpenTofu for Scaleway (Serverless Containers, Managed PostgreSQL, Container Registry) |
| `.github/workflows/` | CI (build, test, `tofu validate`) and, from M1, deploy |

Production URL (from M1): https://sight.tobba.no

## Local development

Prerequisites: .NET 10 SDK, Node 22, Docker (for PostgreSQL from M2 onward), OpenTofu.

```bash
docker compose up -d                          # PostgreSQL (used from M2)
dotnet run --project api/src/Sight.Api        # API on http://localhost:5042
npm --prefix web install && npm --prefix web run dev   # UI on http://localhost:5173, proxies /api to the API
```

Tests:

```bash
dotnet test api
npm --prefix web test
```

Production image (SPA built into the API's `wwwroot`, listens on 8080):

```bash
docker build -t sight .
docker run --rm -p 8080:8080 sight
```

## Translations

UI strings live in `web/src/locales/en.json` and `web/src/locales/nb.json`. A test fails if the two files don't have the same keys. The chosen language is stored in `localStorage` (`sight.lang`).

## Roadmap

- [x] M0: Skeleton (this)
- [ ] M1: Infrastructure on Scaleway and first deploy to sight.tobba.no
- [ ] M2: Host accounts, activities, sessions and join codes
- [ ] M3: Live poll
- [ ] M4: Quiz
- [ ] M5: Survey
- [ ] M6: Q&A
- [ ] M7: Hardening (rate limits, password reset email, monitoring, e2e tests)
