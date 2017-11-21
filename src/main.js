// === DEFAULT / CUSTOM STYLE ===
// WARNING! always comment out ONE of the two require() calls below.
// 1. use next line to activate CUSTOM STYLE (./src/themes)
// require(`./themes/app.${__THEME}.styl`)
// 2. or, use next line to activate DEFAULT QUASAR STYLE
require(`quasar/dist/quasar.${__THEME}.css`)
// ==============================

// Uncomment the following lines if you need IE11/Edge support
// require(`quasar/dist/quasar.ie`)
// require(`quasar/dist/quasar.ie.${__THEME}.css`)

import logger from 'loglevel'
import Vue from 'vue'
import Quasar from 'quasar'
import config from 'config'
import router from './router'
import appHooks from './main.hooks'
import utils from './utils'
import services from './services'
import { kalisio, Store, beforeGuard, authenticationGuard } from 'kCore/client'
import { authorisationGuard } from 'kTeam/client'

// Required IE 11 polyfill
import 'babel-polyfill'
import 'whatwg-fetch'

if (__THEME === 'mat') {
  require('quasar-extras/roboto-font')
}
import 'quasar-extras/material-icons'
import 'quasar-extras/ionicons'
import 'quasar-extras/fontawesome'

let api = kalisio()
// Setup app hooks
api.hooks(appHooks)
// Then all services
services.call(api)

// Set up Vue
Vue.use(Quasar)
Vue.use(router)

// Set up the Store
Store.set('config', config)
Store.set('loadComponent', utils.loadComponent)
Store.set('loadSchema', utils.loadSchema)
Store.set('resolveAsset', utils.resolveAsset)
Store.set('context', { _id: '', service: 'organisations', object: null })

// Add global guards
beforeGuard.registerGuard(authenticationGuard)
beforeGuard.registerGuard(authorisationGuard(api))
// Now done in index to ensure the session has been correctly restored before registering guards
// router.beforeEach(beforeGuard)

Quasar.start(() => {
  logger.info('Starting application')
  // Inject in Vue the Kalisio features
  Object.defineProperty(Vue.prototype, '$store', {
    get () { return Store }
  })
  Object.defineProperty(Vue.prototype, '$api', {
    get () { return api }
  })
  // Create the Vue instance
  /* eslint-disable no-new */
  new Vue({
    router,
    el: '#q-app',
    render: h => h(require('./App'))
  })
})
