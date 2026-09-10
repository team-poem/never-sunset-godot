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

test('CupEscapeMemory: dismissing an inspected cup with Esc preserves the memory', () => {
  const result=integration('cup_escape');
  assert(result.memories.includes('mug'));
  assert.equal(result.mode,'play');
});

test('CupEscapeReturn: Esc after examining the replacement advances the discovery', () => {
  assert.equal(integration('cup_return_escape').phase,'dusk');
});

test('PendingOutcome: save and resume preserves an unacknowledged narrative', () => {
  const result=integration('pending_outcome');
  assert.equal(result.pending,'wash');
  assert.equal(result.acknowledged,'');
  assert.equal(result.restored,true);
  assert.equal(result.mode,'dialog');
  assert.equal(result.title,'손을 닦았다');
});

test('MotionPreservesClues: camera bob setting does not remove world animation', () => {
  const result=integration('motion_clue');
  assert.equal(result.camera_bob,false);
  assert.equal(result.world_advanced,true);
});
