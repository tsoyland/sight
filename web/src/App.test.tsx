import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import App from './App'
import i18n from './i18n'

describe('App', () => {
  beforeEach(async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, json: async () => ({ name: 'Sight', version: '1.2.3' }) }))
    await i18n.changeLanguage('en')
  })

  it('shows server status from /api/info', async () => {
    render(<App />)
    expect(await screen.findByText('Server online (v1.2.3)')).toBeInTheDocument()
  })

  it('switches the UI to Norwegian', async () => {
    render(<App />)
    await userEvent.selectOptions(screen.getByLabelText('Language'), 'nb')
    expect(screen.getByRole('heading', { name: 'Bli med i en økt' })).toBeInTheDocument()
    expect(localStorage.getItem('sight.lang')).toBe('nb')
  })
})

describe('translations', () => {
  const keys = (obj: object, prefix = ''): string[] =>
    Object.entries(obj).flatMap(([k, v]) => (typeof v === 'object' ? keys(v, `${prefix}${k}.`) : [`${prefix}${k}`]))

  it('nb has exactly the same keys as en', async () => {
    const en = (await import('./locales/en.json')).default
    const nb = (await import('./locales/nb.json')).default
    expect(keys(nb).sort()).toEqual(keys(en).sort())
  })
})
