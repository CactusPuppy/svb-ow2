#!mainFile "../../main.opy"


globalvar IcingMaxRange
globalvar IcingSteps
globalvar IcingRadius
globalvar IcingDuration
globalvar IcingCooldown
globalvar IcingOverwritesButton
globalvar IcingMinSpeed
globalvar IcingMaxSpeed
globalvar IcingDamageOnImpact
globalvar IcingSlow
globalvar IcingFreezeOnImpact
globalvar IcingSpeedIncrease
globalvar IcingType


playervar IcingEffects
playervar IcingCreateStep
playervar IcingEndPosition
playervar IcingStartPosition
playervar IcingStepPositions
playervar IcingCurrentSpeed
playervar IcingSnowballEffect
playervar IcingActiveCooldown
playervar IcingPlayersDamaged
playervar IcingPlayersToDamage
playervar InIcingOfPlayer


subroutine ClearIcing
subroutine ChaseIcingSpeed
subroutine IcingFreezeAndDamageOnImpact

subroutine DeployIcing
subroutine DisableAbility

rule "Initialise Icing":
    #Workshop setting that determines what button icing will use, opening this action might be laggy.
    IcingOverwritesButton = createWorkshopSetting(enum["None", "Primary Fire", "Secondary Fire", "Ability 1 (Cryofreeze)", "Ability 2 (Ice Wall)"], "Mei - Icing ability", "What button should Icing overwrite?", 0, -10)
    #Set the variable from the combo index to the actual button
    IcingOverwritesButton = [null, Button.PRIMARY_FIRE, Button.SECONDARY_FIRE, Button.ABILITY_1, Button.ABILITY_2][IcingOverwritesButton]
    #Max range
    IcingMaxRange = createWorkshopSetting(float[5:50], "Mei - Icing ability", "Icing max range", 20, 3)
    #Icing steps (more = more accurate, but more effects used)
    IcingSteps = createWorkshopSetting(int[5:50], "Mei - Icing ability", "Steps (Higher = more circles on the ground)", 20, 5)
    #Width of icing
    IcingRadius = createWorkshopSetting(float[0.5:5], "Mei - Icing ability", "Icing radius (width)", 1.5, 4)
    #Duration of icing
    IcingDuration = createWorkshopSetting(float[0:20], "Mei - Icing ability", "Icing Duration", 5, 2)
    #Cooldown of icing
    IcingCooldown = createWorkshopSetting(float[0:100], "Mei - Icing ability", "Icing Cooldown", 10, 1)
    #Icing min player speed
    IcingMinSpeed = createWorkshopSetting(int[100:400], "Mei - Icing ability", "Minimum speed when standing on icing (Percentage relative to regular move speed)", 200, 6)
    #Icing max player speed
    IcingMaxSpeed = createWorkshopSetting(int[200:500], "Mei - Icing ability", "Maximum speed when standing on icing (Percentage relative to regular move speed)", 300, 7)
    #Icing damage on impact
    IcingDamageOnImpact = createWorkshopSetting(int[0:200], "Mei - Icing ability", "Damage on impact of initial Icing hit", 0, 8)
    #Icing freeze on impact
    IcingFreezeOnImpact = createWorkshopSetting(float[0:3], "Mei - Icing ability", "Freeze duration on impact of initial Icing hit", 0, 9)
    #Set how icing is used
    IcingType = createWorkshopSetting(enum["Create a straight path that \"slides\" teammates from point X to point Y", "Create a straight path that grants a static movement speed buff to teammates"], "Mei - Icing ability", "Icing type - How does Icing function?", 0, -1)
    #Icing slow
    IcingSlow = createWorkshopSetting(int[0:100], "Mei - Icing ability", "Slow for enemies walking over icing", 0, 20)
    #Movement increase for teammates walking on Icing (if Icing type is set to option 2)
    IcingSpeedIncrease = createWorkshopSetting(int[0:200], "Mei - Icing ability", "Movement increase for teammates walking on Icing (if Icing type is set to option 2)", 15, 21)


