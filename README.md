# Setup and Test Commands

To complete this homework, an OpenClaw agent was used. Prior to interfacing with the agent via the TAMUS AI API, a node to the shim must be started with the .mjs located in the current directory:

```bash
node tamu-shim.mjs
```

From here, a new terminal can be opened and the following command can be used to prompt the agent:

```bash
openclaw agent --agent main -m "This is my prompt"
```

Additionally, the following commands can be used for agent debugging and miscellaneous agent information:

```bash
openclaw doctor
openclaw audit
openclaw exec-policy show
```

Session, log, and transcript information can all be found in:

```bash
~/.openclaw/agents/main/sessions/
```