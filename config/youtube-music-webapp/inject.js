let appliedCss = "";

async function applyTheme() {
  const response = await fetch(`${chrome.runtime.getURL("theme.css")}?${Date.now()}`, {
    cache: "no-store",
  });
  const css = await response.text();
  if (css === appliedCss) return;

  const result = await chrome.runtime.sendMessage({ css, previousCss: appliedCss });
  if (!result?.ok) throw new Error(result?.error ?? "Theme injection failed");
  appliedCss = css;
}

async function refreshTheme() {
  try {
    await applyTheme();
  } catch (error) {
    console.error("YouTube Music theme:", error);
  }
  setTimeout(refreshTheme, 1000);
}

refreshTheme();
