#!mainFile "../../main.opy"

globalvar meiFreezeDamageBoost = createWorkshopSetting(float[0:100], "Mei", "Weapon Freeze Damage Boost", 20)

rule "[Mei] Deal extra damage on primary fire":
    @Event playerDealtDamage
    @Hero mei
    @Condition eventAbility == Button.PRIMARY_FIRE

    damage(victim, attacker, meiFreezeDamageBoost / 100 * eventDamage)
