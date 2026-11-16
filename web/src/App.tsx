import { useEffect, useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { supportedLanguages } from './i18n'

type ServerStatus = { state: 'checking' } | { state: 'online'; version: string } | { state: 'offline' }

const features = ['poll', 'quiz', 'survey', 'qa'] as const

function useServerStatus(): ServerStatus {
  const [status, setStatus] = useState<ServerStatus>({ state: 'checking' })
  useEffect(() => {
    const controller = new AbortController()
    fetch('/api/info', { signal: controller.signal })
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error(String(res.status)))))
      .then((info: { version: string }) => setStatus({ state: 'online', version: info.version }))
      .catch(() => {
        if (!controller.signal.aborted) setStatus({ state: 'offline' })
      })
    return () => controller.abort()
  }, [])
  return status
}

function LanguageSwitcher() {
  const { t, i18n } = useTranslation()
  return (
    <label className="lang">
      <span className="visually-hidden">{t('language.label')}</span>
      <select value={i18n.resolvedLanguage} onChange={(e) => void i18n.changeLanguage(e.target.value)}>
        {supportedLanguages.map((lng) => (
          <option key={lng} value={lng}>
            {t(`language.${lng}`)}
          </option>
        ))}
      </select>
    </label>
  )
}

export default function App() {
  const { t } = useTranslation()
  const status = useServerStatus()
  const [code, setCode] = useState('')
  const [submitted, setSubmitted] = useState(false)

  const onJoin = (e: FormEvent) => {
    e.preventDefault()
    setSubmitted(true)
  }

  return (
    <div className="page">
      <header className="topbar">
        <span className="brand">
          <img src="/favicon.svg" alt="" width={28} height={28} />
          {t('app.name')}
        </span>
        <LanguageSwitcher />
      </header>

      <main>
        <section className="hero">
          <h1>{t('app.name')}</h1>
          <p className="tagline">{t('app.tagline')}</p>

          <form className="join" onSubmit={onJoin}>
            <h2>{t('join.title')}</h2>
            <label htmlFor="code">{t('join.codeLabel')}</label>
            <div className="join-row">
              <input
                id="code"
                inputMode="numeric"
                autoComplete="off"
                placeholder={t('join.codePlaceholder')}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/[^\d ]/g, '').slice(0, 7))}
              />
              <button type="submit">{t('join.submit')}</button>
            </div>
            {submitted && <p className="hint">{t('join.comingSoon')}</p>}
          </form>
        </section>

        <section className="features" aria-labelledby="features-title">
          <h2 id="features-title">{t('features.title')}</h2>
          <ul>
            {features.map((f) => (
              <li key={f}>
                <h3>{t(`features.${f}.name`)}</h3>
                <p>{t(`features.${f}.description`)}</p>
              </li>
            ))}
          </ul>
        </section>
      </main>

      <footer className={`status status-${status.state}`} role="status">
        {status.state === 'online' ? t('status.online', { version: status.version }) : t(`status.${status.state}`)}
      </footer>
    </div>
  )
}
