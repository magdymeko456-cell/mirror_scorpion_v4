const test = require("node:test");
const assert = require("node:assert/strict");

test("Functions entrypoint loads healthCheck without a service-account file", () => {
  const functions = require("../index");

  assert.equal(typeof functions.healthCheck, "function");
});
