chrome.runtime.onMessage.addListener(({ css, previousCss }, sender, respond) => {
  if (sender.tab?.id === undefined) return;

  const target = { tabId: sender.tab.id, frameIds: [sender.frameId] };
  chrome.scripting
    .insertCSS({ target, css, origin: "USER" })
    .then(() =>
      previousCss
        ? chrome.scripting.removeCSS({ target, css: previousCss, origin: "USER" })
        : undefined,
    )
    .then(() => respond({ ok: true }))
    .catch((error) => {
      console.error("YouTube Music theme:", error);
      respond({ ok: false, error: error.message });
    });

  return true;
});
