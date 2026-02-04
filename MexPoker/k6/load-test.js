import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 50 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    'http_req_duration': ['p(95)<2000'],
    'http_req_failed': ['rate<0.01'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';

export default function () {
  // Test evaluate endpoint
  const evaluatePayload = JSON.stringify({
    hole_cards: ['HA', 'HK'],
    community_cards: ['HQ', 'HJ', 'HT', 'D2', 'C3'],
  });

  const evaluateRes = http.post(`${BASE_URL}/api/evaluate`, evaluatePayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(evaluateRes, {
    'evaluate status is 200': (r) => r.status === 200,
    'evaluate has best_hand': (r) => JSON.parse(r.body).best_hand !== undefined,
  });

  sleep(1);

  // Test compare endpoint
  const comparePayload = JSON.stringify({
    "player1_hole_cards": ["HA", "HK"],
    "player1_community_cards": ["HQ", "HJ", "HT", "D2", "C3"],
    "player2_hole_cards": ["SA", "SK"],
    "player2_community_cards": ["HQ", "HJ", "HT", "D2", "C3"]
  });

  const compareRes = http.post(`${BASE_URL}/api/compare`, comparePayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(compareRes, {
    'compare status is 200': (r) => r.status === 200,
    'compare has winner': (r) => JSON.parse(r.body).winner !== undefined,
  });

  // Test probability endpoint
  const probPayload = JSON.stringify({
    hole_cards: ['HA', 'HK'],
    community_cards: ['HQ', 'HJ'],
    num_players: 3,
    num_simulations: 100,
  });

  const probRes = http.post(`${BASE_URL}/api/probability`, probPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(probRes, {
    'probability status is 200': (r) => r.status === 200,
    'probability has win_probability': (r) => JSON.parse(r.body).win_probability !== undefined,
  });

  sleep(1);
}
