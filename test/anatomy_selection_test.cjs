// Executes the actual anatomy script with a minimal DOM, without a live account.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const html = fs.readFileSync('assets/body_parts/index.html', 'utf8');
const script = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)][0][1];
const messages = [];
const context = vm.createContext({
  window: {ArcMuscle: {}},
  ArcMuscle: {postMessage: message => messages.push(message)},
  document: {querySelectorAll: () => []},
});
vm.runInContext(script, context);
vm.runInContext("toggleMuscleGroup('chest'); toggleMuscleGroup('forearm'); toggleMuscleGroup('hamstring');", context);
assert.deepEqual(messages, ['chest', 'forearm', 'hamstring']); // Browse's original toggle protocol; no cap.
vm.runInContext('clearAll()', context);
assert.equal(messages.at(-1), '__clear__');
vm.runInContext("configurePrioritySelection(['chest'], ['chest','biceps','quadriceps','hamstring']); toggleMuscleGroup('biceps'); toggleMuscleGroup('quadriceps'); toggleMuscleGroup('hamstring'); toggleMuscleGroup('hair');", context);
assert.deepEqual(JSON.parse(messages.at(-1)), ['chest','biceps','quadriceps']);
assert.equal(vm.runInContext('selectedGroups.size', context), 3);
vm.runInContext("toggleView(); toggleView(); toggleMuscleGroup('chest'); toggleMuscleGroup('hamstring');", context);
assert.deepEqual(JSON.parse(messages.at(-1)), ['biceps','quadriceps','hamstring']);
vm.runInContext('clearAll()', context);
assert.equal(messages.at(-1), '[]');
assert.equal(vm.runInContext('selectedGroups.size', context), 0);
console.log('PASS: actual anatomy script Browse protocol, priority cap, deselection, front/back and reset');
