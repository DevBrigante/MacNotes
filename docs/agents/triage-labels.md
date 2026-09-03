# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the right-hand column to match whatever vocabulary you actually use.

## `needs-device-check` — orthogonal to the five

The five roles above answer one question: **who does the work**. They do not answer a second one this project keeps running into: **what counts as done**.

MacNotes draws around a physical camera notch and follows the user across displays. Whole issues turn on whether the Notch Panel lands in the right strip of glass, survives a Space switch, or leaves the camera unobstructed. No test asserts any of that — a human has to look, on a real MacBook and on a real external monitor.

That is a statement about the acceptance criteria, not about who writes the code. An agent can implement these perfectly well. Folding the requirement into `ready-for-human` conflates the two questions and parks the work: an agent reading the table above sees "requires human implementation" and declines an issue it could have built.

So the hardware gate is its own label, applied **alongside** a triage role:

| Label                | Meaning                                                      |
| -------------------- | ------------------------------------------------------------ |
| `needs-device-check` | An agent implements it; a human signs it off on real hardware |

`ready-for-agent` + `needs-device-check` reads: build it, then hand it over to be judged. Keep `ready-for-human` for work an agent genuinely cannot produce.
