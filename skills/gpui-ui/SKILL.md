---
name: gpui-ui
description: Builds and reviews Rust user interfaces made with GPUI, the UI framework from Zed. Covers views and components, entity state and async tasks, key bindings and focus, popups, lists, text input, and GPUI tests. Use whenever a project depends on the gpui crate or the user mentions GPUI.
metadata:
  version: "0.1.0"
---

# Build with GPUI

GPUI reshapes its API between versions, so GPUI code written from memory often targets a version the project doesn't use. It also gives you primitives, not finished controls: an element has no focus, key bindings, hover or focus styling, or text editing until you add them.

## Read first

1. Find the installed source. Its directory holds `src/`, `examples/` and `docs/`:

   ```sh
   cargo metadata --format-version 1 | jq -r '.packages[] | select(.name == "gpui") | .version, .manifest_path'
   ```

2. Read the example nearest your task in `examples/`, like `input.rs` for a text field or `tab_stop.rs` for Tab order, and the project's own views. They document this version. Zed's main branch and snippets online may not.
3. Write only names the installed source defines, and search `src/` for any you are unsure of. `View<T>`, `Model<T>`, `ViewContext`, `WindowContext`, `cx.new_view` and `cx.new_model` come from older versions. Later ones use `Entity<T>`, `Context<T>`, `Window` with `App`, and `cx.new`.
4. When the source doesn't settle how something behaves, like where focus lands or whether a handler runs, answer it with a temporary `#[gpui::test]`, then remove the test.

Look in the project and its component library for an existing control before you build one. Adding a dependency is the user's decision.

## Rules

In a review, check the change against every rule.

### State and async

- State that outlives a frame lives in an entity. A view is an `Entity<T>` whose `T` implements `Render`. A stateless piece is a struct that implements `RenderOnce`, derives `IntoElement`, and is configured through builder methods.
- Call `cx.notify()` after changing anything `render` reads. Without it the view is not drawn again.
- `render` only builds elements. Start tasks, subscriptions, I/O and focus changes from constructors and event handlers.
- Inside `entity.update(cx, |this, cx| ...)` use the closure's `cx`. Updating an entity that is already being updated panics.
- A dropped `Task` is cancelled and a dropped `Subscription` stops listening. Keep each in a field, await it, or call `.detach()`. For work that a newer request replaces, like search as you type, assign the new `Task` to the same field, which cancels the old one.
- The foreground thread draws every frame. Do slow work in `cx.background_spawn` and await it from `cx.spawn(async move |this, cx| ...)`. There `this` is a `WeakEntity`: update the view through it, stop if the view is gone, and show any failure in the UI.
- Two entities that hold each other are never dropped. A child reaches its parent with `cx.emit` and the parent's `cx.subscribe`, or through a `WeakEntity`.

### Keyboard and focus

- A key binding reaches only the focus path: the focused element and its ancestors. Put `.track_focus(&focus_handle)`, `.key_context("TodoList")` and `.on_action(cx.listener(Self::remove))` on one element, bind with `KeyBinding::new("backspace", Remove, Some("TodoList"))`, and focus a handle when the window opens. While nothing is focused, no element's action handler runs.
- App-wide commands like quit register with `cx.on_action` on `App`, which runs wherever focus is.
- Give every binding a context unless it is app-wide. A binding without one ties with the innermost context and the binding added later wins, so register app-wide bindings first.
- Everything a click can do needs a key. Have both call the same method, so they validate and change state the same way.
- An action handler ends the action there. Call `cx.propagate()` to let an ancestor handle it too. Mouse and key listeners are the reverse: they keep bubbling until `cx.stop_propagation()`.
- Enter and Space already click the focused element that has `on_click`, on key-up, so an Enter binding on the same element acts twice.
- Nothing else is bound. Tab needs actions that call `window.focus_next()` and `window.focus_prev()`, with `tab_index` or `tab_stop` on each stop, set on its `FocusHandle` when the element tracks one. Quitting, menu items and editing keys need bindings too.
- When the focused element stops rendering, nothing is focused and its ancestors' bindings go dead. Move focus first, or restore it from `cx.on_focus_lost`.

