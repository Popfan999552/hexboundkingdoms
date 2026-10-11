extends Node
# Google test IDs only. No live credentials and no automatic SDK initialization.
signal reward_earned
signal availability_changed
const REWARDED_ID="ca-app-pub-3940256099942544/5224354917"
const INTERSTITIAL_ID="ca-app-pub-3940256099942544/1033173712"
var enabled=false
var consent_ready=false
var rewarded: RewardedAd
var interstitial: InterstitialAd
var showing=false
var completed_matches=0
var generation=0
var rewarded_request: RewardedAdLoadCallback
var interstitial_request: InterstitialAdLoadCallback
var reward_listener: OnUserEarnedRewardListener
var initialization_listener: OnInitializationCompleteListener

func supported() -> bool:
	return OS.get_name()=="Android" and Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobConsentInformation")

func set_enabled(value: bool) -> void:
	generation+=1; enabled=value and supported(); consent_ready=false
	if rewarded: rewarded.destroy(); rewarded=null
	if interstitial: interstitial.destroy(); interstitial=null
	availability_changed.emit()
	if not enabled: return
	var request=ConsentRequestParameters.new()
	# Adult/general audience candidate. Actual audience declaration must be reviewed.
	request.tag_for_under_age_of_consent=false
	var epoch=generation
	UserMessagingPlatform.consent_information.update(request,func():
		if epoch!=generation or not enabled: return
		var status=UserMessagingPlatform.consent_information.get_consent_status()
		if status==ConsentInformation.ConsentStatus.REQUIRED:
			UserMessagingPlatform.load_consent_form(func(form: ConsentForm):
				if epoch!=generation or not enabled: return
				form.show(func(error: FormError):
					if error==null: initialize_after_consent(epoch)),func(_error: FormError): pass)
		else: initialize_after_consent(epoch),func(_error: FormError): pass)

func initialize_after_consent(epoch: int) -> void:
	if epoch!=generation or not enabled: return
	var status=UserMessagingPlatform.consent_information.get_consent_status()
	if not status in [ConsentInformation.ConsentStatus.OBTAINED,ConsentInformation.ConsentStatus.NOT_REQUIRED]: return
	consent_ready=true
	var config=RequestConfiguration.new(); config.max_ad_content_rating=RequestConfiguration.MAX_AD_CONTENT_RATING_PG
	MobileAds.set_request_configuration(config)
	MobileAds.set_publisher_first_party_id_enabled(false)
	initialization_listener=OnInitializationCompleteListener.new()
	initialization_listener.on_initialization_complete=func(_status: InitializationStatus):
		if epoch==generation and enabled: load_ads()
	MobileAds.initialize(initialization_listener)

func load_ads() -> void:
	if not enabled or not consent_ready: return
	var epoch=generation
	rewarded_request=RewardedAdLoadCallback.new()
	rewarded_request.on_ad_loaded=func(ad: RewardedAd):
		if epoch!=generation or not enabled: ad.destroy(); return
		rewarded=ad; availability_changed.emit()
	rewarded_request.on_ad_failed_to_load=func(_error: LoadAdError): availability_changed.emit()
	RewardedAdLoader.new().load(REWARDED_ID,AdRequest.new(),rewarded_request)
	interstitial_request=InterstitialAdLoadCallback.new()
	interstitial_request.on_ad_loaded=func(ad: InterstitialAd):
		if epoch!=generation or not enabled: ad.destroy(); return
		interstitial=ad
	interstitial_request.on_ad_failed_to_load=func(_error: LoadAdError): pass
	InterstitialAdLoader.new().load(INTERSTITIAL_ID,AdRequest.new(),interstitial_request)

func can_reward(match_finished: bool) -> bool:
	return match_finished and enabled and consent_ready and rewarded!=null and not showing

func show_reward(match_finished: bool) -> bool:
	if not can_reward(match_finished): return false
	showing=true
	var ad=rewarded; rewarded=null
	var callback=FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content=func(): showing=false; ad.destroy(); load_ads()
	callback.on_ad_failed_to_show_full_screen_content=func(_error: AdError): showing=false; ad.destroy(); availability_changed.emit()
	ad.full_screen_content_callback=callback
	reward_listener=OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward=func(_item: RewardedItem): reward_earned.emit()
	ad.show(reward_listener); availability_changed.emit(); return true

func match_to_menu(match_finished: bool) -> void:
	if not match_finished: return
	completed_matches+=1
	# Only between matches, no more often than every third completed match.
	if completed_matches%3!=0 or not enabled or not consent_ready or interstitial==null or showing: return
	showing=true
	var ad=interstitial; interstitial=null
	var callback=FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content=func(): showing=false; ad.destroy(); load_ads()
	callback.on_ad_failed_to_show_full_screen_content=func(_error: AdError): showing=false; ad.destroy()
	ad.full_screen_content_callback=callback; ad.show()

func privacy_options() -> void:
	if not enabled or not supported(): return
	UserMessagingPlatform.show_privacy_options_form(func(_error: FormError):
		# Re-run consent gate; discard preloaded ads following preference changes.
		set_enabled(enabled))

func privacy_options_required() -> bool:
	return enabled and supported() and UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()==ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func _exit_tree() -> void:
	if rewarded: rewarded.destroy()
	if interstitial: interstitial.destroy()
