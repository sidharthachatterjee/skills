# Glossary

**Skill**:
A folder under `skills/` with a `SKILL.md`. Loaded on demand by the agent's Skill tool.

**User-invoked**:
A skill only the human fires, by name or through its OpenCode command. Its description is for humans.

**Model-invoked**:
A skill the agent may fire on its own when a task matches its description. The human can still fire it by name.

**Context pointer**:
Always-loaded text that names out-of-context material and the condition for reaching it. A skill description is one; a line in `AGENTS.md` naming a doc is another.

**Branch**:
A distinct case a skill handles. Each deserves one trigger in the description and decides what is inlined versus disclosed.

**Completion criterion**:
The condition that tells the agent a step is done.

**Leading word**:
A compact concept from the model's pretraining, repeated as a token, that anchors a region of behaviour (_tracer bullet_, _red_).

**Command**:
An OpenCode slash command in `commands/`. Used here only as the trigger for a user-invoked skill.
