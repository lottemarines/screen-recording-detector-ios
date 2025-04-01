# screen-recording-detector-ios

**screen-recording-detector-ios** is a custom native module for iOS built using the Expo Modules API. It detects changes in screen recording (including mirroring) and screenshot events and sends those events to the JavaScript side. This module also implements delayed status checks to help capture the recording state even after the app is terminated and restarted.

## Features

- **Screen Recording Detection**  
  - Listens for `UIScreen.capturedDidChangeNotification` to detect when screen recording or mirroring starts/stops.
  - Re-checks the recording status when the app becomes active using `UIApplication.didBecomeActiveNotification`.
  - Schedules delayed status checks on app launch to capture changes that might be delayed (e.g., after a task kill).

- **Screenshot Detection**  
  - Detects screenshots using `UIApplication.userDidTakeScreenshotNotification`.

- **Delayed Status Checks**  
  - On app launch (OnCreate), the module sends the initial recording status and then performs delayed checks at a specified interval.

## Installation

### As a Published Yarn/NPM Package

Install via yarn or npm:

```bash
yarn add screen-recording-detector-ios
# or
npm install screen-recording-detector-ios
```

### As a Local Module

If you are managing it locally, add the following to your host app's `package.json`:

```json
"dependencies": {
  "screen-recording-detector-ios": "file:./modules/screen-recording-detector-ios"
}
```

## Expo Integration

If your module requires additional native configuration, ensure your host app's `app.json` or `app.config.js` includes the plugin configuration. For example:

```json
{
  "expo": {
    "plugins": [
      "screen-recording-detector-ios"
    ]
  }
}
```

If no additional Info.plist changes are needed, you may omit the plugin configuration.

## Usage

Import and use the module's API in your JavaScript/TypeScript code:

```ts
import { useEffect, useState } from "react";
import RNScreenshotPrevent, { enableSecureView } from "react-native-screenshot-prevent";
import { isDev, isAndroidProd } from "utils/validator";
import {
  addScreenRecordingListener,
  addScreenshotListener,
  getCapturedStatus,
} from "screen-recording-detector-ios";
import { logEvent } from "utils/firebaseHelper";
import { alertSound } from "utils/soundHelper";

const POLLING_INTERVAL = 5000;

export const useSecureScreenView = (enabled: boolean) => {
  const [isCaptured, setIsCaptured] = useState<boolean>(false);

  useEffect(() => {
    if (isDev("useSecureScreenView")) return;
    if (isAndroidProd) return RNScreenshotPrevent.enabled(enabled);

    // iOS: enable screenshot prevention and secure view
    RNScreenshotPrevent.enabled(enabled);
    if (enabled) enableSecureView();

    const recording = addScreenRecordingListener((captured) => {
      if (captured) {
        logEvent("ScreenRecording");
        setIsCaptured(true);
      }
    });

    const screenshot = addScreenshotListener(() => logEvent("ScreenShot"));

    // Poll the current captured status periodically (to handle task kill/restart scenarios)
    const pollCapturedStatus = async () => {
      try {
        const captured: boolean = await getCapturedStatus();
        console.log("Polled captured status:", captured);
        if (captured && !isCaptured) {
          logEvent("ScreenRecording_Polling");
          setIsCaptured(true);
        }
      } catch (error) {
        console.error("Error polling captured status:", error);
      }
    };

    const intervalId = setInterval(pollCapturedStatus, POLLING_INTERVAL);

    return () => {
      recording.remove();
      screenshot.remove();
      clearInterval(intervalId);
    };
  }, [enabled]);

  useEffect(() => {
    if (isCaptured) alertSound();
  }, [isCaptured]);

  return { isCaptured };
};
```

Additionally, you can directly call `getCapturedStatus()` to retrieve the current screen recording state:

```ts
async function checkStatus() {
  const status = await getCapturedStatus();
  console.log("Current captured status:", status);
}
```

## iOS Native Implementation Overview

The native (Swift) module implements:

- **OnCreate**  
  - Sends the initial screen recording status.
  - Schedules delayed checks (e.g., every 5 seconds, 3 times) to update the status.
  
- **OnStartObserving**  
  - Observes `UIScreen.capturedDidChangeNotification` for changes in screen recording/mirroring.
  - Observes `UIApplication.userDidTakeScreenshotNotification` for screenshot detection.
  - Observes `UIApplication.didBecomeActiveNotification` to re-check the status when the app comes to the foreground.

- **OnStopObserving**  
  - Removes all observers.

## License

MIT License  
(Include additional license information as needed)

---

This README serves as a starting point—adjust the details as needed for your project. If you have any questions or need further adjustments, feel free to ask!
