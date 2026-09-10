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

test('HomeMemory: washing requires three distinct baseline memories', () => {
  assert.equal(run(['wash']).phase,'home');
  const state=run(['mug','mug','photo','mark','wash']);
  assert.equal(state.phase,'return');
  assert.deepEqual([...state.memories].sort(),['mark','mug','photo']);
  assert.equal(state.history.filter(x=>x==='mug').length,1);
});
