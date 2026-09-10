# Godot scenario tests

User approved autonomous planning and execution. Tests run the actual GDScript state in Godot headless.

## Story lifecycle

```js
// file: tests/story.test.js
import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
const baseline = ['mark','photo','mug','wash','mug'];
const safe = [...baseline,'seal','cover','off','count','leave'];
function run(actions=[], extra={}) {
  const output=execFileSync('./tools/godot.sh',['--headless','--path','.','--log-file','/tmp/nsg-story-test.log','--script','res://tools/story_probe.gd','--',JSON.stringify({actions,...extra})],{encoding:'utf8',timeout:20000});
  const line=output.split('\n').find(line=>line.startsWith('STORY_JSON:'));
  assert(line,'Godot must execute and emit a valid state');
  return JSON.parse(line.slice(11));
}
```

- [x] HomeMemory — washing requires three distinct baseline memories

```js
test('HomeMemory: washing requires three distinct baseline memories', () => {
  assert.equal(run(['wash']).phase,'home');
  const state=run(['mug','mug','photo','mark','wash']);
  assert.equal(state.phase,'return');
  assert.deepEqual([...state.memories].sort(),['mark','mug','photo']);
  assert.equal(state.history.filter(x=>x==='mug').length,1);
});
```

- [x] UncannyReturn — revisiting the mug reveals a missing chip

```js
test('UncannyReturn: revisiting the mug reveals a missing chip', () => {
  assert.equal(run().mug_state,'left');
  assert.equal(run(['mark','photo','mug','wash']).mug_state,'smooth');
  assert.equal(run(baseline).phase,'dusk');
  assert.equal(run([...baseline,'seal','cover']).mug_state,'right');
});
```

- [x] CurtainRule — either curtain choice proceeds but looking leaves exposure

```js
test('CurtainRule: either curtain choice proceeds but looking leaves exposure', () => {
  assert.equal(run([...baseline,'seal']).phase,'drain');
  assert.equal(run([...baseline,'seal']).exposure,0);
  assert.equal(run([...baseline,'look']).exposure,1);
});
```

- [x] DrainRule — drain choices cannot skip the curtain or repeat consequences

```js
test('DrainRule: drain choices cannot skip the curtain or repeat consequences', () => {
  assert.equal(run([...baseline,'cover']).phase,'dusk');
  const state=run([...baseline,'seal','touch','touch']);
  assert.equal(state.phase,'signal');
  assert.equal(state.exposure,1);
});
```

- [x] SignalRule — voice registration and silence reach pulse with distinct evidence

```js
test('SignalRule: voice registration and silence reach pulse with distinct evidence', () => {
  const silent=run([...baseline,'seal','cover','off']);
  const voice=run([...baseline,'seal','cover','answer']);
  assert.equal(silent.phase,'pulse');
  assert.equal(voice.phase,'pulse');
  assert.equal(voice.voice,true);
  assert.equal(silent.voice,false);
});
```

- [x] EvacuationRule — pulse must be checked before leaving and lift is optional

```js
test('EvacuationRule: pulse must be checked before leaving and lift is optional', () => {
  assert.equal(run([...baseline,'seal','cover','off','leave']).phase,'pulse');
  const state=run([...safe,'elevator','elevator']);
  assert.equal(state.phase,'landing');
  assert.equal(state.exposure,1);
});
```

- [x] ThreeEndings — evidence and physically chosen key yield three endings

```js
test('ThreeEndings: evidence and physically chosen key yield three endings', () => {
  assert.equal(run([...safe,'archive','exit','worn']).ending,'witness');
  assert.equal(run([...safe,'exit','worn']).ending,'survivor');
  assert.equal(run([...safe,'archive','exit','new']).ending,'registered');
});
```

- [x] SaveReplay — valid saves replay and malformed or fabricated saves are rejected

```js
test('SaveReplay: valid saves replay and malformed or fabricated saves are rejected', () => {
  const state=run([...safe,'archive'],{roundtrip:true});
  assert.equal(state.restore_ok,true);
  assert.equal(state.restored.phase,'landing');
  for(const raw of ['{','{}','null',JSON.stringify({...state.restored,exposure:99}),JSON.stringify({...state.restored,history:['new']})]) assert.equal(run([],{restore:raw}).restore_ok,false);
});
```

- [x] TerminalSafety — unknown actions and post-ending actions change nothing

```js
test('TerminalSafety: unknown actions and post-ending actions change nothing', () => {
  const path=[...safe,'archive','exit','worn'];
  const ending=run(path);
  const repeated=run([...path,'new','wash','not_an_action']);
  assert.deepEqual(repeated,ending);
});
```

## Scene integration regressions

```js
// file: tests/integration.test.js
import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
function integration(name) {
  const output=execFileSync('./tools/godot.sh',['--headless','--path','.','--log-file','/tmp/nsg-integration-test.log','--script','res://tools/integration_probe.gd','--',name,'--qa-no-save'],{encoding:'utf8',timeout:25000});
  const line=output.split('\n').find(line=>line.startsWith('INTEGRATION_JSON:'));
  assert(line,'Actual game scene must emit integration result');
  return JSON.parse(line.slice(17));
}
```

- [x] CupEscapeMemory — actual scene integration

```js
test('CupEscapeMemory: dismissing an inspected cup with Esc preserves the memory', () => {
  const result=integration('cup_escape');
  assert(result.memories.includes('mug'));
  assert.equal(result.mode,'play');
});
```

- [x] CupEscapeReturn — actual scene integration

```js
test('CupEscapeReturn: Esc after examining the replacement advances the discovery', () => {
  assert.equal(integration('cup_return_escape').phase,'dusk');
});
```

- [x] PendingOutcome — actual scene integration

```js
test('PendingOutcome: save and resume preserves an unacknowledged narrative', () => {
  const result=integration('pending_outcome');
  assert.equal(result.pending,'wash');
  assert.equal(result.acknowledged,'');
  assert.equal(result.restored,true);
  assert.equal(result.mode,'dialog');
  assert.equal(result.title,'손을 닦았다');
});
```

- [x] MotionPreservesClues — actual scene integration

```js
test('MotionPreservesClues: camera bob setting does not remove world animation', () => {
  const result=integration('motion_clue');
  assert.equal(result.camera_bob,false);
  assert.equal(result.world_advanced,true);
});
```

## Browser pointer fallback

```js
// file: tests/look.test.js
import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
function look() {
  const output=execFileSync('./tools/godot.sh',['--headless','--path','.','--script','res://tools/look_probe.gd'],{encoding:'utf8',timeout:25000});
  return JSON.parse(output.split('\n').find(line=>line.startsWith('LOOK_JSON:')).slice(10));
}
```

- [ ] UncapturedLook — drag without pointer lock

```js
test('UncapturedLook: dragging turns the camera when pointer lock is unavailable', () => {
  const result=look();
  assert.equal(result.idle,0);
  assert(result.yaw < -0.2);
  assert(result.pitch < -0.05);
});
```
