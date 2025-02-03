# 1. Configure

After you installed the project via SPM, you need to initialize the UIManager inside AppDelegate or SwiftUIApp.

```
OnboardingUIManager.configure(key: <#Enter your public key#>, customerUserId: UUID().uuidString,
                                      configuration: OnboardingConfiguration(
                                        primaryFont: UIFont.zodiakBlack(28),
                                        secondaryFont: .generalSansVariableBoldMedium(14),
                                        ctaFont: .generalSansVariableBoldSemibold(14)))
```

#2. Showing Onboarding

Splash Screen needs to be provided to OnboardingUI, this will make app shows some kind of loader while onboarding contents are loading. Once it's loaded, it should automatically transition from splash screen to onboarding screen.


```
                    OnboardingMainView(splashView: SplashScreen())
                        .onReceive(OnboardingUIManager.shared.eventPassthrough) { output in
                            print("OnboardingUI outputs", output)
                        }
```

Current outputs for the eventPassthrough are:

```
        case appInitialized
        case appInitializedFailed(Error)
        case onboardingStarted
        case onboardingCompleted
```

You can use these events to send analytics or show paywall.

#3. Configuration

WIP: Currently we need to pass the fonts that we want to show during the onboarding. To do that OnboardingConfiguration needs to be passed during configuring OnboardingUIManager.

```
OnboardingConfiguration(
                                        primaryFont: UIFont.zodiakBlack(28),
                                        secondaryFont: .generalSansVariableBoldMedium(14),
                                        ctaFont: .generalSansVariableBoldSemibold(14))
```
## This will be updated




