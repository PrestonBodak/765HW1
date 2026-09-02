# tamu-shim — TAMUS AI API compatibility shim for OpenClaw

**Why:** OpenClaw's `openai-completions` adapter sends `"content": null` on assistant
messages that contain only tool calls (correct per the OpenAI spec). The TAMUS AI
Chat proxy validates `content` strictly and returns **HTTP 422** for `null` — which
kills every multi-turn agent tool loop (all of Homework 1 Task 3). OpenClaw has no
config flag that changes this (`compat.requiresStringContent` only flattens content
*arrays*; `compat.strictMessageKeys` strips `tool_calls` and breaks tool use).

**What this does:** a ~40-line local proxy (Node standard library, no dependencies —
Node is already installed for OpenClaw). It rewrites `content: null → ""` in the
outbound `messages` array, forwards to `https://chat-api.tamu.ai`, and streams the
response back unchanged. **Tested:** with the shim, the agent's multi-turn tool loop
completes normally via TAMUS `protected.gpt-4o`.

## Run it

```bash
export TAMU_API_KEY="<your key from chat.tamu.ai>"
node tamu-shim.mjs          # listens on http://127.0.0.1:8899
```

Keep it running (a second terminal, `tmux`, `nohup … &`, or the user service below).

## Point OpenClaw at the shim

```bash
openclaw config set models.providers.tamus.api openai-completions
openclaw config set models.providers.tamus.baseUrl http://127.0.0.1:8899/openai
openclaw config set models.providers.tamus.apiKey via-shim
openclaw config set models.providers.tamus.request.allowPrivateNetwork true
openclaw config set models.providers.tamus.models.0.id protected.gpt-4o
openclaw config set models.providers.tamus.models.0.compat.supportsTools true
openclaw config validate
openclaw models set tamus/protected.gpt-4o
openclaw daemon restart
```

The **real key lives only in the shim's environment**, not in `openclaw.json`.

## Optional: run as a user service

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/tamu-shim.service <<'EOF'
[Unit]
Description=TAMUS AI compatibility shim for OpenClaw
[Service]
Environment=TAMU_API_KEY=%h/.config/tamu-shim.key
ExecStart=/usr/bin/env bash -lc 'TAMU_API_KEY=$(cat %h/.config/tamu-shim.key) node %h/tamu-shim.mjs'
Restart=on-failure
[Install]
WantedBy=default.target
EOF
printf '%s' "<your key>" > ~/.config/tamu-shim.key && chmod 600 ~/.config/tamu-shim.key
cp tamu-shim.mjs ~/tamu-shim.mjs
systemctl --user daemon-reload && systemctl --user enable --now tamu-shim.service
loginctl enable-linger "$USER"
```

## Notes

- If OpenClaw stops sending `content: null` in a future version, the shim becomes a
  harmless pass-through — safe to leave in place.
- The shim also sends a `curl`-style `User-Agent`; the TAMUS site's Cloudflare layer
  blocks some default library user agents.
- This is a workaround for a client/proxy mismatch. The cleaner fix is upstream —
  OpenClaw coercing `null → ""` for non-native `openai-completions` endpoints (it
  already does similar compat shaping), or TAMU IT relaxing the proxy to accept
  `content: null` (which is valid OpenAI).
