import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import {
	guardPath,
	sandboxCommand,
	workspaceRoot,
} from "../home/files/pi/extensions/workspace-sandbox.ts";

const root = mkdtempSync(join(process.cwd(), ".pi-sandbox-test-"));

try {
	const workspace = join(root, "repo");
	const outside = join(root, "outside");
	const credentials = join(workspace, "credentials");
	mkdirSync(join(workspace, ".git"), { recursive: true });
	mkdirSync(credentials);
	mkdirSync(outside);
	writeFileSync(join(workspace, ".git", "config"), "safe");
	writeFileSync(join(credentials, "token"), "secret");
	writeFileSync(join(outside, "file"), "safe");
	process.env.GH_CONFIG_DIR = credentials;

	assert.equal(workspaceRoot(workspace), workspace);
	assert.equal(guardPath("file", workspace, workspace, true), undefined);
	assert.match(guardPath("../outside/file", workspace, workspace, true) ?? "", /outside workspace/);
	assert.match(guardPath(".git/config", workspace, workspace, true) ?? "", /Protected path/);
	assert.match(guardPath("credentials/token", workspace, workspace, false) ?? "", /Sensitive path/);

	const command = sandboxCommand(
		"printf changed > inside; ! printf changed > .git/config 2>/dev/null; ! printf changed > ../outside/file 2>/dev/null",
		workspace,
		workspace,
	);
	const result = spawnSync("bash", ["-c", command], { encoding: "utf8" });
	assert.equal(result.status, 0, result.stderr);
	assert.equal(existsSync(join(workspace, "inside")), true);
	assert.equal(readFileSync(join(workspace, ".git", "config"), "utf8"), "safe");
	assert.equal(readFileSync(join(outside, "file"), "utf8"), "safe");
} finally {
	rmSync(root, { recursive: true, force: true });
}