rule "Icing Cooldown HUD if icing is on Primary or Secondary fire":
    @Condition IcingOverwritesButton != null
    @Condition (IcingOverwritesButton == Button.PRIMARY_FIRE or IcingOverwritesButton == Button.SECONDARY_FIRE) == true
    
    hudText([i for i in localPlayer if localPlayer.getCurrentHero() == Hero.MEI and true], null, " \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", " \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", HudPosition.RIGHT, 99, null, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_STRING_AND_COLOR, SpecVisibility.DEFAULT)
    hudHeader([i for i in localPlayer if localPlayer.getCurrentHero() == Hero.MEI and true], "Icing: {0}".format(localPlayer.IcingActiveCooldown), HudPosition.RIGHT, 100, Color.RED if localPlayer.IcingActiveCooldown else Color.AQUA, HudReeval.VISIBILITY_STRING_AND_COLOR, SpecVisibility.DEFAULT)


def DisableAbility():
  if IcingOverwritesButton != Button.PRIMARY_FIRE:
    eventPlayer.disallowButton(IcingOverwritesButton)
    waitUntil(eventPlayer.hero != evalOnce(eventPlayer.hero), 9999)
    eventPlayer.allowButton(IcingOverwritesButton)

rule "Disable original Ability":
    @Event eachPlayer
    @Condition IcingOverwritesButton != null
    @Hero mei
    
    DisableAbility()


