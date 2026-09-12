(() => {
  const knob = document.getElementById('knob');
  const dish = document.getElementById('knobDish');
  const cursor = document.getElementById('knobCursor');
  const ticksContainer = document.getElementById('demoRingTicks');
  const demo = document.getElementById('demo');
  const label = document.getElementById('demoLabel');
  const timer = document.getElementById('demoTimer');

  if (!knob) return;

  const IDLE_WAIT = 2000;
  const JIGGLE_INTERVAL = 3000;
  const BLINK_DURATION = 550; // ~3 blinks at 0.16s + settle
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const TICK_COUNT = 48;
  const TICK_RADIUS = 84;

  let on = false;
  let phase = 'off'; // off | idle | growing | blinking
  let phaseStart = 0;
  let raf = null;
  let blinkTimeout = null;

  const fmt = (ms) => `0:${Math.max(0, Math.ceil(ms / 1000)).toString().padStart(2, '0')}`;

  // 48 discrete dash marks around the ring, matching the app's dash:[4,5] stroke —
  // trimmed and revealed one by one as progress grows, rather than a smooth arc.
  const ticks = [];
  function buildTicks() {
    const frag = document.createDocumentFragment();
    for (let i = 0; i < TICK_COUNT; i++) {
      const deg = (360 / TICK_COUNT) * i;
      const el = document.createElement('span');
      el.className = 'demo-ring-tick';
      el.style.transform = `rotate(${deg}deg) translateY(-${TICK_RADIUS}px)`;
      frag.appendChild(el);
      ticks.push(el);
    }
    ticksContainer.appendChild(frag);
  }

  // Off (no countdown): every dash visible, muted — the decorative fallback ring.
  function setTicksDecorative(isDecorative) {
    ticks.forEach((t) => t.classList.toggle('decorative', isDecorative));
    if (isDecorative) setTickProgress(0);
  }

  // Counting down (idle or active): dashes reveal one by one up to `frac`, always in
  // gray — matching the real app's trim(from: 0, to: elapsedProgress). Green is reserved
  // for the blink at the exact moment a jiggle fires, not the countdown itself.
  function setTickProgress(frac) {
    const filledCount = Math.round(Math.max(0, Math.min(1, frac)) * TICK_COUNT);
    for (let i = 0; i < TICK_COUNT; i++) {
      ticks[i].classList.toggle('filled', i < filledCount);
    }
  }

  function tickIdleGrowth(ts) {
    if (phase !== 'idle') return;
    const elapsed = ts - phaseStart;
    timer.textContent = fmt(IDLE_WAIT - elapsed);
    setTickProgress(elapsed / IDLE_WAIT);
    if (elapsed < IDLE_WAIT) {
      raf = requestAnimationFrame(tickIdleGrowth);
    } else {
      enterActive();
    }
  }

  function tickActiveGrowth(ts) {
    if (phase !== 'growing') return;
    const elapsed = ts - phaseStart;
    timer.textContent = fmt(JIGGLE_INTERVAL - elapsed);
    setTickProgress(elapsed / JIGGLE_INTERVAL);
    if (elapsed < JIGGLE_INTERVAL) {
      raf = requestAnimationFrame(tickActiveGrowth);
    } else {
      doBlink();
    }
  }

  // The ring has just completed a full countdown — a jiggle fires right now. Blink the
  // icon and every filled dash mint 3 times, pulse the dish, then reset and count again.
  function doBlink() {
    phase = 'blinking';
    setTickProgress(1);
    timer.textContent = fmt(0);

    dish.classList.add('pulsing');
    ticksContainer.classList.add('flash');
    cursor.classList.add('flash');

    clearTimeout(blinkTimeout);
    blinkTimeout = setTimeout(() => {
      dish.classList.remove('pulsing');
      ticksContainer.classList.remove('flash');
      cursor.classList.remove('flash');
      if (phase !== 'blinking' || !on) return;
      phase = 'growing';
      setTickProgress(0);
      phaseStart = performance.now();
      if (!reduced) {
        raf = requestAnimationFrame(tickActiveGrowth);
      } else {
        timer.textContent = fmt(JIGGLE_INTERVAL);
        blinkTimeout = setTimeout(doBlink, JIGGLE_INTERVAL);
      }
    }, BLINK_DURATION);
  }

  function enterActive() {
    demo.classList.remove('idle');
    demo.classList.add('active');
    label.textContent = 'Awake · until next jiggle';
    doBlink();
  }

  function start() {
    on = true;
    phase = 'idle';
    demo.classList.add('on', 'idle');
    knob.setAttribute('aria-pressed', 'true');
    label.textContent = 'Waiting · until jiggle';
    setTicksDecorative(false);
    timer.textContent = fmt(IDLE_WAIT);

    phaseStart = performance.now();
    if (!reduced) {
      raf = requestAnimationFrame(tickIdleGrowth);
    } else {
      blinkTimeout = setTimeout(enterActive, IDLE_WAIT);
    }
  }

  function stop() {
    on = false;
    phase = 'off';
    demo.classList.remove('on', 'idle', 'active');
    knob.setAttribute('aria-pressed', 'false');
    label.textContent = 'Off · Click to start';
    setTicksDecorative(true);
    dish.classList.remove('pulsing');
    ticksContainer.classList.remove('flash');
    cursor.classList.remove('flash');
    clearTimeout(blinkTimeout);
    if (raf) cancelAnimationFrame(raf);
  }

  buildTicks();
  setTicksDecorative(true);

  knob.addEventListener('click', () => (on ? stop() : start()));

  const pills = document.getElementById('demoPills');
  if (pills) {
    pills.addEventListener('click', (e) => {
      const pill = e.target.closest('.demo-pill');
      if (!pill) return;
      pills.querySelectorAll('.demo-pill').forEach((p) => p.classList.remove('active'));
      pill.classList.add('active');
    });
  }
})();

// Download button. Its href already points at the latest release's JigTail.dmg,
// so this only adds the version and size under it, and falls back to the
// releases page when there is no DMG to download yet (or the API is unreachable).
(() => {
  const btn = document.getElementById('downloadBtn');
  const meta = document.getElementById('releaseMeta');
  if (!btn || !meta) return;

  const REPO = 'pcampina/jigtail';
  const ASSET = 'JigTail.dmg';

  // iOS Safari's UA says "like Mac OS X" and iPadOS in desktop mode reports
  // "Macintosh", so rule both out before trusting the platform string.
  const isMac = (() => {
    if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) return false;
    if (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1) return false;
    const platform = navigator.userAgentData && navigator.userAgentData.platform;
    if (platform) return /mac/i.test(platform);
    return /Mac OS X|Macintosh/i.test(navigator.userAgent);
  })();

  if (!isMac) meta.textContent = 'JigTail runs on macOS — open this page on your Mac to download';

  fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
    headers: { Accept: 'application/vnd.github+json' },
  })
    .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`HTTP ${res.status}`))))
    .then((release) => {
      const asset = (release.assets || []).find((a) => a.name === ASSET);
      if (!asset) throw new Error(`No ${ASSET} in ${release.tag_name}`);
      if (isMac) {
        const mb = (asset.size / (1024 * 1024)).toFixed(1);
        meta.textContent = `${release.tag_name} · ${mb} MB · macOS 13+ · Apple Silicon`;
      }
    })
    .catch(() => {
      btn.href = `https://github.com/${REPO}/releases`;
    });
})();
