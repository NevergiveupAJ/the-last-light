// Serves the Godot web build. The engine (index.wasm) is stored gzipped because it is
// bigger than Cloudflare's per-file limit; it is sent with Content-Encoding: gzip so the
// browser unpacks it.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/index.wasm") {
      const res = await env.ASSETS.fetch(new Request(new URL("/index.wasm.gz", url), request));
      if (!res.ok) return res;
      return new Response(res.body, {
        headers: {
          "Content-Type": "application/wasm",
          "Content-Encoding": "gzip",
          "Cache-Control": "public, max-age=3600",
        },
        encodeBody: "manual",
      });
    }
    return env.ASSETS.fetch(request);
  },
};
