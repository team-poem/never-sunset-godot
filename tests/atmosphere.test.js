// file: tests/atmosphere.test.js
import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
function atmosphere(name) {
  const output=execFileSync('./tools/godot.sh',['--headless','--path','.','--script','res://drafts/atmosphere/scene_probe.gd','--',name,'--qa-no-save'],{encoding:'utf8',timeout:25000});
  assert(!output.includes('SCRIPT ERROR'),'The actual scene probe must execute without script errors');
  const line=output.split('\n').find(value=>value.startsWith('ATMOSPHERE_JSON:'));
  assert(line,'Actual Godot scene must return evidence');
  return JSON.parse(line.slice(16));
}

test('ContinuousEntry: homecoming begins with narration while walking remains available', () => {
  const result=atmosphere('entry');
  assert.equal(result.continuous,true);
  assert.equal(result.narration,true);
});

test('WorldObservation: observing the mark and photo records memories without a modal', () => {
  const result=atmosphere('observe');
  assert.equal(result.continuous,true);
  assert(result.memories.includes('mark'));
  assert(result.memories.includes('photo'));
});

test('HeldCup: the cup is held in the world with walking enabled and Esc records it', () => {
  const result=atmosphere('mug');
  assert.equal(result.continuous,true);
  assert(result.held_meshes > 0);
  assert.equal(result.collected,true);
});

test('MovingCurtain: primary interaction visibly closes curtains once while movement stays enabled', () => {
  const result=atmosphere('curtain');
  assert.equal(result.animated,true);
  assert.equal(result.continuous,true);
  assert.equal(result.phase,'drain');
  assert.equal(result.commits,1);
});

test('DirectAppliances: sink wallpad and tile advance through direct actions without confirmation pages', () => {
  const result=atmosphere('appliances');
  assert.equal(result.continuous,true);
  assert.deepEqual(result.phases,['signal','pulse','escape']);
  assert.equal(result.exposure,0);
});
