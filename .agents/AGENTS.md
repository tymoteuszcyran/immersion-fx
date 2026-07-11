# ImmersionFX Agent Rules & Guidelines

ImmersionFX is a World of Warcraft retail addon designed to provide subtle, immersive screen and camera effects during combat. It focuses mostly on camera movement during combat to add immersion to the battle. Each spell effect must be subtle and must not be too intrusive to the gameplay. The primary philosophy is to avoid dizzying and headaches when applying new effects. 
Addon must be complaint with Blizzard's rules and compatible with new API changes that were introduced as part of Midnight's expansion.

Follow these project-specific rules, design patterns, and standards when developing or refactoring code.

---

## 1. Project Architecture

The addon uses a modular architecture structured around a shared addon table namespace injected by the WoW client:
* **Addon Namespace**: In every Lua file, retrieve the private addon table using:
  ```lua
  local addonName, IFX = ...
  ```
* **Modules**: Keep modules separated and bound to the `IFX` table:
  * `IFX.Core` ([Core.lua](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/Core.lua)): Event routing setup (`ADDON_LOADED`, `PLAYER_LOGIN`), logging, slash commands. It also initializes the `IFX.Animation` namespace and its handler registration API.
  * `IFX.Config` ([Config.lua](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/Config.lua)): Handles SavedVariables configuration database, defaults merging, and settings API.
  * `IFX.Events` ([Events.lua](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/Events.lua)): Registers and listens to gameplay events, routing them to the animation engine.
  * `IFX.SpellEffects` ([SpellEffects.lua](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/SpellEffects.lua)): Central registry exposing dynamic registration APIs (`RegisterProfile` and `RegisterProfiles`) for spell effects.
  * `IFX.Overlay` ([Overlay.lua](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/Overlay.lua)): Frame elements and overlay handling (flashes, pulses, vignettes, etc.).
  * `IFX.Engine` ([EffectEngine.lua](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/EffectEngine.lua)): Queries spell profiles and dynamically triggers registered animation handlers.

* **Spells Directory Structure**:
  Spell effects and specialized animations are modularized and contained within the `Spells/` folder, structured by Class and Specialization:
  ```
  Spells/
  ├── <Class>/
  │   ├── Common/               <-- Baseline class abilities and shared helper functions
  │   └── <Specialization>/     <-- Spec-specific abilities and custom animations (e.g. Frost.lua)
  └── General/                  <-- General abilities shared by all classes
  ```
  * Every new spell configuration or class-specific animation file must be registered in the [ImmersionFX.toc](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/ImmersionFX.toc) file under the `# Modular Spell Configurations` section to load.
  * Avoid placing baseline code or shared animations in specific specialization modules; move them to class `Common/` folders, or initialize them in [Core.lua](file:///c:/Program%20Files%20%28x86%29/World%20of%20Warcraft/_retail_/Interface/AddOns/ImmersionFX/Core.lua) if shared by all classes.

---

## 2. Configuration & SavedVariables

* **DB Reference**: The addon database is stored globally as `ImmersionFXDB`. It is linked to `IFX.db` in `Config:InitializeDB()`.
* **Decoupling**: Never access `IFX.db` or `ImmersionFXDB` directly outside of `Config.lua`. Always query settings via the Settings API, such as:
  * `IFX.Config:IsEnabled()`
  * `IFX.Config:GetIntensity()`
  * `IFX.Config:IsEffectTypeEnabled(effectType)`
* **Feature Merges**: When adding new configuration fields, update `Config.Defaults`. Use the deep merge `CopyDefaults` function to avoid erasing user settings during addon updates.

---

## 3. Lua Style and Naming Guidelines

* **Locals vs Globals**: Declare helper functions, loop counters, and temporary references as `local` to optimize performance and prevent namespace pollution.
* **Capitalization**:
  * Use **PascalCase** for module names and exposed module methods (e.g., `IFX.Config`, `Core:Initialize()`, `Config:GetIntensity()`).
  * Use **camelCase** for properties within config defaults and effect/spell structures (e.g., `intensityMultiplier`, `castDuration`, `driftOut`).
* **Clean Code & Modular Registration**:
  * Avoid duplicate functions. Keep modular files clean and focused.
  * Register spell profiles using `IFX.SpellEffects:RegisterProfiles(profiles)`.
  * Register custom spec/class animations dynamically using `IFX.Animation:Register(name, eventType, handlerFunc)`. Do not hardcode routing in `EffectEngine.lua`.

---

## 4. Camera and CVar Safety

Because ImmersionFX manipulates user CVars and camera properties, it is **critical** to protect the player's baseline UI state:
* **Baseline Capture**: Always capture the player's initial camera state or CVar before starting an animation:
  ```lua
  local baselineDistance = GetCameraZoom()
  local baselineVertical = tonumber(GetCVar("test_cameraVerticalOffset")) or 0
  ```
* **Guaranteed Cleanup**: Always schedule a safety cleanup action via `C_Timer.After` to guarantee original settings are restored, even if the animation sequence is interrupted or dynamic values fail:
  ```lua
  C_Timer.After(totalDuration + safetyMargin, function()
      SetCVar("test_cameraVerticalOffset", baselineVertical)
  end)
  ```

---

## 5. Event Handling

* Keep event logic inside `Events.lua` lightweight.
* Filter events for the player where applicable using `RegisterUnitEvent` (e.g., `"UNIT_SPELLCAST_START", "player"`).
* Verify configuration status (`IFX.Config:IsEnabled()`) early in event handlers to prevent processing overhead.

---

## 6. Logging and Debugging

* Avoid standard `print()` statements for debugging.
* Use `IFX:Log(message, isError)` for debugging outputs. Debug messages are automatically throttled unless `IFX.db.global.debugMode` is enabled (errors are printed regardless).
