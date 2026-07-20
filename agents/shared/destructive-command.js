#!/usr/bin/env node
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";

function shellWords(command) {
	return command.match(/(?:[^\s"'\\]|\\.|"(?:\\.|[^"])*"|'[^']*')+/g) ?? [];
}

function option(words, short, long) {
	return words.some(
		(word) => word === long || (/^-[^-]+$/.test(word) && word.slice(1).includes(short)),
	);
}

function bare(word) {
	if ((word.startsWith("'") && word.endsWith("'")) || (word.startsWith('"') && word.endsWith('"'))) {
		return word.slice(1, -1);
	}
	return word;
}

export function destructiveReason(command) {
	for (const segment of command.replaceAll("\\\n", " ").split(/&&|\|\||[;|\n]/)) {
		const words = shellWords(segment);
		let executableIndex = 0;
		while (["command", "doas", "env", "sudo"].includes(bare(words[executableIndex] ?? "").split("/").at(-1) ?? "")) {
			executableIndex++;
			while (/^(?:-[^-]|--|[A-Za-z_][A-Za-z0-9_]*=)/.test(bare(words[executableIndex] ?? ""))) {
				executableIndex++;
			}
		}
		const executable = bare(words[executableIndex] ?? "").split("/").at(-1);
		if (!/^(?:rm|git|find|shred|wipefs|blkdiscard|mkfs(?:\..+)?)$/.test(executable ?? "")) continue;
		const args = words.slice(executableIndex + 1).map(bare);
		if (executable === "rm" && option(args, "r", "--recursive") && option(args, "f", "--force")) {
			return "recursive forced deletion";
		}
		const gitArgs = executable === "git" && args[0] === "-C" ? args.slice(2) : args;
		if (executable === "git" && gitArgs[0] === "reset" && gitArgs.includes("--hard")) {
			return "git reset --hard";
		}
		if (executable === "git" && gitArgs[0] === "clean" && option(gitArgs.slice(1), "f", "--force")) {
			return "forced git clean";
		}
		if (executable === "find" && args.includes("-delete")) return "find -delete";
		if (["shred", "wipefs", "blkdiscard"].includes(executable ?? "") || executable?.startsWith("mkfs")) {
			return `${executable} can destroy data`;
		}
	}
	return undefined;
}

if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
	let raw = "";
	process.stdin.setEncoding("utf8");
	for await (const chunk of process.stdin) raw += chunk;
	const input = JSON.parse(raw);
	const reason = input.tool_name === "Bash" ? destructiveReason(input.tool_input?.command ?? "") : undefined;
	if (reason) {
		process.stdout.write(
			JSON.stringify({
				hookSpecificOutput: {
					hookEventName: "PreToolUse",
					permissionDecision: "ask",
					permissionDecisionReason: `Destructive command: ${reason}`,
				},
			}),
		);
	}
}
