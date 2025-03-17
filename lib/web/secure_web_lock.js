console.log("Secure Web Lock script loaded!");

// Ensure window.isLocked is initialized
window.isLocked = false;
console.log("Initial lock state:", window.isLocked);

// Function for escape attempts
window.handleLockEscape = function () {
    console.log("ESCAPE ATTEMPT: User tried to bypass lock screen!");

    // Call the callback provided by Dart
    if (window._secureLockEscapeCallback) {
        window._secureLockEscapeCallback();
    } else {
        console.log("No escape callback defined");
    }
};

// Function to set the lock state - called from Dart
window.setLockState = function (isLocked) {
    console.log("%c Lock state changed to: " + isLocked,
        isLocked ? "background: red; color: white; font-size: 14px;" :
            "background: green; color: white; font-size: 14px;");
    window.isLocked = isLocked;
};

// Prevent page reload and log out the user
window.addEventListener('beforeunload', function (event) {
    console.log("beforeunload event triggered, lock state:", window.isLocked);
    if (window.isLocked) {
        console.log("LOCKED: Preventing page unload");
        handleLockEscape();
        event.preventDefault();
        event.returnValue = 'Your session is locked.';
        return event.returnValue;
    }
});

// Prevent refresh with F5 or Ctrl+R
window.addEventListener('keydown', function (event) {
    if (window.isLocked && (event.key === 'F5' || (event.ctrlKey && event.key === 'r'))) {
        console.log("LOCKED: Refresh key detected, preventing and handling escape");
        handleLockEscape();
        event.preventDefault();
        event.stopPropagation();
        return false;
    }
});

// Prevent navigation clicks
window.addEventListener('click', function (event) {
    if (window.isLocked && event.target.tagName === 'A') {
        console.log("LOCKED: Navigation attempt detected, preventing and handling escape");
        handleLockEscape();
        event.preventDefault();
        event.stopPropagation();
    }
});

// Prevent back navigation
window.addEventListener('popstate', function (event) {
    if (window.isLocked) {
        console.log("LOCKED: Back navigation detected, preventing and handling escape");
        handleLockEscape();
        history.pushState(null, '', location.href);
    }
});

// Prevent context menu to avoid right-click refresh
window.addEventListener('contextmenu', function (event) {
    if (window.isLocked) {
        console.log("LOCKED: Context menu prevented");
        event.preventDefault();
    }
});

console.log("All lock screen protection event listeners registered");