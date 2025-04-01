# screen-recording-detector-ios

**screen-recording-detector-ios** is a custom native module for iOS built with the Expo Modules API. It detects changes in screen recording (including mirroring) and screenshot events, sending these events to the JavaScript side. The module also performs delayed status checks at app startup to help update the recording status even if the app is terminated and relaunched.

## Features

- **Screen Recording Detection**  
  - Listens for changes in the screen recording state via `UIScreen.capturedDidChangeNotification`.  
  - Checks the recording state when the app becomes active via `UIApplication.didBecomeActiveNotification`.  
  - Schedules delayed checks at startup to capture any delayed updates.

- **Screenshot Detection**  
  - Detects screenshot events using `UIApplication.userDidTakeScreenshotNotification`.

## Installation

### As a Published Package

```bash
yarn add screen-recording-detector-ios
```

## Usage

Import and use the module's API in your JavaScript/TypeScript code. For example:

```ts
import { addScreenRecordingListener, addScreenshotListener, getCapturedStatus } from "screen-recording-detector-ios";

// Adding event listeners
const recordingListener = addScreenRecordingListener((payload) => {
  console.log("Screen recording state changed:", payload.isCaptured);
});

const screenshotListener = addScreenshotListener(() => {
  console.log("Screenshot detected.");
});

// Getting the current screen recording status
async function checkStatus() {
  const status = await getCapturedStatus();
  console.log("Current recording status:", status);
}
```

## iOS Native Implementation Overview

The native (Swift) module does the following:

- **OnCreate**:  
  - Sends the initial screen recording state at app launch.
  - Schedules delayed checks (e.g., every 5 seconds for 3 attempts) to update the state.

- **OnStartObserving**:  
  - Observes `UIScreen.capturedDidChangeNotification` to detect changes.
  - Observes `UIApplication.userDidTakeScreenshotNotification` to detect screenshots.
  - Observes `UIApplication.didBecomeActiveNotification` to re-check the state when the app returns to the foreground.

- **OnStopObserving**:  
  - Removes all observers when the module is no longer needed.

## License

MIT License