### Elements and styling

- `on_click`, `on_hover`, `tooltip`, dragging, scrolling and element state need `.id(...)`. Keep ids unique among siblings and stable across frames. In a list that reorders or filters, derive each from the item's identity, not its index.
- An element shows no hover, pressed or focus state until you style it with `.hover(...)`, `.active(...)` and `.focus(...)`, or `.focus_visible(...)` where the version has it. Keyboard focus must always be visible, and selected, disabled and invalid must read without color alone.
- Take colors, spacing and type sizes from the app's theme, or define them in one place if it has none. Text needs a 4.5:1 contrast ratio with its background. Large text, control boundaries and focus indicators need 3:1.

### Popups

- Render a popup as `deferred(anchored().child(...))` so it paints above the rest of the window and stays inside it, and call `.occlude()` on its surface so clicks don't reach what is underneath.
- Make it a view with its own focus handle and key context. Before opening, save `window.focused(cx)`, then focus the popup. Close it by emitting `DismissEvent` on Escape, on a choice, on `on_mouse_down_out` and when it loses focus. Give focus back to what had it only if the popup still holds focus, or you take it from what the person just clicked.
- Render a dialog as a full-size `.occlude()` layer at the root of the window's view, not as `deferred`. Some versions panic on a `deferred` inside a `deferred`, which is what a popup opened from a `deferred` dialog would be.

### Lists

- For rows of one height use `uniform_list`, which builds only the visible rows. For varying heights use `list` with a `ListState` kept in the view, and report every change through `splice` or `reset` so it doesn't lay out stale rows. Both draw nothing until their height is bounded, by a sized parent or by `ListSizingBehavior::Infer` when the list should fit its rows.
- After a key moves the selection, scroll it into view with `scroll_to_item` or `scroll_to_reveal_item`.
- In a list with a search field, keep focus in the field and move a highlighted row with actions.

### Text input

- Typed text reaches a view through the platform input handler, and only while its focus handle is focused: implement `EntityInputHandler` and call `window.handle_input` during paint. Input methods, dead keys and the emoji picker deliver text no other way, so a field built on key-down events loses them. Reuse the project's field or start from `examples/input.rs`.
- The platform's ranges count UTF-16 units and Rust strings count UTF-8 bytes. Convert at the boundary and test with emoji.

### Accessibility

- Screen reader support depends on the version. If the installed source has `src/_accessibility.rs`, follow it: every control gets an id, a role and a label. If it doesn't, the app exposes nothing to assistive technology, so say that in your report.

## Test it

- Add `gpui` with its `test-support` feature to `[dev-dependencies]` and write `#[gpui::test]` functions that take `&mut TestAppContext`. `cx.add_window_view(...)` returns the view and a `VisualTestContext` for its window.
- A test starts with no key bindings and an inactive window, where focus and blur listeners never fire. Register the app's bindings and call `window.activate_window()` first.
- Drive the real path and assert the resulting state and where focus is, not that a callback ran. Keys: `cx.simulate_keystrokes("down enter")`, which sends key-down only, so the Enter and Space click needs `cx.simulate_event` with a `KeyUpEvent`. Actions: `cx.dispatch_action(...)`. Clicks: tag the element with `.debug_selector(...)` and `cx.simulate_click` the center of its `cx.debug_bounds(...)`.
- Spawned work runs only when you call `cx.run_until_parked()`. Use `cx.background_executor().timer(...)` for delays. Awaiting anything GPUI doesn't schedule panics.
- For a new control, cover each key in both directions, activation by key and by click, every way of closing it and where focus returns, and removing the focused item.
- Prove that the tests of a new control can fail: remove one behavior at a time, check that a test fails, and put it back. A behavior you can remove unnoticed needs a test.
- The test window is simulated. Layout with real fonts, text composition, native menus and screen readers need the running app. If you can't run it, say so.

## When you're done

1. Run the project's format, lint, build and test commands.
2. Report each command with its result, any key behavior you had to invent, what you could not exercise in the running app, and anything in the installed source that contradicts this skill.
