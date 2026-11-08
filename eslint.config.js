import js from '@eslint/js'
import stylistic from '@stylistic/eslint-plugin'
import skipFormatting from '@vue/eslint-config-prettier/skip-formatting'
import { defineConfig, globalIgnores } from 'eslint/config'
import simpleImportSort from 'eslint-plugin-simple-import-sort'
import unusedImports from 'eslint-plugin-unused-imports'
import pluginVue from 'eslint-plugin-vue'
import globals from 'globals'

import autoImportGlobals from './.eslintrc-auto-import.mjs'

// the pages and the components call the API through the composables of resources/js/composables
const NO_USE_API = {
  selector: 'CallExpression[callee.name=\'useApi\']',
  message: 'Call the API through a composable of resources/js/composables (a new one if needed), not useApi() in a page or a component.',
}

// A text goes through t() and the catalogs of resources/lang. The files already migrated are refused any text written in
// the code: this list grows until it covers the whole site.
const FILES_WITH_TRANSLATED_TEXTS = [
  'resources/js/pages/login.vue',
  'resources/js/components/account/LanguageSelector.vue',
]
const NO_ACCENTED_TEXT = [
  { selector: 'Literal[value=/[À-ÿ]/]', message: 'A text goes through t() and resources/lang.' },
  { selector: 'TemplateElement[value.raw=/[À-ÿ]/]', message: 'A text goes through t() and resources/lang.' },
]

export default defineConfig([
  globalIgnores(['**/dist/**', '**/coverage/**', 'resources/js/games/**']),

  // Base JS rules
  js.configs.recommended,

  // Vue rules
  ...pluginVue.configs['flat/essential'],

  // Désactive les règles de formatting en conflit (via Prettier)
  skipFormatting,

  {
    files: ['resources/js/**/*.{js,jsx,mjs,ts,tsx,vue}', '*.{js,ts,json}'],
    languageOptions: {
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
      },
      globals: {
        ...globals.browser,
        ...globals.serviceworker,
        PIXI: 'readonly',
        ...autoImportGlobals.globals,
      },
    },
    plugins: {
      '@stylistic': stylistic,
      'unused-imports': unusedImports,
      'simple-import-sort': simpleImportSort,
    },
    rules: {
      // tri imports
      'simple-import-sort/imports': 'error',
      'simple-import-sort/exports': 'error',

      // unused
      'unused-imports/no-unused-imports': 'error',

      // syntaxe JS
      // indent: ['error', 2],
      quotes: ['error', 'single'],
      semi: ['error', 'never'],
      'comma-dangle': ['error', 'always-multiline'],

      // Vue
      'vue/html-indent': ['error', 2],
      'vue/max-attributes-per-line': [
        'error',
        {
          singleline: 3,
          multiline: 1,
        },
      ],
      'vue/no-v-html': 'off',
      'vue/multi-word-component-names': 'off',

      // stylistic
      '@stylistic/indent': ['error', 2],
      '@stylistic/semi': ['error', 'never'],
      '@stylistic/quotes': ['error', 'single'],
      '@stylistic/brace-style': ['error', '1tbs', { allowSingleLine: true }],
      '@stylistic/space-before-function-paren': ['error', 'never'],
      '@stylistic/object-curly-spacing': ['error', 'always'],
      '@stylistic/no-mixed-spaces-and-tabs': ['error'],
      '@stylistic/no-trailing-spaces': ['error'],
      '@stylistic/arrow-spacing': ['error'],
      '@stylistic/space-before-blocks': ['error'],
    },
  },

  // the pages and the components call the API through the composables of resources/js/composables (useGames, useClans,
  // usePaginatedList...): they do not know its URLs
  {
    files: ['resources/js/pages/**/*.vue', 'resources/js/components/**/*.vue', 'resources/js/layouts/**/*.vue'],
    rules: {
      'no-restricted-syntax': ['error', NO_USE_API],
    },
  },

  // (a block replaces the options of a rule: NO_USE_API has to stay here)
  {
    files: FILES_WITH_TRANSLATED_TEXTS,
    rules: {
      'no-restricted-syntax': ['error', NO_USE_API, ...NO_ACCENTED_TEXT],
      'vue/no-restricted-syntax': ['error', ...NO_ACCENTED_TEXT],
      'vue/no-bare-strings-in-template': ['error', {
        allowlist: ['(', ')', ',', '.', '&', '+', '-', '=', '*', '/', '#', '%', '!', '?', ':', '[', ']', '{', '}', '<', '>', '•', '·', '—', ' ', '|'],
        attributes: {
          '/.+/': ['title', 'label', 'placeholder', 'aria-label', 'aria-placeholder', 'aria-roledescription', 'aria-valuetext'],
          img: ['alt'],
        },
      }],
    },
  },

  // Node scripts (run on the server)
  {
    files: ['resources/js/replay-verifier/**/*.mjs'],
    languageOptions: {
      globals: globals.node,
    },
  },
])