def DeployIcing():
    @Name "[mei/icing.opy] Subroutine: Deploy Icing"

    if IcingOverwritesButton == null: return
    if eventPlayer.isAlive() == false: return
    if not eventPlayer.getAbilityCooldown(IcingOverwritesButton) == 0: return
    if not eventPlayer.IcingActiveCooldown == 0: return
    if not eventPlayer.AvalancheTimer != true: return
    if (eventPlayer.hasStatusEffect(Status.HACKED) or eventPlayer.hasStatusEffect(Status.KNOCKED_DOWN) or eventPlayer.hasStatusEffect(Status.ASLEEP) or eventPlayer.hasStatusEffect(Status.FROZEN) or eventPlayer.hasStatusEffect(Status.STUNNED) or eventPlayer.isDead()): return

    if IcingOverwritesButton == Button.PRIMARY_FIRE:
        eventPlayer.disallowButton(Button.PRIMARY_FIRE)
        eventPlayer.cancelPrimaryAction()
        eventPlayer.setAmmo(0, eventPlayer.getAmmo(0) + 1)

    ClearIcing()
    
    #Set cooldown of button used for Icing
    eventPlayer.setAbilityCooldown(IcingOverwritesButton, IcingCooldown)
    eventPlayer.IcingActiveCooldown = IcingCooldown
    eventPlayer.IcingPlayersDamaged = []
    chase(eventPlayer.IcingActiveCooldown, 0, duration=IcingCooldown, ChaseReeval.DESTINATION_AND_DURATION)
    #Communite, for extra flare
    eventPlayer.communicate(Comms.GOING_IN)
    #Reset icing
    eventPlayer.IcingEffects = []
    eventPlayer.IcingStepPositions = []
    #set the start of icing right in front of the player
    eventPlayer.IcingStartPosition = vect((eventPlayer.getEyePosition() + (eventPlayer.getFacingDirection() * (IcingRadius + 1))).x, eventPlayer.getEyePosition().y, (eventPlayer.getEyePosition() + (eventPlayer.getFacingDirection() * (IcingRadius + 1))).z)
    #Set the end position, always at the same eye position as event player
    eventPlayer.IcingEndPosition = raycast(eventPlayer.getEyePosition(), vect((eventPlayer.getEyePosition() + eventPlayer.getFacingDirection() * IcingMaxRange).x, eventPlayer.getEyePosition().y, (eventPlayer.getEyePosition() + eventPlayer.getFacingDirection() * IcingMaxRange).z), null, null, false).getHitPosition()
    #Snowball!
    createEffect(getAllPlayers(), Effect.SPHERE, Color.SKY_BLUE, eventPlayer.IcingStepPositions.last() + Vector.UP * 3, 0.25, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    eventPlayer.IcingSnowballEffect = getLastCreatedEntity()

    createEffect(getAllPlayers(), Effect.MEI_FROZEN_SOUND, eventPlayer.getTeam(), eventPlayer.IcingStartPosition, 50, EffectReeval.NONE)
    eventPlayer.IcingEffects = eventPlayer.IcingEffects.concat(getLastCreatedEntity())
    createEffect(getAllPlayers(), Effect.MEI_FROZEN_SOUND, eventPlayer.getTeam(), eventPlayer.IcingEndPosition, 50, EffectReeval.NONE)
    eventPlayer.IcingEffects = eventPlayer.IcingEffects.concat(getLastCreatedEntity())

    playEffect(getAllPlayers(), DynamicEffect.BUFF_IMPACT_SOUND, Color.WHITE, eventPlayer, 75)

    #Loop to create effects and array for Icing location
    for eventPlayer.IcingCreateStep in range(0, IcingMaxRange, IcingMaxRange / IcingSteps):
        #Set position of next icing circle
        eventPlayer.IcingStepPositions = eventPlayer.IcingStepPositions.concat(eventPlayer.IcingStartPosition + directionTowards(eventPlayer.IcingStartPosition, eventPlayer.IcingEndPosition) * eventPlayer.IcingCreateStep)
        #Cast icing down in case we're going over slopes
        eventPlayer.IcingStepPositions[eventPlayer.IcingStepPositions.index(eventPlayer.IcingStepPositions.last())] = raycast(eventPlayer.IcingStepPositions.last(), eventPlayer.IcingStepPositions.last() + Vector.DOWN * 10, null, null, false).getHitPosition()
        #Slow enemies hit by the impact, if set by Workshop Setting
        async(IcingFreezeAndDamageOnImpact, AsyncBehavior.RESTART)

        #Create a bunch of cool effects at current position and save them to a variable
        createEffect(getAllPlayers(), Effect.RING, eventPlayer.getTeam(), eventPlayer.IcingStepPositions.last(), IcingRadius, EffectReeval.NONE)
        eventPlayer.IcingEffects = eventPlayer.IcingEffects.concat(getLastCreatedEntity())

        # Only create these effects half ofthe time
        if (eventPlayer.IcingCreateStep % (IcingMaxRange * 2 / IcingSteps)):
            createEffect(getAllPlayers(), Effect.CLOUD, Color.WHITE, eventPlayer.IcingStepPositions.last() + Vector.DOWN * 0.25, IcingRadius * 1.5, EffectReeval.NONE)
            eventPlayer.IcingEffects = eventPlayer.IcingEffects.concat(getLastCreatedEntity())
            createEffect(getAllPlayers(), Effect.SPARKLES, eventPlayer.getTeam(), eventPlayer.IcingStepPositions.last() + Vector.DOWN * 0.25, IcingRadius * 1.5, EffectReeval.NONE)
            eventPlayer.IcingEffects = eventPlayer.IcingEffects.concat(getLastCreatedEntity())

            playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, eventPlayer.getTeam(), eventPlayer.IcingStepPositions.last(), IcingRadius * 2)
            playEffect(getAllPlayers(), DynamicEffect.GOOD_PICKUP_EFFECT, Color.WHITE, eventPlayer.IcingStepPositions.last(), IcingRadius * 2)
            playEffect(getAllPlayers(), DynamicEffect.GOOD_PICKUP_EFFECT, eventPlayer.getTeam(), eventPlayer.IcingStepPositions.last(), IcingRadius * 1)
            playEffect(getAllPlayers(), DynamicEffect.BUFF_IMPACT_SOUND, Color.WHITE, eventPlayer.IcingStepPositions.last(), 25)

            wait(0.032)


    destroyEffect(eventPlayer.IcingSnowballEffect)
    #Clear after delay (duration)
    waitUntil(eventPlayer.hero != evalOnce(eventPlayer.hero), IcingDuration)
    ClearIcing()
    waitUntil(eventPlayer.IcingActiveCooldown == 0, IcingCooldown)
    if IcingOverwritesButton == Button.PRIMARY_FIRE:
        eventPlayer.allowButton(Button.PRIMARY_FIRE)


