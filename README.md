# NUTM Campus Store — Sign in & Sign up (UIKit, MVVM-C)

A small iOS app for students to shop on campus. The assignment part is the **authentication flow**:
a Sign in screen and a Create account screen, built with the patterns from class.

## Run it

1. Double-click `CampusStore.xcodeproj` (Xcode 15.3 or newer).
2. Scheme **CampusStore**, any iPhone simulator → **⌘R**.
3. Sign in with the demo account **demo@nutm.edu.ng** / **Password1**, or tap **Create an account**.
4. **⌘U** runs the StoreCore unit tests (validation, auth service, both ViewModels).

No backend is needed: `FakeAuthAPI` is an in-memory server with a 0.8 s delay. Accounts you
create last until the app is stopped from Xcode; the demo account is always there.

## Project layout

```
StoreCore/                Swift package — NO UIKit. Unit-tested.
  Models.swift            User, Session, SignUpRequest, Product
  Validation.swift        Every form rule + password strength (pure functions)
  AuthAPI.swift           AuthAPI protocol, AuthError, FakeAuthAPI (the pretend server)
  AuthService.swift       Sign in / up / restore / sign out; SessionStoring protocol
  SignInViewModel.swift   Sign-in state, rules, server call, error mapping
  SignUpViewModel.swift   Sign-up state, rules, server call, error mapping
  Tests/                  ValidationTests, AuthServiceTests, SignIn/SignUpViewModelTests
AppSources/               The iOS app (UIKit, all layout in code — no storyboards)
  App/                    AppDelegate, SceneDelegate (creates the window)
  Navigation/             AppCoordinator — decides which screen shows when
  Screens/                FormScreen (shared layout), SignIn, SignUp, Home
  Components/             StoreTextField, StoreButton, banner, strength meter, checklist
  Data/                   KeychainSessionStore — the session token, encrypted
  Theme/                  Colours, fonts, spacing (light + dark mode)
Supporting/Info.plist
```

## Things to try in the demo

| Try | You'll see |
|---|---|
| Tap **Sign in** with empty fields | An error under each field; no network call |
| `demo@nutm.edu.ng` + a wrong password | Red banner “That email and password don’t match.” |
| Wrong password 5 times | “Too many attempts. Try again in 5 minutes.” |
| **Forgot password?** with an email typed | Green banner “If an account exists… we’ve sent a reset link.” |
| Sign up with a gmail address | “Use your school email (…@nutm.edu.ng).” |
| Type a password | Strength meter + checklist update live |
| Mismatched confirm password | “Passwords don’t match.” |
| Sign up with `demo@nutm.edu.ng` | “An account with this email already exists” under Email |
| Valid sign-up | Lands on Home with your name |
| Stop the app (■) and run again | Still signed in (session restored from the Keychain) |
| Home ▸ Sign out | Back to Sign in |
