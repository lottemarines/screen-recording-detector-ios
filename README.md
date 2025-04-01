Below is a complete README in plain Markdown format specifically for the **screen-recording-detector-ios** library. You can copy and paste this into your README.md on GitHub.

```markdown
# screen-recording-detector-ios

**screen-recording-detector-ios** is a custom native module for iOS built using the Expo Modules API. It detects changes in screen recording (including mirroring) and screenshot events, and sends these events to the JavaScript side. The module also performs delayed status checks at app startup to help update the recording status even if the app is terminated and relaunched.

## Features

- **Screen Recording Detection**  
  - Listens for changes in the screen recording state using `UIScreen.capturedDidChangeNotification`.
  - Checks the screen recording status when the app becomes active using `UIApplication.didBecomeActiveNotification`.
  - Schedules delayed checks on startup to catch changes that might be delayed (e.g., after a task kill).

- **Screenshot Detection**  
  - Detects screenshot events via `UIApplication.userDidTakeScreenshotNotification`.

## Installation

### As a Published Package

Install via yarn:

```bash
yarn add screen-recording-detector-ios
```

Or using npm:

```bash
npm install screen-recording-detector-ios
```

### As a Local Module

If you manage the module locally, add the following to your host app's `package.json`:

```json
"dependencies": {
  "screen-recording-detector-ios": "file:./modules/screen-recording-detector-ios"
}
```

## Expo Integration

If your module requires additional native configuration, include it via a config plugin. For example, in your host app's `app.config.js`:

```js
module.exports = {
  expo: {
    // ...other settings...
    plugins: [
      "screen-recording-detector-ios"
    ]
  }
};
```

If no additional Info.plist or AndroidManifest.xml changes are needed, you may omit the plugin configuration.

## Usage

Import and use the module's API in your JavaScript/TypeScript code. For example:

```ts
import { addScreenRecordingListener, addScreenshotListener, getCapturedStatus } from "screen-recording-detector-ios";

// Example: Adding event listeners
const recordingListener = addScreenRecordingListener((payload) => {
  console.log("Screen recording state changed:", payload.isCaptured);
});

const screenshotListener = addScreenshotListener(() => {
  console.log("Screenshot detected.");
});

// Example: Getting the current recording status
async function checkStatus() {
  const status = await getCapturedStatus();
  console.log("Current recording status:", status);
}
```

## iOS Native Implementation Overview

The module's native (Swift) implementation includes:

- **OnCreate**:  
  - Sends the initial screen recording status at app launch.
  - Schedules delayed checks (e.g., every 5 seconds, for 3 attempts) to update the status.

- **OnStartObserving**:  
  - Observes `UIScreen.capturedDidChangeNotification` to detect changes in the recording state.
  - Observes `UIApplication.userDidTakeScreenshotNotification` for screenshot detection.
  - Observes `UIApplication.didBecomeActiveNotification` to re-check the recording state when the app returns to the foreground.

- **OnStopObserving**:  
  - Removes all observers when no longer needed.

## License

MIT License

```

Feel free to modify the text as needed for your project. This README provides a concise overview of the library, its features, installation, integration with Expo, usage examples, and an overview of the iOS native implementation.