rule "Presses Ability":
  @Event eachPlayer
  @Hero mei
  @Condition ((IcingOverwritesButton == Button.PRIMARY_FIRE and eventPlayer.isFiringPrimaryFire()) or (IcingOverwritesButton != Button.PRIMARY_FIRE and eventPlayer.isHoldingButton(IcingOverwritesButton))) == true

  async(DeployIcing, AsyncBehavior.RESTART)

rule "Player is on Icing and Icing Type is set to slide":
    @Event eachPlayer
    @Condition IcingType == 0
    @Condition eventPlayer.isOnGround() == true
    @Condition eventPlayer.AvalancheTimer != true
    @Condition any([len(player.IcingStepPositions) > 0 for player in getPlayersOnHero(Hero.MEI, eventPlayer.getTeam())]) == true
    @Condition any([distance(eventPlayer, player) < IcingRadius for player in getPlayersOnHero(Hero.MEI, eventPlayer.getTeam())[0].IcingStepPositions]) == true
    
    eventPlayer.InIcingOfPlayer = ([player for player in getPlayers(eventPlayer.getTeam()) if player.getCurrentHero() == Hero.MEI and len(player.IcingStepPositions) > 0])[0]
    #Accelerate in current moving direction
    eventPlayer.startAcceleration(directionTowards(vect(0, 0, 0), evalOnce(eventPlayer.getThrottle() if eventPlayer.getThrottle() != vect(0, 0, 0) else vect(0, 0, 1))), 400, 200, Relativity.TO_PLAYER, AccelReeval.NONE)
    eventPlayer.startForcingThrottle(0, 0, 0, 0, 0, 0)

    async(ChaseIcingSpeed, AsyncBehavior.NOOP)
    waitUntil(not (IcingType == 0 and eventPlayer.isOnGround() and not eventPlayer.AvalancheTimer and any([len(player.IcingStepPositions) > 0 for player in getPlayersOnHero(Hero.MEI, eventPlayer.getTeam())]) and any([distance(eventPlayer, player) < IcingRadius for player in getPlayersOnHero(Hero.MEI, eventPlayer.getTeam())[0].IcingStepPositions])), 99999)
    wait(0.032)
    eventPlayer.stopAcceleration()
    eventPlayer.InIcingOfPlayer = null
    eventPlayer.AddSpeedMod -= eventPlayer.IcingCurrentSpeed
    eventPlayer.IcingCurrentSpeed = 0
    #Don't reset speed is using Avalanche
    if eventPlayer.AvalancheTimer != true:
        eventPlayer.stopForcingThrottle()


rule "Speed up teammates walking on icing (if enabled)":
    @Event eachPlayer
    @Condition IcingType == 1
    @Condition (any([player != 0 and distance(player, eventPlayer.getPosition()) < IcingRadius for player in ([player for player in getPlayers(eventPlayer.getTeam()) if player.hero == Hero.MEI and len(player.IcingStepPositions) > 0]).IcingStepPositions])) == true
    
    eventPlayer.AddSpeedMod += IcingSpeedIncrease
    waitUntil(not ((any([player != 0 and distance(player, eventPlayer.getPosition()) < IcingRadius for player in ([player for player in getPlayers(eventPlayer.getTeam()) if player.hero == Hero.MEI and len(player.IcingStepPositions) > 0]).IcingStepPositions])) and IcingType == 1), 99999)
    eventPlayer.AddSpeedMod -= IcingSpeedIncrease
    if RULE_CONDITION:
        goto RULE_START
    


rule "Slow down enemies walking on icing (if enabled)":
    @Event eachPlayer
    @Condition IcingSlow > 0
    @Condition (any([player != 0 and distance(player, eventPlayer.getPosition()) < IcingRadius for player in ([player for player in getPlayers(getOppositeTeam(eventPlayer.getTeam())) if player.hero == Hero.MEI and len(player.IcingStepPositions) > 0]).IcingStepPositions])) == true
    
    eventPlayer.AddSpeedMod -= IcingSlow
    waitUntil(not ((any([player != 0 and distance(player, eventPlayer.getPosition()) < IcingRadius for player in ([player for player in getPlayers(getOppositeTeam(eventPlayer.getTeam())) if player.hero == Hero.MEI and len(player.IcingStepPositions) > 0]).IcingStepPositions])) and IcingSlow > 0), 99999)
    eventPlayer.AddSpeedMod += IcingSlow
    if RULE_CONDITION:
        goto RULE_START
    


