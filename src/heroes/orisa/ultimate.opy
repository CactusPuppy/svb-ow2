#!mainFile "../../main.opy"


rule "orisa - Pressed ultimate":
    @Event eachPlayer
    @Hero orisa
    @Condition eventPlayer.isHoldingButton(Button.ULTIMATE)
    @Condition eventPlayer.getUltCharge() == 100

    eventPlayer.CastingUltimate = true
    wait(0.5)
    waitUntil(not eventPlayer.isUsingAbility2(), 5)
    eventPlayer.CastingUltimate = false


rule "[orisa.del] Ultimate":
    @Event eachPlayer
    @Hero orisa
    @Condition eventPlayer.isUsingUltimate() == true

    eventPlayer.TemporaryCooldown = eventPlayer.getAbilityCooldown(Button.ABILITY_2)
    eventPlayer.CastingUltimate = true
    wait(0.16)
    #Deploy shield
    eventPlayer.setProjectileSpeed(50)
    eventPlayer.setProjectileGravity(abs(1000))
    eventPlayer.setAbilityCooldown(Button.ABILITY_2, 0)
    eventPlayer.allowButton(Button.ABILITY_2)
    wait(0.032)
    eventPlayer.forceButtonPress(Button.ABILITY_2)
    wait(0.032)
    eventPlayer.forceButtonPress(Button.ABILITY_2)
    #Wait until shield is deployed
    waitUntil(eventPlayer.isUsingAbility2(), 2)
    waitUntil(eventPlayer.getAbilityCooldown(Button.ABILITY_2) >= 2, 2)
    wait(0.032)
    #Reset
    eventPlayer.disallowButton(Button.ABILITY_2)
    eventPlayer.setAbilityCooldown(Button.ABILITY_2, eventPlayer.TemporaryCooldown - 0.256)
    eventPlayer.setProjectileGravity(100)
    eventPlayer.setProjectileSpeed(125)
