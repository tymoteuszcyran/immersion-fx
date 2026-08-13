local addonName, IFX = ...

-- High Immersion Camera Placement Profile
-- Balances tight cinematic over-the-shoulder framing with ground telegraph clarity
IFX.Camera:RegisterProfile("high_immersion", {
    name = "High Immersion (Over-the-Shoulder)",
    description = "Cinematic over-the-shoulder framing with elevated eye-line and dynamic pitch for ground mechanic awareness.",
    cvars = {
        test_cameraOverShoulder = 1.2,
        test_cameraVerticalOffset = 0.6,
        test_cameraDynamicPitch = 1,
        test_cameraHeadMovement = 1,
    }
})