def ClearIcing():
  @Name "Subroutine - Clear Icing"
  
  #Clear icing and all of it's effects
  while len(eventPlayer.IcingEffects) > 0:
    destroyEffect(eventPlayer.IcingEffects[0])
    eventPlayer.IcingEffects = eventPlayer.IcingEffects.exclude(eventPlayer.IcingEffects[0])
    destroyEffect(eventPlayer.IcingEffects[0])
    eventPlayer.IcingEffects = eventPlayer.IcingEffects.exclude(eventPlayer.IcingEffects[0])
    destroyEffect(eventPlayer.IcingEffects[0])
    eventPlayer.IcingEffects = eventPlayer.IcingEffects.exclude(eventPlayer.IcingEffects[0])
    eventPlayer.IcingStepPositions = eventPlayer.IcingStepPositions.exclude(eventPlayer.IcingStepPositions[0])
    wait(0.032)
  #Set to empty, just in case
  eventPlayer.IcingStepPositions = []


def ChaseIcingSpeed():
    @Name "Subroutine - Chase Icing Speed"

    #Slowly accelerate player between a range
    eventPlayer.AddSpeedMod += IcingMinSpeed - 100
    eventPlayer.AddSpeedMod -= (IcingMaxSpeed-IcingMinSpeed) / 60
    for eventPlayer.IcingCurrentSpeed in range(IcingMinSpeed - 100, IcingMaxSpeed - 100, (IcingMaxSpeed - IcingMinSpeed) / 60):
        eventPlayer.AddSpeedMod += (IcingMaxSpeed-IcingMinSpeed) / 60
        wait(0.016)
        if not (IcingType == 0 and eventPlayer.isOnGround() and not eventPlayer.AvalancheTimer and any([len(player.IcingStepPositions) > 0 for player in getPlayersOnHero(Hero.MEI, eventPlayer.getTeam())]) and any([distance(eventPlayer, player) < IcingRadius for player in getPlayersOnHero(Hero.MEI, eventPlayer.getTeam())[0].IcingStepPositions])):
            return
    eventPlayer.AddSpeedMod += (IcingMaxSpeed-IcingMinSpeed) / 60


def IcingFreezeAndDamageOnImpact():
    @Name "Subroutine - Freeze and damage enemies on impact"

    #Freeze players in radius if freeze duration is set
    if IcingFreezeOnImpact > 0:
        getPlayersInRadius(eventPlayer.IcingStepPositions.last(), IcingRadius, getOppositeTeam(eventPlayer.getTeam()), LosCheck.SURFACES).setStatusEffect(eventPlayer, Status.FROZEN, IcingFreezeOnImpact)
    #Damage players in radius if damage is set
    if IcingDamageOnImpact > 0:
        eventPlayer.IcingPlayersToDamage = [player for player in getPlayersInRadius(eventPlayer.IcingStepPositions.last(), IcingRadius, getOppositeTeam(eventPlayer.getTeam()), LosCheck.SURFACES) if player in eventPlayer.IcingPlayersDamaged != true]
        #Damage players in this radius and remove them from the array, continue until array is empty
        while len(eventPlayer.IcingPlayersToDamage) > 0:
            damage(eventPlayer.IcingPlayersToDamage.last(), eventPlayer, IcingDamageOnImpact)
            eventPlayer.IcingPlayersDamaged = eventPlayer.IcingPlayersDamaged.concat(eventPlayer.IcingPlayersToDamage.last())
            eventPlayer.IcingPlayersToDamage = eventPlayer.IcingPlayersToDamage.exclude(eventPlayer.IcingPlayersToDamage.last())

