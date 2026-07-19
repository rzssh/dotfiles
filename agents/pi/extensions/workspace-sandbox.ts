import { existsSync, realpathSync, statSync } from "node:fs";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const protectedNames = new Set([".git", ".jj", ".pi", ".agents"]);

function canonicalTarget(path: string): string {
	let cursor = path;
	const tail: string[] = [];

	while (!existsSync(cursor)) {
		const parent = dirname(cursor);
		if (parent === cursor) break;
		tail.unshift(basename(cursor));
		cursor = parent;
	}

	return resolve(existsSync(cursor) ? realpathSync(cursor) : cursor, ...tail);
}

function expandPath(path: string, cwd: string): string {
	const clean = path.startsWith("@") ? path.slice(1) : path;
	if (clean === "~") return process.env.HOME ?? cwd;
	if (clean.startsWith("~/")) return join(process.env.HOME ?? cwd, clean.slice(2));
	return resolve(cwd, clean);
}

export function workspaceRoot(cwd: string): string {
	let cursor = realpathSync(cwd);

	while (true) {
		if (existsSync(join(cursor, ".git")) || existsSync(join(cursor, ".jj"))) return cursor;
		const parent = dirname(cursor);
		if (parent === cursor) return realpathSync(cwd);
		cursor = parent;
	}
}

export function isWithin(path: string, root: string): boolean {
	return path === root || path.startsWith(`${root}${sep}`);
}

function canonicalRoots(paths: Array<string | undefined>): string[] {
	return paths
		.filter((path): path is string => Boolean(path))
		.map(canonicalTarget)
		.filter((path, index, roots) => roots.indexOf(path) === index);
}

function readableRoots(workspace: string): string[] {
	const home = process.env.HOME;
	const agentDir = process.env.PI_CODING_AGENT_DIR;
	return canonicalRoots([
		workspace,
		home ? join(home, ".agents", "skills") : undefined,
		agentDir ? join(agentDir, "skills") : undefined,
	]);
}

function sensitivePaths(workspace: string): string[] {
	const home = process.env.HOME;
	const candidates = canonicalRoots([
		process.env.AI_PROFILES_DIR,
		process.env.AWS_SHARED_CREDENTIALS_FILE,
		process.env.CLAUDE_CONFIG_DIR
			? join(process.env.CLAUDE_CONFIG_DIR, ".credentials.json")
			: undefined,
		process.env.CODEX_HOME ? join(process.env.CODEX_HOME, "auth.json") : undefined,
		process.env.DOCKER_CONFIG,
		process.env.GH_CONFIG_DIR ? join(process.env.GH_CONFIG_DIR, "hosts.yml") : undefined,
		process.env.HERMES_HOME ? join(process.env.HERMES_HOME, "auth.json") : undefined,
		process.env.NPM_CONFIG_USERCONFIG,
		process.env.PI_CODING_AGENT_DIR
			? join(process.env.PI_CODING_AGENT_DIR, "auth.json")
			: undefined,
		process.env.SOPS_AGE_KEY_FILE,
		process.env.XDG_DATA_HOME ? join(process.env.XDG_DATA_HOME, "opencode", "auth.json") : undefined,
		home ? join(home, ".local", "share", "ai", "profiles") : undefined,
		home ? join(home, ".local", "share", "opencode", "auth.json") : undefined,
		home ? join(home, ".local", "share", "keyrings") : undefined,
		home ? join(home, ".claude", ".credentials.json") : undefined,
		home ? join(home, ".codex", "auth.json") : undefined,
		home ? join(home, ".config", "sops") : undefined,
		home ? join(home, ".config", "gh", "hosts.yml") : undefined,
		home ? join(home, ".hermes", "auth.json") : undefined,
		home ? join(home, ".pi", "agent", "auth.json") : undefined,
		home ? join(home, ".ssh") : undefined,
		home ? join(home, ".aws") : undefined,
		home ? join(home, ".docker") : undefined,
		home ? join(home, ".kube") : undefined,
		home ? join(home, ".gnupg") : undefined,
		home ? join(home, ".password-store") : undefined,
		home ? join(home, ".git-credentials") : undefined,
		home ? join(home, ".netrc") : undefined,
		home ? join(home, ".npmrc") : undefined,
		home ? join(home, ".pypirc") : undefined,
	]);
	return candidates
		.filter((path) => path !== workspace && !isWithin(workspace, path))
		.sort((left, right) => left.length - right.length)
		.filter((path, index, roots) => !roots.slice(0, index).some((root) => isWithin(path, root)));
}

