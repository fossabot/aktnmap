import _ from 'lodash'
import config from 'config'
import utils from './utils'
import { Store } from '@kalisio/kCore/client'

export default {
  install (Vue, options) {
    // Inject in Vue the Kalisio features
    Vue.prototype.$store = Store
    Vue.prototype.$api = options.api
    Vue.prototype.$can = options.api.can
    Vue.prototype.$load = utils.load
    Vue.prototype.$config = function (path, defaultValue) {
      return _.get(config, path, defaultValue)
    }
    // FIXME: This is used for testing purpose, don't know how to access this from testcafe otherwise
    global.$store = Vue.prototype.$store
    global.$api = Vue.prototype.$api
  }
}
