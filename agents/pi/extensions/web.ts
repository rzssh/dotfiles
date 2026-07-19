import { Type } from "typebox";
import { fetchReadable, formatSearchResults } from "../lib/web.ts";

const searxUrl = process.env.SEARXNG_URL || "http://127.0.0.1:8888";

export default function web(pi: any) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description: "Search the web through local SearXNG and return compact results with source URLs.",
		parameters: Type.Object({
			query: Type.String({ minLength: 1 }),
			max_results: Type.Optional(Type.Integer({ minimum: 1, maximum: 10 })),
			time_range: Type.Optional(Type.Union([Type.Literal("day"), Type.Literal("month"), Type.Literal("year")])),
		}),
		async execute(_id: string, params: any, signal: AbortSignal) {
			const url = new URL("/search", searxUrl);
			url.searchParams.set("q", params.query);
			url.searchParams.set("format", "json");
			url.searchParams.set("safesearch", "0");
			if (params.time_range) url.searchParams.set("time_range", params.time_range);
			const requestSignal = AbortSignal.any([signal, AbortSignal.timeout(15000)]);
			const response = await fetch(url, { signal: requestSignal });
			if (!response.ok) throw new Error(`SearXNG HTTP ${response.status}`);
			const data = await response.json() as any;
			const text = formatSearchResults(Array.isArray(data.results) ? data.results : [], params.max_results ?? 8);
			return { content: [{ type: "text", text: text || "No results." }], details: { query: params.query } };
		},
	});

	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description: "Fetch a public HTTP or HTTPS page as size-limited readable text. Private, local, credentialed, and binary URLs are blocked.",
		parameters: Type.Object({
			url: Type.String({ minLength: 1 }),
			max_chars: Type.Optional(Type.Integer({ minimum: 1000, maximum: 50000 })),
		}),
		async execute(_id: string, params: any, signal: AbortSignal) {
			const requestSignal = AbortSignal.any([signal, AbortSignal.timeout(15000)]);
			const result = await fetchReadable(params.url, params.max_chars ?? 20000, requestSignal);
			return { content: [{ type: "text", text: `Source: ${result.url}\n\n${result.text}` }], details: { url: result.url } };
		},
	});
}
