# Health UI Revamp: Liquid Metal Experience

Revamp the existing health metric widgets from static blocks to dynamic, "liquid metal" visualizations. This includes flowing rings for steps, a fluid-filled heart for heart rate, and a unique sleep depth visualizer, all adhering to the project's high-fidelity metallic aesthetic.

## Proposed Changes

### [Component] UI Visuals
Create a new set of custom painters and widgets to handle the "liquid metal" rendering logic.

#### [NEW] [health_visuals.dart](file:///C:/Users/kiran/Desktop/Arc/lib/widgets/health_visuals.dart)
- `LiquidMetalRing`: A circular progress indicator with a mercury-like flow effect.
- `LiquidMetalHeart`: A heart-shaped container that fills with metallic fluid based on pulse intensity or latest reading.
- `LiquidMetalSleepPool`: A multi-layered fluid container showing Sleep, Deep, and REM stages as different "densities" of liquid metal.

#### [MODIFY] [health_metric_card.dart](file:///C:/Users/kiran/Desktop/Arc/lib/widgets/health_metric_card.dart)
- Integrate `LiquidMetalHeart` into the heart rate display.
- Overhaul `HealthSleepCard` to use the `LiquidMetalSleepPool`.
- Update `_MetalProgress` to have a more fluid, high-gloss finish.

#### [MODIFY] [home_page.dart](file:///C:/Users/kiran/Desktop/Arc/lib/home_page.dart)
- Replace the standard progress bar in `_movementHero` with the new `LiquidMetalRing`.
- Refine the layout to give more breathing room to the new visual components.

## Verification Plan

### Manual Verification
- Verify the "Liquid Metal" aesthetic consistency across dark and light themes (Champagne/Dark Metal).
- Ensure animations (filling effects) are smooth and don't stutter.
- Check that the visualizations correctly reflect the data provided by `HealthService` without breaking the existing data flow.