function protectedPaths(workspace: string): string[] {
	return [...protectedNames]
		.map((name) => join(workspace, name))
		.filter((path) => existsSync(path));
}

function quote(value: string): string {
	return `'${value.replaceAll("'", `'"'"'`)}'`;
}

export function sandboxCommand(command: string, workspace: string, cwd: string): string {
	const args = [
		"--die-with-parent",
		"--new-session",
		"--unshare-all",
		"--share-net",
		"--ro-bind",
		"/",
		"/",
		"--bind",
		workspace,
		workspace,
	];

	for (const path of protectedPaths(workspace)) args.push("--ro-bind", path, path);
	for (const path of sensitivePaths(workspace)) {
		if (!existsSync(path)) continue;
		if (statSync(path).isDirectory()) args.push("--tmpfs", path);
		else args.push("--ro-bind", "/dev/null", path);
	}

	args.push("--tmpfs", "/tmp", "--dev", "/dev", "--proc", "/proc", "--chdir", cwd, "--", "bash", "-c", command);
	return ["exec", "bwrap", ...args].map(quote).join(" ");
}

export function guardPath(
	path: string,
	cwd: string,
	workspace: string,
	write: boolean,
): string | undefined {
	const target = canonicalTarget(expandPath(path, cwd));
	if (sensitivePaths(workspace).some((root) => isWithin(target, root))) return `Sensitive path: ${path}`;
	const allowed = write ? isWithin(target, workspace) : readableRoots(workspace).some((root) => isWithin(target, root));
	if (!allowed) return `Path outside workspace: ${path}`;

	if (write) {
		const names = relative(workspace, target).split(sep);
		if (names.some((name) => protectedNames.has(name))) return `Protected path: ${path}`;
	}

	return undefined;
}

export function scrubProfileEnvironment(env: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
	const clean = { ...env };
	for (const key of (env.AI_PROFILE_KEYS ?? "").split(",")) {
		if (key) delete clean[key];
	}
	delete clean.AI_PROFILE_KEYS;
	return clean;
}

export default async function workspaceSandbox(pi: ExtensionAPI) {
	const { createBashTool } = await import("@earendil-works/pi-coding-agent");
	const cwd = realpathSync(process.cwd());
	const workspace = workspaceRoot(cwd);
	let enabled = true;
	const bashTool = createBashTool(cwd, {
		spawnHook: ({ command, cwd: commandCwd, env }) => ({
			command: enabled ? sandboxCommand(command, workspace, commandCwd) : command,
			cwd: commandCwd,
			env: scrubProfileEnvironment(env),
		}),
	});

	pi.registerTool({
		...bashTool,
		execute: async (id, params, signal, onUpdate) => bashTool.execute(id, params, signal, onUpdate),
	});

	pi.registerFlag("no-workspace-sandbox", {
		description: "Disable workspace filesystem sandbox",
		type: "boolean",
		default: false,
	});

	pi.on("session_start", (_event: unknown, ctx: any) => {
		enabled = !pi.getFlag("no-workspace-sandbox");
		if (!ctx.hasUI) return;
		ctx.ui.setStatus("workspace-sandbox", enabled ? "sandbox: workspace" : "sandbox: off");
		if (!enabled) ctx.ui.notify("Workspace sandbox disabled", "warning");
	});

	pi.on("tool_call", (event: any) => {
		if (!enabled) return undefined;

		const write = event.toolName === "write" || event.toolName === "edit";
		const read = event.toolName === "read" || event.toolName === "grep" || event.toolName === "find" || event.toolName === "ls";
		if (!write && !read) return undefined;

		const reason = guardPath(event.input.path ?? ".", cwd, workspace, write);
		return reason ? { block: true, reason } : undefined;
	});
}
