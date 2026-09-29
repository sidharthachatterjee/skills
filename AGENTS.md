# Skills repo

A collection of agent skills. Vocabulary lives in [GLOSSARY.md](GLOSSARY.md); use its terms.

## Layout

- `skills/<name>/SKILL.md`: one folder per skill. `name` in frontmatter matches the folder name (lowercase, hyphen-separated).
- Reference a skill needs only on some branches goes in a sibling file in the same folder, linked from `SKILL.md`.
- `commands/<name>.md`: thin OpenCode command that fires a user-invoked skill. Create the folder when the first one exists.
- `scripts/link-skills.sh`: symlinks skills into `~/.agents/skills` and commands into `~/.config/opencode/commands`.

Every skill is listed in `README.md` under **User-invoked** or **Model-invoked**, with its name linked to its `SKILL.md` and a one-line description.

## Invocation

Decide invocation first; it decides how the description is written.

- **Model-invoked**: the agent can reach it autonomously. The description is model-facing: what it is, then one trigger per distinct branch, front-loading the words I actually use in prompts.
- **User-invoked**: only I fire it. Set `disable-model-invocation: true` and write a one-line human-facing description. OpenCode ignores that field, so also add `commands/<name>.md` whose body is `Call the Skill tool with "<name>".` plus `$ARGUMENTS`.

Choose model-invoked only when the agent or another skill must reach it on its own. Otherwise user-invoked, which costs no context.

One skill uses another by saying `Call the Skill tool with "<name>".` The target must be model-invoked. Shared reference lives in the skill that owns it.

## Writing a skill

- Steps first, in order. Each step ends on a completion criterion that is checkable and exhaustive.
- Push reference down behind a context pointer when only some branches need it. Keep the top legible.
- Prefer a leading word the model already knows over a sentence that describes the same idea.
- State the target behaviour. Use a prohibition only for a hard guardrail, paired with the positive.
- One source of truth per meaning. Leave facts the environment already states (config, `--help`, directory layout) to the environment.
- Delete any sentence that does not change behaviour versus the model's default.

## After changing a skill

1. Update the `README.md` entry.
2. Run `scripts/link-skills.sh` if a skill or command was added, renamed, or removed.
