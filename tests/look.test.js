// file: tests/look.test.js
import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
function look() {
  const output=execFileSync('./tools/godot.sh',['--headless','--path','.','--script','res://tools/look_probe.gd'],{encoding:'utf8',timeout:25000});
  return JSON.parse(output.split('\n').find(line=>line.startsWith('LOOK_JSON:')).slice(10));
}
test('UncapturedLook: dragging turns the camera when pointer lock is unavailable', () => {
  const result=look();
  assert.equal(result.idle,0);
  assert(result.yaw < -0.2);
  assert(result.pitch < -0.05);
});
