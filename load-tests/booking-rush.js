// k6 load test: a ticket rush plus normal browsing.
//
//   docker run --rm -i -e BASE_URL=http://host.docker.internal:8080 grafana/k6:2.3.0 run - < load-tests/booking-rush.js
//
// setup() creates an organizer, one event with SEATS seats and BUYERS buyer accounts.
// "rush": every buyer tries to book one ticket at the same moment.
// "browse": steady traffic on the event list while the rush runs.
// The run fails if any request returns an unexpected status, if more tickets are
// confirmed than there are seats, or if latency goes over the thresholds.

import http from 'k6/http'
import { check } from 'k6'
import { Counter } from 'k6/metrics'
import exec from 'k6/execution'

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080'
const SEATS = Number(__ENV.SEATS || 50)
const BUYERS = Number(__ENV.BUYERS || 120)
const JSON_HEADERS = { 'Content-Type': 'application/json' }

const confirmed = new Counter('bookings_confirmed')
const soldOut = new Counter('bookings_sold_out')
const unexpected = new Counter('unexpected_responses')

export const options = {
  setupTimeout: '5m',
  scenarios: {
    rush: {
      executor: 'per-vu-iterations',
      vus: BUYERS,
      iterations: 1,
      maxDuration: '2m',
      exec: 'bookTicket'
    },
    browse: {
      executor: 'constant-arrival-rate',
      rate: 20,
      timeUnit: '1s',
      duration: '30s',
      preAllocatedVUs: 10,
      maxVUs: 40,
      exec: 'browseEvents'
    }
  },
  thresholds: {
    checks: ['rate==1.0'],
    unexpected_responses: ['count==0'],
    // never sell more seats than the event has
    bookings_confirmed: [`count<=${SEATS}`],
    'http_req_duration{scenario:browse}': ['p(95)<500'],
    'http_req_duration{scenario:rush}': ['p(95)<3000']
  }
}

function register(username) {
  const user = { username, email: `${username}@example.com`, password: 'load-test-pass-123' }
  const registered = http.post(`${BASE_URL}/api/auth/register`, JSON.stringify(user), { headers: JSON_HEADERS })
  check(registered, { 'setup: registered': r => r.status === 200 })
  const login = http.post(`${BASE_URL}/api/auth/login`,
    JSON.stringify({ usernameOrEmail: username, password: user.password }), { headers: JSON_HEADERS })
  check(login, { 'setup: logged in': r => r.status === 200 })
  return login.json('token')
}

export function setup() {
  const run = Date.now()
  const organizerToken = register(`organizer${run}`)
  const event = http.post(`${BASE_URL}/api/events`, JSON.stringify({
    title: `Load test rush ${run}`,
    location: 'Siam Paragon',
    startDate: '2099-05-01T19:00:00',
    endDate: '2099-05-01T22:00:00',
    ticketPrice: 10,
    personLimit: SEATS
  }), { headers: { ...JSON_HEADERS, Authorization: `Bearer ${organizerToken}` } })
  check(event, { 'setup: event created': r => r.status === 200 })

  const tokens = []
  for (let i = 0; i < BUYERS; i++) {
    tokens.push(register(`buyer${run}x${i}`))
  }
  return { eventId: event.json('id'), tokens }
}

export function bookTicket(data) {
  // VU numbers are shared with the browse scenario, so index by this scenario's iteration
  const token = data.tokens[exec.scenario.iterationInTest]
  const response = http.post(`${BASE_URL}/api/bookings`,
    JSON.stringify({ eventId: String(data.eventId), quantity: 1 }),
    {
      headers: { ...JSON_HEADERS, Authorization: `Bearer ${token}` },
      responseCallback: http.expectedStatuses(200, 409),
      tags: { name: 'POST /api/bookings' }
    })

  if (response.status === 200) {
    confirmed.add(1)
  } else if (response.status === 409) {
    soldOut.add(1)
  } else {
    unexpected.add(1)
  }
  check(response, { 'booking answered with 200 or 409': r => r.status === 200 || r.status === 409 })
}

export function browseEvents() {
  const response = http.get(`${BASE_URL}/api/events?page=0&size=12`, { tags: { name: 'GET /api/events' } })
  if (response.status !== 200) {
    unexpected.add(1)
  }
  check(response, { 'event list answered 200': r => r.status === 200 })
}

export function teardown(data) {
  const event = http.get(`${BASE_URL}/api/events/${data.eventId}`)
  const sold = event.json('participantsCount')
  console.log(`seats: ${SEATS}, buyers: ${BUYERS}, tickets sold: ${sold}`)
  check(event, {
    'teardown: no overbooking': () => sold <= SEATS,
    'teardown: every seat sold when buyers outnumber seats': () => BUYERS < SEATS || sold === SEATS
  })
}
