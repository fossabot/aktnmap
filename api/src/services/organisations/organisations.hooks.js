import _ from 'lodash'
import { when } from 'feathers-hooks-common'
import { hooks as coreHooks } from '@kalisio/kdk-core'
import { hooks as billingHooks } from '@kalisio/kdk-billing'
import { hooks as teamHooks } from '@kalisio/kdk-team'
import { hooks as notifyHooks } from '@kalisio/kdk-notify'
import { hooks as eventHooks } from '@kalisio/kdk-event'
import { checkOrganisationsQuotas, checkPlanQuotas, createOrganisationServices, removeOrganisationServices } from '../../hooks'

module.exports = {
  before: {
    all: [],
    find: [],
    get: [],
    create: [checkOrganisationsQuotas],
    update: [],
    // When changing billing plan check for quotas
    patch: [when(hook => _.get(hook, 'data.billing'), checkOrganisationsQuotas, checkPlanQuotas)],
    remove: [teamHooks.preventRemoveOrganisation]
  },

  after: {
    all: [],
    find: [],
    get: [],
    create: [teamHooks.createOrganisationServices,
      eventHooks.createOrganisationServices,
      createOrganisationServices,
      notifyHooks.createTopic,
      teamHooks.createOrganisationAuthorisations,
      billingHooks.subscribeDefaultPlan],
    update: [],
    patch: [],
    remove: [coreHooks.setAsDeleted,
      billingHooks.removeBilling,
      teamHooks.removeOrganisationGroups,
      teamHooks.removeOrganisationTags,
      teamHooks.removeOrganisationAuthorisations,
      notifyHooks.removeTopic,
      removeOrganisationServices,
      eventHooks.removeOrganisationServices,
      teamHooks.removeOrganisationServices]
  },

  error: {
    all: [],
    find: [],
    get: [],
    create: [],
    update: [],
    patch: [],
    remove: []
  }
}
