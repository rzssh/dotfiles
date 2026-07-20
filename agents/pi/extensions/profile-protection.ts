import { existsSync, realpathSync, statSync } from "node:fs";
import { dirname, join, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function canonical(path: string): string {
	let cursor = path;
	const tail: string[] = [];
	while (!existsSync(cursor)) {
		const parent = dirname(cursor);
		if (parent === cursor) break;
		tail.unshift(cursor.slice(parent.length + 1));
		cursor = parent;
	}
	return resolve(existsSync(cursor) ? realpathSync(cursor) : cursor, ...tail);
}

function expand(path: string, cwd: string): string {
	const clean = path.startsWith("@") ? path.slice(1) : path;
	if (clean === "~") return process.env.HOME ?? cwd;
	if (clean.startsWith("~/")) return join(process.env.HOME ?? cwd, clean.slice(2));
	return resolve(cwd, clean);
}

function within(path: string, root: string): boolean {
	return path === root || path.startsWith(`${root}${sep}`);
}

export function protectedRoots(): string[] {
	const home = process.env.HOME;
	const runtime = process.env.XDG_RUNTIME_DIR;
	const data = process.env.XDG_DATA_HOME ?? (home ? join(home, ".local", "share") : undefined);
	return [
		process.env.AI_PROFILES_DIR ?? (home ? join(home, ".local", "share", "ai", "profiles") : undefined),
		process.env.SOPS_AGE_KEY_FILE,
		home ? join(home, ".config", "sops") : undefined,
		runtime ? join(runtime, "secrets.d") : undefined,
		home ? join(home, ".claude", ".credentials.json") : undefined,
		home ? join(home, ".codex", "auth.json") : undefined,
		home ? join(home, ".hermes", "auth.json") : undefined,
		data ? join(data, "opencode", "auth.json") : undefined,
		process.env.PI_CODING_AGENT_DIR
			? join(process.env.PI_CODING_AGENT_DIR, "auth.json")
			: home
				? join(home, ".pi", "agent", "auth.json")
				: undefined,
	]
		.filter((path): path is string => Boolean(path))
		.map(canonical)
		.filter((path, index, roots) => roots.indexOf(path) === index)
		.sort((left, right) => left.length - right.length)
		.filter((path, index, roots) => !roots.slice(0, index).some((root) => within(path, root)));
}

function quote(value: string): string {
	return `'${value.replaceAll("'", `'"'"'`)}'`;
}

export function sandboxCommand(command: string, cwd: string): string {
	const args = ["--die-with-parent", "--bind", "/", "/"];
	for (const path of protectedRoots()) {
		if (!existsSync(path)) continue;
		if (statSync(path).isDirectory()) args.push("--tmpfs", path);
		else args.push("--ro-bind", "/dev/null", path);
	}
	args.push("--chdir", cwd, "--", "bash", "-c", command);
	return ["exec", "bwrap", ...args].map(quote).join(" ");
}

export function guardPath(path: string, cwd: string): string | undefined {
	const target = canonical(expand(path, cwd));
	return protectedRoots().some((root) => within(target, root)) ? `Protected path: ${path}` : undefined;
}

export function scrubProfileEnvironment(env: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
	const clean = { ...env };
	for (const key of (env.AI_PROFILE_KEYS ?? "").split(",")) {
		if (key) delete clean[key];
	}
	delete clean.AI_PROFILE_KEYS;
	return clean;
}

export default async function profileProtection(pi: ExtensionAPI) {
	const { createBashTool } = await import("@earendil-works/pi-coding-agent");
	const cwd = realpathSync(process.cwd());
	const bashTool = createBashTool(cwd, {
		spawnHook: ({ command, cwd: commandCwd, env }) => ({
			command: sandboxCommand(command, commandCwd),
			cwd: commandCwd,
			env: scrubProfileEnvironment(env),
		}),
	});
	pi.registerTool({
		...bashTool,
		execute: async (id, params, signal, onUpdate) => bashTool.execute(id, params, signal, onUpdate),
	});
	pi.on("tool_call", async (event: any) => {
		if (!["read", "write", "edit", "grep", "find", "ls"].includes(event.toolName)) return undefined;
		const reason = guardPath(event.input.path ?? ".", cwd);
		return reason ? { block: true, reason } : undefined;
	});
}
