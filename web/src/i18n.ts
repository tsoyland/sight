import i18n from 'i18next'
import LanguageDetector from 'i18next-browser-languagedetector'
import { initReactI18next } from 'react-i18next'
import en from './locales/en.json'
import nb from './locales/nb.json'

export const supportedLanguages = ['en', 'nb'] as const
export type Language = (typeof supportedLanguages)[number]

void i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: { en: { translation: en }, nb: { translation: nb } },
    fallbackLng: 'en',
    supportedLngs: supportedLanguages,
    // Norwegian browsers often report "no" or "nn"; treat them as bokmål.
    nonExplicitSupportedLngs: true,
    load: 'languageOnly',
    detection: {
      order: ['localStorage', 'navigator'],
      lookupLocalStorage: 'sight.lang',
      caches: ['localStorage'],
      convertDetectedLanguage: (lng: string) => (/^(nb|nn|no)\b/i.test(lng) ? 'nb' : lng),
    },
    interpolation: { escapeValue: false },
  })

i18n.on('languageChanged', (lng) => {
  document.documentElement.lang = lng
})

export default i18n
