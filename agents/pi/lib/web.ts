import { lookup } from "node:dns";
import http from "node:http";
import https from "node:https";
import { BlockList, isIP } from "node:net";

const maxBytes = 2 * 1024 * 1024;
const blockedV4 = new BlockList();
const blockedV6 = new BlockList();

for (const [network, prefix] of [
	["0.0.0.0", 8], ["10.0.0.0", 8], ["100.64.0.0", 10], ["127.0.0.0", 8],
	["169.254.0.0", 16], ["172.16.0.0", 12], ["192.0.0.0", 24], ["192.0.2.0", 24],
	["192.168.0.0", 16], ["198.18.0.0", 15], ["198.51.100.0", 24], ["203.0.113.0", 24],
	["224.0.0.0", 4], ["240.0.0.0", 4],
] as [string, number][]) blockedV4.addSubnet(network, prefix, "ipv4");

for (const [network, prefix] of [
	["::", 96], ["::ffff:0:0", 96], ["64:ff9b::", 96], ["64:ff9b:1::", 48],
	["100::", 64], ["2001::", 23], ["2001:db8::", 32], ["2002::", 16],
	["fc00::", 7], ["fe80::", 10], ["ff00::", 8],
] as [string, number][]) blockedV6.addSubnet(network, prefix, "ipv6");

export function isPublicAddress(rawAddress: string): boolean {
	const address = rawAddress.toLowerCase().split("%")[0];
	const family = isIP(address);
	if (family === 4) return !blockedV4.check(address, "ipv4");
	if (family === 6) return !blockedV6.check(address, "ipv6");
	return false;
}

function publicLookup(hostname: string, options: any, callback: any): void {
	lookup(hostname, { ...options, all: true }, (error, addresses) => {
		if (error) return callback(error);
		if (!addresses.length || addresses.some(({ address }) => !isPublicAddress(address))) {
			return callback(new Error(`Refusing non-public address for ${hostname}`));
		}
		if (options?.all) return callback(null, addresses);
		callback(null, addresses[0].address, addresses[0].family);
	});
}

function assertPublicUrl(url: URL): void {
	if (!new Set(["http:", "https:"]).has(url.protocol)) throw new Error("Only HTTP and HTTPS URLs are allowed");
	if (url.username || url.password) throw new Error("URL credentials are not allowed");
	const hostname = url.hostname.replace(/^\[|\]$/g, "").toLowerCase();
	if (hostname === "localhost" || hostname.endsWith(".localhost")) throw new Error("Local URLs are not allowed");
	if (isIP(hostname) && !isPublicAddress(hostname)) throw new Error("Private and reserved addresses are not allowed");
}

function decodeEntities(text: string): string {
	const named: Record<string, string> = { amp: "&", apos: "'", gt: ">", lt: "<", nbsp: " ", quot: '"' };
	return text.replace(/&(#x[\da-f]+|#\d+|[a-z]+);/gi, (entity, code: string) => {
		if (code[0] !== "#") return named[code.toLowerCase()] ?? entity;
		const value = code[1].toLowerCase() === "x" ? Number.parseInt(code.slice(2), 16) : Number.parseInt(code.slice(1), 10);
		return Number.isFinite(value) && value <= 0x10ffff ? String.fromCodePoint(value) : entity;
	});
}

export function readableText(body: string, contentType = "text/plain"): string {
	const text = contentType.includes("html")
		? body
			.replace(/<(script|style|noscript|svg)\b[^>]*>[\s\S]*?<\/\1>/gi, " ")
			.replace(/<(br|hr)\b[^>]*>|<\/(p|div|li|h[1-6]|tr|section|article)>/gi, "\n")
			.replace(/<[^>]+>/g, " ")
		: body;
	return decodeEntities(text).replace(/\r/g, "").replace(/[\t ]+/g, " ").replace(/\n{3,}/g, "\n\n").trim();
}

export async function fetchReadable(rawUrl: string, limit = 20000, signal?: AbortSignal, redirects = 0): Promise<{ text: string; url: string }> {
	if (redirects > 5) throw new Error("Too many redirects");
	const url = new URL(rawUrl);
	assertPublicUrl(url);
	const transport = url.protocol === "https:" ? https : http;
	const response = await new Promise<{ body: string; contentType: string; location?: string; status: number }>((resolve, reject) => {
		const request = transport.request(url, {
			headers: { accept: "text/html, text/plain, application/json, application/xml;q=0.9", "accept-encoding": "identity", "user-agent": "pi-web/1" },
			lookup: publicLookup,
			signal,
		}, (result) => {
			const chunks: Buffer[] = [];
			let size = 0;
			result.on("error", reject);
			result.on("data", (chunk: Buffer) => {
				size += chunk.length;
				if (size > maxBytes) result.destroy(new Error("Response exceeds 2 MiB"));
				else chunks.push(chunk);
			});
			result.on("end", () => resolve({
				body: Buffer.concat(chunks).toString("utf8"),
				contentType: String(result.headers["content-type"] ?? "text/plain").toLowerCase(),
				location: result.headers.location,
				status: result.statusCode ?? 0,
			}));
		});
		request.setTimeout(15000, () => request.destroy(new Error("Request timed out")));
		request.on("error", reject);
		request.end();
	});
	if (response.status >= 300 && response.status < 400 && response.location) {
		return fetchReadable(new URL(response.location, url).href, limit, signal, redirects + 1);
	}
	if (response.status < 200 || response.status >= 300) throw new Error(`HTTP ${response.status}`);
	if (!/^(text\/|application\/(json|[^;]+\+json|xml|[^;]+\+xml))/.test(response.contentType)) {
		throw new Error(`Unsupported content type: ${response.contentType}`);
	}
	return {
		text: readableText(response.body, response.contentType).slice(0, Math.max(1000, Math.min(limit, 50000))),
		url: url.href,
	};
}

export function formatSearchResults(results: any[], limit: number): string {
	return results.slice(0, limit).map((result, index) => {
		const parts = [`${index + 1}. ${String(result.title || "Untitled")}`, String(result.url || "")];
		if (result.content) parts.push(String(result.content).replace(/\s+/g, " ").slice(0, 600));
		if (result.publishedDate) parts.push(`Published: ${result.publishedDate}`);
		return parts.join("\n");
	}).join("\n\n");
}
