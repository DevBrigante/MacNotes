# Calendar consent activates MacNotes

MacNotes activates before asking EventKit for full Calendar access. The app normally runs as an accessory application until the Planner opens, but the system consent alert needs a responsive foreground application to receive its buttons' input. Activating at the request boundary preserves that requirement even when the request is initiated from a future Calendar surface.

## Considered Options

Relying on the Planner window to activate MacNotes leaves the permission request dependent on presentation order. An EventKit request is asynchronous and macOS owns the consent alert, so a request made while the app is inactive can leave the person looking at an alert without an app window ready to receive its result. Activating directly before the request makes the source responsible for the platform condition it needs.

Ignoring EventKit errors with `try?` kept the card in its initial state when the system declined to complete a request. The Calendar model now presents an unavailable state with retry and System Settings actions. A source stub covers that state transition; the system-owned consent alert itself has no deterministic test seam.

## Consequences

A failed access request is visible and recoverable instead of appearing to do nothing. People can retry after dismissing a transient system condition or open Calendar privacy settings when macOS has recorded a denial. The Calendar usage-description key and sandbox entitlement remain required for the request to be eligible.
