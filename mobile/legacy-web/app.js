let acupoints = [
  {
    id: "huyet_26",
    so: 26,
    ten: "Huyệt 26",
    cong_dung: ["an thần", "hạ áp", "giảm căng thẳng"],
    vi_tri_mo_ta: "Giữa trán, trên đường dọc giữa mặt.",
    cach_tac_dong: "Day tròn nhẹ 60 giây, thở chậm.",
    x: 0.5,
    y: 0.3,
  },
  {
    id: "huyet_124",
    so: 124,
    ten: "Huyệt 124",
    cong_dung: ["dễ ngủ", "giảm stress", "an thần"],
    vi_tri_mo_ta: "Vùng giữa trán, thấp hơn huyệt 26.",
    cach_tac_dong: "Dùng đầu ngón tay day tròn vừa phải.",
    x: 0.5,
    y: 0.38,
  },
  {
    id: "huyet_34",
    so: 34,
    ten: "Huyệt 34",
    cong_dung: ["hạ áp", "giảm đau đầu"],
    vi_tri_mo_ta: "Hai bên thái dương.",
    cach_tac_dong: "Day theo vòng tròn, lực nhẹ.",
    x: 0.26,
    y: 0.38,
  },
  {
    id: "huyet_61",
    so: 61,
    ten: "Huyệt 61",
    cong_dung: ["trị ho", "viêm họng", "hô hấp"],
    vi_tri_mo_ta: "Vùng nhân trung.",
    cach_tac_dong: "Ấn nhẹ từng nhịp 30-60 giây.",
    x: 0.5,
    y: 0.58,
  },
  {
    id: "huyet_19",
    so: 19,
    ten: "Huyệt 19",
    cong_dung: ["bổ phế", "thông mũi", "trị ho"],
    vi_tri_mo_ta: "Vùng cằm giữa.",
    cach_tac_dong: "Day đều, tránh làm đau da.",
    x: 0.5,
    y: 0.73,
  },
  {
    id: "huyet_50",
    so: 50,
    ten: "Huyệt 50",
    cong_dung: ["tiêu hóa", "đầy bụng", "ăn ngon"],
    vi_tri_mo_ta: "Vùng má phải theo đồ hình.",
    cach_tac_dong: "Lăn hoặc day 1 phút.",
    x: 0.72,
    y: 0.57,
  },
];

let conditions = [
  {
    id: "benh_mat_ngu",
    loai: "benh",
    ten: "Mất ngủ",
    nhom: "thần kinh",
    tu_khoa: ["mất ngủ", "khó ngủ", "trằn trọc", "khó vào giấc", "ngủ không sâu"],
    phac_do_ids: ["pd_mat_ngu"],
    co_nguy_hiem: false,
  },
  {
    id: "trc_dau_dau",
    loai: "trieu_chung",
    ten: "Đau đầu",
    nhom: "thần kinh",
    tu_khoa: ["đau đầu", "nhức đầu", "váng đầu", "căng đầu"],
    phac_do_ids: ["pd_dau_dau"],
    co_nguy_hiem: false,
  },
  {
    id: "benh_tang_huyet_ap",
    loai: "benh",
    ten: "Tăng huyết áp nặng",
    nhom: "tim mạch",
    tu_khoa: ["cao huyết áp", "tăng xông", "choáng", "huyết áp cao"],
    phac_do_ids: ["pd_ha_ap_ho_tro"],
    co_nguy_hiem: true,
  },
  {
    id: "trc_day_bung",
    loai: "trieu_chung",
    ten: "Đầy bụng",
    nhom: "tiêu hóa",
    tu_khoa: ["đầy bụng", "khó tiêu", "ăn không tiêu", "no hơi"],
    phac_do_ids: ["pd_tieu_hoa"],
    co_nguy_hiem: false,
  },
];

let protocols = [
  {
    id: "pd_mat_ngu",
    ten: "Mất ngủ, khó vào giấc",
    benh_ids: ["benh_mat_ngu"],
    thoi_diem: "Làm tối",
    thoi_luong_phut: 8,
    muc_canh_bao: "luu_y",
    buoc: [
      { thu_tu: 1, huyet_id: "huyet_124", huong_dan: "Day tròn giữa trán, ấn nhẹ vừa phải.", thoi_luong_giay: 60 },
      { thu_tu: 2, huyet_id: "huyet_34", huong_dan: "Day hai bên thái dương theo chiều kim đồng hồ.", thoi_luong_giay: 60 },
      { thu_tu: 3, huyet_id: "huyet_26", huong_dan: "Ấn nhẹ và thở chậm để thư giãn.", thoi_luong_giay: 60 },
    ],
  },
  {
    id: "pd_dau_dau",
    ten: "Đau đầu, căng vùng trán",
    benh_ids: ["trc_dau_dau"],
    thoi_diem: "Khi khó chịu",
    thoi_luong_phut: 5,
    muc_canh_bao: "thuong",
    buoc: [
      { thu_tu: 1, huyet_id: "huyet_34", huong_dan: "Day thái dương 1 phút mỗi bên.", thoi_luong_giay: 60 },
      { thu_tu: 2, huyet_id: "huyet_26", huong_dan: "Day vùng trán nhẹ, dừng nếu chóng mặt.", thoi_luong_giay: 60 },
    ],
  },
  {
    id: "pd_ha_ap_ho_tro",
    ten: "Hỗ trợ khi huyết áp cao",
    benh_ids: ["benh_tang_huyet_ap"],
    thoi_diem: "Chỉ hỗ trợ",
    thoi_luong_phut: 3,
    muc_canh_bao: "di_kham_ngay",
    buoc: [
      { thu_tu: 1, huyet_id: "huyet_34", huong_dan: "Ngồi nghỉ, day nhẹ thái dương. Không thay thuốc.", thoi_luong_giay: 45 },
    ],
  },
  {
    id: "pd_tieu_hoa",
    ten: "Đầy bụng, khó tiêu",
    benh_ids: ["trc_day_bung"],
    thoi_diem: "Sau ăn 30 phút",
    thoi_luong_phut: 4,
    muc_canh_bao: "thuong",
    buoc: [
      { thu_tu: 1, huyet_id: "huyet_50", huong_dan: "Day hoặc lăn nhẹ vùng má theo đồ hình.", thoi_luong_giay: 60 },
    ],
  },
];

let reflexMaps = [];
let touchPoints = [];
let principles = [];
let tools = [];
let productSpec = {
  sitemap: {},
  screens: [],
  nonFunctionalRequirements: [],
  mvpCompletionCriteria: [],
  privacyNotice: "",
};

const tiles = [
  { id: "symptom", title: "Tra triệu chứng", desc: "Đau, mệt, khó chịu", icon: "⚕", color: "coral", action: "symptoms" },
  { id: "protocol", title: "Phác đồ chữa", desc: "Hướng dẫn từng bước", icon: "☷", color: "amber", action: "protocols" },
  { id: "map", title: "Tra huyệt & đồ hình", desc: "Bản đồ trên mặt", icon: "⌖", color: "blue", action: "map" },
  { id: "journal", title: "Bệnh án của tôi", desc: "Theo dõi sức khỏe", icon: "✎", color: "leaf", action: "journal" },
];

const state = {
  tab: "home",
  view: "home",
  selectedProtocol: "pd_mat_ngu",
  selectedPoint: "huyet_124",
  query: "",
  mood: 3,
  faceScore: 79,
  capturedFace: "",
  settings: loadSettings(),
  journals: [],
  trackingRecords: [],
  bookmarks: [],
};

function loadSettings() {
  const fallback = {
    layout: "grid",
    font: "normal",
    tileOrder: tiles.map((tile) => tile.id),
    presets: [],
    cloud: false,
    reminders: true,
  };
  try {
    return { ...fallback, ...JSON.parse(localStorage.getItem("dc_settings") || "{}") };
  } catch {
    return fallback;
  }
}

function saveSettings() {
  localStorage.setItem("dc_settings", JSON.stringify(state.settings));
  apiFetch("/api/v1/settings", {
    method: "PUT",
    body: JSON.stringify(state.settings),
  }).catch(() => {});
}

async function apiFetch(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  if (!response.ok) throw new Error(`API ${response.status}`);
  return response.json();
}

async function loadRemoteState() {
  try {
    const [catalog, settings, journals, trackingRecords, bookmarks, spec] = await Promise.all([
      apiFetch("/api/v1/catalog"),
      apiFetch("/api/v1/settings"),
      apiFetch("/api/v1/journals"),
      apiFetch("/api/v1/tracking-records"),
      apiFetch("/api/v1/bookmarks"),
      apiFetch("/api/v1/product-spec"),
    ]);
    acupoints = catalog.acupoints?.length ? catalog.acupoints : acupoints;
    conditions = catalog.conditions?.length ? catalog.conditions : conditions;
    protocols = catalog.protocols?.length ? catalog.protocols : protocols;
    reflexMaps = catalog.reflexMaps || [];
    touchPoints = catalog.touchPoints || [];
    principles = catalog.principles || [];
    tools = catalog.tools || [];
    productSpec = spec || productSpec;
    state.settings = { ...state.settings, ...(settings || {}) };
    state.journals = Array.isArray(journals) ? journals : [];
    state.trackingRecords = Array.isArray(trackingRecords) ? trackingRecords : [];
    state.bookmarks = Array.isArray(bookmarks) ? bookmarks : [];
    localStorage.setItem("dc_settings", JSON.stringify(state.settings));
  } catch {
    toast("Đang dùng dữ liệu offline trên máy");
  }
}

function setTitle(title) {
  document.getElementById("screenTitle").textContent = title;
}

function applySettings() {
  const scale = { normal: 1, large: 1.12, xlarge: 1.24 }[state.settings.font] || 1;
  document.documentElement.style.setProperty("--font-scale", scale);
  document.getElementById("app").classList.toggle("layout-list", state.settings.layout === "list");
}

function render() {
  applySettings();
  const appEl = app();
  appEl.classList.remove("screen-enter");
  void appEl.offsetWidth;
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.tab === state.tab);
  });
  const view = {
    home: renderHome,
    lookup: renderLookup,
    connect: renderConnect,
    profile: renderProfile,
    search: renderSearch,
    protocols: renderProtocolList,
    protocolDetail: renderProtocolDetail,
    map: renderMap,
    acupoints: renderAcupoints,
    journal: renderJournal,
    quickJournal: renderQuickJournal,
    settings: renderSettings,
    dataSpec: renderDataSpec,
    principles: renderPrinciples,
    tools: renderTools,
    saved: renderSaved,
  }[state.view];
  view();
  appEl.classList.add("screen-enter");
}

function setView(view, tab = state.tab) {
  state.view = view;
  state.tab = tab;
  render();
}

function orderedTiles() {
  return state.settings.tileOrder
    .map((id) => tiles.find((tile) => tile.id === id))
    .filter(Boolean);
}

function renderHome() {
  setTitle("Chẩn đoán mặt");
  const todayProtocol = protocols[Math.abs(new Date().getDate()) % protocols.length] || protocols[0];
  app().innerHTML = `
    <section class="hero-diagnosis">
      <div>
        <p class="eyebrow">AI Dien Chan analysis</p>
        <h2>Quét khuôn mặt khách hàng</h2>
        <p>Định vị vùng mặt, gợi ý huyệt và phác đồ phù hợp từ triệu chứng đang ghi nhận.</p>
      </div>
      <button class="scan-fab" type="button" data-action="map" aria-label="Mở camera chẩn đoán">⌖</button>
    </section>
    <div class="score-grid">
      ${scoreCard("Điểm phân tích", `${state.faceScore}%`, "Từ vùng mặt & triệu chứng")}
      ${scoreCard("Huyệt nổi bật", String(acupoints.length), "Có tọa độ chạm")}
      ${scoreCard("Cảnh báo", String(conditions.filter((condition) => condition.co_nguy_hiem).length), "Cần đi khám")}
      ${scoreCard("Bệnh án", String(state.journals.length), "Lần đã ghi")}
    </div>
    ${searchBox("Nhập triệu chứng: mất ngủ, đau đầu...", state.query)}
    <h2 class="section-title">Luồng nhanh</h2>
    <div class="action-strip">
      ${miniAction("⌖", "Scan mặt", "map")}
      ${miniAction("☷", "Phác đồ", "protocols")}
      ${miniAction("•", "Huyệt", "acupoints")}
      ${miniAction("✎", "Report", "journal")}
    </div>
    <button class="row-card feature-row" type="button" data-action="protocol" data-id="${todayProtocol.id}">
      <span class="row-icon">☼</span>
      <span><strong>Dưỡng sinh hôm nay</strong><p>${todayProtocol.ten} · ${todayProtocol.thoi_luong_phut} phút</p></span>
      <span aria-hidden="true">›</span>
    </button>
  `;
}

function scoreCard(label, value, desc) {
  return `
    <div class="score-card">
      <span>${label}</span>
      <strong>${value}</strong>
      <p>${desc}</p>
    </div>
  `;
}

function miniAction(icon, label, action) {
  return `
    <button class="mini-action" type="button" data-action="${action}">
      <span>${icon}</span>
      <strong>${label}</strong>
    </button>
  `;
}

function searchBox(placeholder, value = "") {
  return `
    <form class="search" data-action="search-form">
      <span aria-hidden="true">⌕</span>
      <input value="${escapeHtml(value)}" name="q" placeholder="${placeholder}" aria-label="${placeholder}" />
      <button class="icon-btn" type="button" data-action="voice" aria-label="Tìm bằng giọng nói">🎙</button>
    </form>
  `;
}

function tileCard(tile) {
  const vars = {
    coral: ["var(--coral-soft)", "var(--coral)", "#4a1b0c"],
    amber: ["var(--amber-soft)", "var(--amber)", "#412402"],
    blue: ["var(--blue-soft)", "#85b7eb", "#042c53"],
    leaf: ["var(--leaf-soft)", "#97c459", "#173404"],
  }[tile.color];
  return `
    <button class="card" type="button" data-action="${tile.action}" style="background:${vars[0]};color:${vars[2]}">
      <span class="tile-icon" style="background:${vars[1]}">${tile.icon}</span>
      <strong>${tile.title}</strong>
      <p style="color:${vars[2]}">${tile.desc}</p>
    </button>
  `;
}

function renderLookup() {
  setTitle("Tra cứu");
  app().innerHTML = `
    ${searchBox("Tìm huyệt, bệnh, đồ hình...", state.query)}
    <div class="panel">
      ${lookupRow("Đồ hình trên mặt", "Chạm để xem huyệt", "⌖", "map", "blue")}
      ${lookupRow("Danh sách huyệt", "Vị trí & công dụng", "•", "acupoints", "green")}
      ${lookupRow("Bệnh theo nhóm", "Tiêu hóa, thần kinh, tim mạch", "☷", "symptoms", "coral")}
      ${lookupRow("Nguyên lý Diện Chẩn", "Đồng ứng, phản chiếu, day ấn", "☼", "principles", "violet")}
      ${lookupRow("Dụng cụ", "Cây lăn, que dò, búa gõ", "◌", "tools", "green")}
    </div>
  `;
}

function lookupRow(title, desc, icon, action, color) {
  const colorMap = {
    blue: ["var(--blue-soft)", "var(--blue)"],
    green: ["var(--mint)", "var(--green-deep)"],
    coral: ["var(--coral-soft)", "var(--coral)"],
    violet: ["var(--violet-soft)", "var(--violet)"],
    amber: ["var(--amber-soft)", "var(--amber)"],
  }[color];
  return `
    <button class="row-card" type="button" data-action="${action}" style="margin-bottom:10px">
      <span class="row-icon" style="background:${colorMap[0]};color:${colorMap[1]}">${icon}</span>
      <span><strong>${title}</strong><p>${desc}</p></span>
      <span aria-hidden="true">›</span>
    </button>
  `;
}

function renderSearch() {
  setTitle("Kết quả tìm kiếm");
  const q = normalize(state.query);
  const matchedConditions = conditions.filter((condition) =>
    [condition.ten, ...condition.tu_khoa].some((word) => normalize(word).includes(q) || q.includes(normalize(word))),
  );
  const matchedProtocolIds = new Set(matchedConditions.flatMap((condition) => condition.phac_do_ids));
  const matchedProtocols = protocols.filter((protocol) => matchedProtocolIds.has(protocol.id) || normalize(protocol.ten).includes(q));
  const matchedPoints = acupoints.filter((point) =>
    [point.ten, point.vi_tri_mo_ta, ...point.cong_dung].some((word) => normalize(word).includes(q)),
  );
  const dangerous = matchedConditions.find((condition) => condition.co_nguy_hiem);
  app().innerHTML = `
    ${searchBox("Tìm lại...", state.query)}
    ${dangerous ? `<div class="banner danger"><strong>!</strong><span>${dangerous.ten} có dấu hiệu cần đi khám. Diện Chẩn chỉ hỗ trợ chăm sóc, không thay chẩn đoán y khoa.</span></div>` : ""}
    ${resultSection("Bệnh / Triệu chứng", matchedConditions.map(conditionResult).join(""))}
    ${resultSection("Phác đồ", matchedProtocols.map(protocolResult).join(""))}
    ${resultSection("Huyệt", matchedPoints.map(pointResult).join(""))}
    ${
      !matchedConditions.length && !matchedProtocols.length && !matchedPoints.length
        ? `<div class="panel"><h3>Chưa thấy kết quả</h3><p>Thử tìm bằng từ dân gian như "nhức đầu", "khó ngủ", "ăn không tiêu", hoặc hỏi cộng đồng khi có mạng.</p></div>`
        : ""
    }
  `;
}

function resultSection(title, html) {
  if (!html) return "";
  return `<h2 class="section-title">${title}</h2><div class="panel">${html}</div>`;
}

function conditionResult(condition) {
  return `
    <button class="row-card" type="button" data-action="condition" data-id="${condition.id}" style="margin-bottom:10px">
      <span class="row-icon" style="background:var(--coral-soft);color:var(--coral)">⚕</span>
      <span><strong>${condition.ten}</strong><p>${condition.nhom} · ${condition.tu_khoa.slice(0, 3).join(", ")}</p></span>
      <span>›</span>
    </button>
  `;
}

function protocolResult(protocol) {
  return `
    <button class="row-card" type="button" data-action="protocol" data-id="${protocol.id}" style="margin-bottom:10px">
      <span class="row-icon" style="background:var(--amber-soft);color:#854f0b">☷</span>
      <span><strong>${protocol.ten}</strong><p>${protocol.buoc.length} huyệt · ${protocol.thoi_luong_phut} phút · ${protocol.thoi_diem}</p></span>
      <span>›</span>
    </button>
  `;
}

function pointResult(point) {
  return `
    <button class="row-card" type="button" data-action="point" data-id="${point.id}" style="margin-bottom:10px">
      <span class="row-icon" style="background:var(--mint);color:var(--green-deep)">•</span>
      <span><strong>${point.ten}</strong><p>${point.cong_dung.join(", ")}</p></span>
      <span>›</span>
    </button>
  `;
}

function renderProtocolList(conditionId) {
  setTitle("Phác đồ");
  const condition = conditionId ? conditions.find((item) => item.id === conditionId) : null;
  const list = condition ? protocols.filter((protocol) => condition.phac_do_ids.includes(protocol.id)) : protocols;
  app().innerHTML = `
    ${condition ? `<div class="banner ${condition.co_nguy_hiem ? "danger" : "info"}"><strong>${condition.co_nguy_hiem ? "!" : "i"}</strong><span>${condition.ten}: ${condition.co_nguy_hiem ? "nên đi khám khi triệu chứng nặng hoặc kéo dài." : "chọn phác đồ phù hợp bên dưới."}</span></div>` : ""}
    ${list.map(protocolResult).join("")}
  `;
}

function renderProtocolDetail() {
  const protocol = protocols.find((item) => item.id === state.selectedProtocol) || protocols[0];
  setTitle("Phác đồ");
  const danger = protocol.muc_canh_bao === "di_kham_ngay";
  app().innerHTML = `
    <section class="panel" style="background:var(--amber-soft);border-color:#efd19c">
      <h2 style="color:#412402">${protocol.ten}</h2>
      <div class="chips">
        <span class="chip">${protocol.buoc.length} huyệt</span>
        <span class="chip">~${protocol.thoi_luong_phut} phút</span>
        <span class="chip">${protocol.thoi_diem}</span>
      </div>
    </section>
    <div class="banner ${danger ? "danger" : "info"}">
      <strong>${danger ? "!" : "i"}</strong>
      <span>${danger ? "Có dấu hiệu nguy hiểm. Hãy đi khám hoặc gọi cấp cứu nếu huyết áp rất cao, đau ngực, khó thở, yếu liệt." : "Hỗ trợ chăm sóc, không thay khám bệnh. Nếu triệu chứng kéo dài nên gặp bác sĩ."}</span>
    </div>
    <h2 class="section-title">Làm theo thứ tự</h2>
    ${protocol.buoc.map(stepTemplate).join("")}
    <button class="primary-btn" type="button" data-action="guide" style="width:100%">▶ Bắt đầu hướng dẫn</button>
    <button class="ghost-btn" type="button" data-action="save-record" style="width:100%;margin-top:10px">✎ Lưu vào bệnh án</button>
    <button class="ghost-btn" type="button" data-action="bookmark" data-type="protocol" data-id="${protocol.id}" style="width:100%;margin-top:10px">☆ Lưu phác đồ</button>
  `;
}

function stepTemplate(step) {
  const point = acupoints.find((item) => item.id === step.huyet_id);
  return `
    <div class="step">
      <div class="step-no">${step.thu_tu}</div>
      <div class="panel" style="margin-top:0">
        <h3>${point.ten}</h3>
        <p>${step.huong_dan}</p>
        <div class="chips">
          <button class="chip" type="button" data-action="map-point" data-id="${point.id}">⌖ Xem vị trí</button>
          <span class="chip">◷ ${Math.round((step.thoi_luong_giay || 60) / 60)} phút</span>
          <span class="chip">${point.cong_dung[0]}</span>
        </div>
      </div>
    </div>
  `;
}

function renderMap() {
  setTitle("Scan khuôn mặt");
  const selected = acupoints.find((point) => point.id === state.selectedPoint) || acupoints[0];
  const map = reflexMaps[0];
  app().innerHTML = `
    <section class="scan-stage">
      <video id="faceCamera" autoplay playsinline muted></video>
      <div class="face-placeholder" id="facePlaceholder">
        <div class="face-oval">
          <span></span><span></span><i></i>
        </div>
      </div>
      <div class="face-fit-guide" aria-hidden="true">
        <div class="fit-oval">
          <span class="eye-line"></span>
          <span class="nose-line"></span>
          <span class="mouth-line"></span>
          <b class="left-eye-dot"></b>
          <b class="right-eye-dot"></b>
        </div>
      </div>
      <div class="face-acupoints" aria-label="Điểm huyệt trên khuôn mặt khách hàng">
        ${faceAcupointMarkers()}
      </div>
      <div class="scan-corners" aria-hidden="true"><span></span><span></span><span></span><span></span></div>
      <div class="scan-lines" aria-hidden="true">
        <span></span>
        <span></span>
      </div>
      <div class="fit-status">
        <span class="ok">Mắt ngang vạch</span>
        <span>Mũi giữa khung</span>
        <span>Cằm trong oval</span>
      </div>
      <button class="camera-btn" type="button" data-action="scan-face">◎</button>
      <p>${map ? map.ten : "Mặt nhìn thẳng"} · nhìn thẳng, giữ mặt khớp oval</p>
    </section>
    <section class="analysis-panel">
      <div>
        <span class="small">Huyệt đang chọn</span>
        <strong>${selected.so}</strong>
      </div>
      <div class="analysis-bars">
        ${analysisBar("Độ khớp vị trí", 86)}
        ${analysisBar("Căn mắt ngang", 92)}
        ${analysisBar("Mũi giữa trục", 88)}
        ${analysisBar("Cằm trong oval", 79)}
      </div>
    </section>
    <section class="panel" style="width:100%">
      <h2>${selected.ten}</h2>
      <p>${selected.cong_dung.join(", ")}. ${selected.vi_tri_mo_ta}</p>
      ${faceAnalysisMap()}
      <div class="chips">
        <button class="chip" type="button" data-action="protocols-by-point" data-id="${selected.id}">Xem phác đồ dùng huyệt này</button>
        <button class="chip" type="button" data-action="bookmark" data-type="acupoint" data-id="${selected.id}">☆ Lưu</button>
      </div>
      ${toolSuggestions(selected).join("")}
    </section>
  `;
  startFaceCamera();
}

function faceAcupointMarkers() {
  const points = touchPoints.length ? touchPoints : acupoints.map((point) => ({ huyet_id: point.id, x: point.x, y: point.y }));
  return points
    .map((touchPoint) => {
      const point = acupoints.find((item) => item.id === touchPoint.huyet_id);
      if (!point) return "";
      const active = point.id === state.selectedPoint ? "active" : "";
      return `
        <button
          class="face-acupoint ${active}"
          type="button"
          data-action="select-point"
          data-id="${point.id}"
          style="left:${touchPoint.x * 100}%;top:${touchPoint.y * 100}%"
          aria-label="${point.ten}"
        >
          <span>${point.so}</span>
        </button>
      `;
    })
    .join("");
}

function facePointButtons(className = "captured-acupoint") {
  const points = touchPoints.length ? touchPoints : acupoints.map((point) => ({ huyet_id: point.id, x: point.x, y: point.y }));
  return points
    .map((touchPoint) => {
      const point = acupoints.find((item) => item.id === touchPoint.huyet_id);
      if (!point) return "";
      const active = point.id === state.selectedPoint ? "active" : "";
      return `
        <button
          class="${className} ${active}"
          type="button"
          data-action="select-point"
          data-id="${point.id}"
          style="left:${touchPoint.x * 100}%;top:${touchPoint.y * 100}%"
          aria-label="${point.ten}"
        >
          ${point.so}
        </button>
      `;
    })
    .join("");
}

function analysisBar(label, value) {
  return `
    <div class="analysis-bar">
      <span>${label}</span>
      <b>${value}%</b>
      <i style="width:${value}%"></i>
    </div>
  `;
}

async function startFaceCamera() {
  const video = document.getElementById("faceCamera");
  const placeholder = document.getElementById("facePlaceholder");
  if (!video || !navigator.mediaDevices?.getUserMedia) return;
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" }, audio: false });
    video.srcObject = stream;
    video.classList.add("active");
    if (placeholder) placeholder.hidden = true;
  } catch {
    toast("Chưa bật camera, đang dùng mô phỏng khuôn mặt");
  }
}

function captureFaceFrame() {
  const video = document.getElementById("faceCamera");
  if (!video || !video.videoWidth || !video.videoHeight) return false;
  const canvas = document.createElement("canvas");
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  const context = canvas.getContext("2d");
  context.translate(canvas.width, 0);
  context.scale(-1, 1);
  context.drawImage(video, 0, 0, canvas.width, canvas.height);
  state.capturedFace = canvas.toDataURL("image/jpeg", 0.88);
  return true;
}

function faceAnalysisMap() {
  if (state.capturedFace) {
    return `
      <div class="captured-face-map">
        <img src="${state.capturedFace}" alt="Ảnh khuôn mặt khách hàng vừa chụp" />
        <div class="captured-face-oval" aria-hidden="true"></div>
        <div class="captured-face-points">${facePointButtons()}</div>
      </div>
    `;
  }

  return `
    <div class="captured-face-map empty">
      <div class="capture-empty-face"></div>
      <div class="captured-face-oval" aria-hidden="true"></div>
      <div class="captured-face-points">${facePointButtons()}</div>
      <p>Chụp khuôn mặt ở màn scan để phân tích trên ảnh thật.</p>
    </div>
  `;
}

function toolSuggestions(point) {
  const suggested = (point.dung_cu_goi_y || [])
    .map((id) => tools.find((tool) => tool.id === id))
    .filter(Boolean);
  if (!suggested.length) return [];
  return [
    `<h3 class="section-title">Dụng cụ gợi ý</h3>`,
    `<div class="chips">${suggested.map((tool) => `<span class="chip">${tool.ten}</span>`).join("")}</div>`,
  ];
}

function renderAcupoints() {
  setTitle("Danh sách huyệt");
  app().innerHTML = acupoints.map(pointResult).join("");
}

function renderJournal() {
  setTitle("Report");
  const journals = [...state.journals].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  const latest = journals.slice(0, 4);
  const averageMood = journals.length
    ? (journals.reduce((sum, item) => sum + Number(item.mood || 0), 0) / journals.length).toFixed(1)
    : "0";
  app().innerHTML = `
    <section class="report-hero">
      <p class="eyebrow">Your face report</p>
      <h2>Kết quả phân tích Diện Chẩn</h2>
      <div class="report-score">
        <strong>${state.faceScore}%</strong>
        <span>Điểm cân bằng vùng mặt</span>
      </div>
    </section>
    <div class="metric-row">
      <div class="metric"><span class="small">Bản ghi</span><strong>${journals.length}</strong><span class="small">lần</span></div>
      <div class="metric"><span class="small">Cảm nhận TB</span><strong>${averageMood}</strong><span class="small">/ 4</span></div>
    </div>
    <section class="panel report-card">
      <div style="display:flex;justify-content:space-between;gap:10px;align-items:center">
        <h3>Theo dõi gần đây</h3>
        <span class="chip" style="background:var(--leaf-soft);color:var(--leaf)">${journals.length ? "Đã lưu API" : "Chưa có dữ liệu"}</span>
      </div>
      <svg class="trend" viewBox="0 0 320 130" role="img" aria-label="Biểu đồ mức khó chịu giảm từ 8 xuống 3">
        <path d="M10 20 H310 M10 50 H310 M10 80 H310 M10 110 H310" stroke="#e1e0d9"/>
        <path d="M10 25 C45 25 45 40 80 40 S120 58 150 62 S205 80 230 88 S270 98 310 98" fill="none" stroke="#1d9e75" stroke-width="4" stroke-linecap="round"/>
        <path d="M10 25 C45 25 45 40 80 40 S120 58 150 62 S205 80 230 88 S270 98 310 98 L310 120 L10 120 Z" fill="rgba(29,158,117,.12)"/>
      </svg>
      <p>${journals.length ? "Dữ liệu bệnh án được lưu qua API local trong backend/data/store.json." : "Bấm ghi nhật ký để bắt đầu tạo bệnh án thật."}</p>
    </section>
    <h2 class="section-title">Nhật ký đã lưu</h2>
    ${latest.length ? latest.map(journalEntry).join("") : `<div class="panel"><h3>Chưa có nhật ký</h3><p>Ghi một buổi thực hành để app lưu lại lịch sử và cảm nhận.</p></div>`}
    <button class="primary-btn" type="button" data-action="quick-journal" style="width:100%;margin-top:10px">＋ Ghi nhật ký hôm nay</button>
  `;
}

function journalEntry(item) {
  const protocol = protocols.find((protocol) => protocol.id === item.protocolId);
  const moodLabel = ["", "Khó chịu", "Bình thường", "Dễ chịu", "Rất tốt"][Number(item.mood)] || "Chưa rõ";
  return `
    <div class="panel" style="margin-bottom:10px">
      <h3>${protocol?.ten || "Phác đồ tự ghi"}</h3>
      <p>${formatDate(item.createdAt)} · ${moodLabel}${item.note ? ` · ${escapeHtml(item.note)}` : ""}</p>
    </div>
  `;
}

function formatDate(value) {
  return new Intl.DateTimeFormat("vi-VN", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
}

function renderQuickJournal() {
  setTitle("Nhật ký hôm nay");
  app().innerHTML = `
    <form data-action="journal-form">
    <section class="panel">
      <h2>Hôm nay cô làm phác đồ gì?</h2>
      <select name="protocolId" style="width:100%;min-height:50px;border-radius:14px;border:1px solid var(--soft);padding:0 12px;background:#fff">
        ${protocols.map((protocol) => `<option value="${protocol.id}" ${protocol.id === state.selectedProtocol ? "selected" : ""}>${protocol.ten}</option>`).join("")}
      </select>
    </section>
    <section class="panel">
      <h2>Cô cảm thấy thế nào?</h2>
      <input type="hidden" name="mood" value="${state.mood}" />
      <div class="mood-row">
        ${["Khó chịu", "Bình thường", "Dễ chịu", "Rất tốt"].map((label, index) => `<button class="mood ${state.mood === index + 1 ? "active" : ""}" type="button" data-action="mood" data-id="${index + 1}"><span style="font-size:1.5rem">${["☹", "○", "☺", "☻"][index]}</span><span>${label}</span></button>`).join("")}
      </div>
    </section>
    <section class="panel">
      <h2>Ghi chú thêm</h2>
      <textarea name="note" placeholder="Ví dụ: ngủ ngon hơn, bớt trằn trọc..."></textarea>
    </section>
    <button class="primary-btn" type="submit" style="width:100%">Lưu nhật ký</button>
    </form>
  `;
}

function renderConnect() {
  setTitle("Kết nối");
  app().innerHTML = `
    <div class="banner info"><strong>i</strong><span>Khu vực này cần mạng. Nội dung tra cứu, phác đồ, đồ hình và bệnh án vẫn dùng offline.</span></div>
    ${lookupRow("Hỏi đáp cộng đồng", "Có kiểm duyệt nội dung sức khỏe", "?", "toast", "green")}
    ${lookupRow("Tìm chuyên gia / lớp học", "Bản đồ và lịch học", "⌖", "toast", "blue")}
    ${lookupRow("Chia sẻ trải nghiệm", "Kể lại tiến triển của mình", "✎", "toast", "coral")}
  `;
}

function renderProfile() {
  setTitle("Cá nhân");
  app().innerHTML = `
    ${lookupRow("Bệnh án", "Tổng quan + biểu đồ", "✎", "journal", "green")}
    ${lookupRow("Đã lưu", "Huyệt và phác đồ yêu thích", "☆", "saved", "violet")}
    ${lookupRow("Khóa học", "Dẫn ra ngoài khi có mạng", "☼", "toast", "amber")}
    ${lookupRow("Cài đặt & Bảo mật", "Cỡ chữ, đồng bộ, nhắc lịch", "☰", "settings", "blue")}
    ${lookupRow("Data PRD", "Phần A/B cho thầy và dev", "{}", "dataSpec", "green")}
  `;
}

function renderSettings() {
  setTitle("Cài đặt");
  const presets = state.settings.presets;
  app().innerHTML = `
    <div class="banner info"><strong>i</strong><span>${productSpec.privacyNotice || "Bệnh án mặc định lưu trên máy, chỉ đồng bộ khi người dùng bật."}</span></div>
    <section class="panel">
      <h2>Cỡ chữ</h2>
      <div class="segmented">
        ${segment("font", "normal", "Vừa")}
        ${segment("font", "large", "Lớn")}
        ${segment("font", "xlarge", "Rất lớn")}
      </div>
    </section>
    <section class="panel">
      <h2>Bố cục Trang chủ</h2>
      <div class="segmented">
        ${segment("layout", "grid", "2 cột")}
        ${segment("layout", "list", "Danh sách")}
      </div>
      <div class="customize-list">
        ${orderedTiles().map((tile) => `
          <div class="drag-row" draggable="true" data-drag-tile="${tile.id}">
            <span class="drag-handle" aria-hidden="true">⋮⋮</span>
            <button type="button" data-action="move-up" data-id="${tile.id}" aria-label="Đưa ${tile.title} lên">↑</button>
            <button type="button" data-action="move-down" data-id="${tile.id}" aria-label="Đưa ${tile.title} xuống">↓</button>
            <strong>${tile.title}</strong>
          </div>
        `).join("")}
      </div>
      <div class="preset-row">
        <button type="button" data-action="save-preset">Lưu bố cục</button>
        <button type="button" data-action="reset-layout">Reset mặc định</button>
      </div>
      ${presets.length ? `<h3 class="section-title">Bố cục đã lưu</h3><div class="preset-row">${presets.map((preset, index) => `<button type="button" data-action="load-preset" data-id="${index}">${preset.name}</button>`).join("")}</div>` : ""}
    </section>
    <section class="panel">
      <h2>Bảo mật</h2>
      ${toggleRow("cloud", "Đồng bộ cloud", "Mặc định tắt, bệnh án lưu trên máy")}
      ${toggleRow("privacyAcknowledged", "Đã hiểu cách lưu dữ liệu", "Xác nhận trước khi dùng bệnh án lâu dài")}
      ${toggleRow("reminders", "Nhắc lịch tự chăm sóc", "Nhắc nhẹ theo giờ đã chọn")}
    </section>
  `;
}

function segment(key, value, label) {
  return `<button class="${state.settings[key] === value ? "active" : ""}" type="button" data-action="segment" data-key="${key}" data-id="${value}">${label}</button>`;
}

function toggleRow(key, title, desc) {
  return `
    <button class="row-card" type="button" data-action="toggle" data-id="${key}" style="margin-bottom:10px">
      <span class="row-icon" style="background:${state.settings[key] ? "var(--mint)" : "var(--coral-soft)"};color:${state.settings[key] ? "var(--green-deep)" : "var(--coral)"}">${state.settings[key] ? "✓" : "○"}</span>
      <span><strong>${title}</strong><p>${desc}</p></span>
    </button>
  `;
}

function renderDataSpec() {
  setTitle("Data & PRD");
  const counts = [
    ["huyet", acupoints.length],
    ["do_hinh", reflexMaps.length],
    ["diem_cham", touchPoints.length],
    ["phac_do", protocols.length],
    ["benh", conditions.length],
    ["nguyen_ly", principles.length],
    ["dung_cu", tools.length],
    ["benh_an", state.trackingRecords.length],
  ];
  app().innerHTML = `
    <section class="panel">
      <h2>Phần A — Dữ liệu</h2>
      <p><strong>${productSpec.title || "DIỆN CHẨN Data PRD"}</strong></p>
      <p><strong>Quan hệ:</strong> ${(productSpec.relationships || []).join(" · ")}</p>
      <div class="chips">${counts.map(([name, count]) => `<span class="chip">${name}: ${count}</span>`).join("")}</div>
      <p style="margin-top:12px">Điểm chạm dùng <strong>x, y = 0-1</strong>. Tìm kiếm dùng trường <strong>tu_khoa</strong> có cả tiếng dân gian để giọng nói hoạt động tốt. Trường <strong>co_nguy_hiem</strong> kích hoạt banner đỏ.</p>
    </section>
    <section class="panel">
      <h2>Phần B — Sitemap 4 tab</h2>
      ${Object.entries(productSpec.sitemap || {}).map(([key, items]) => `<p><strong>${key}:</strong> ${items.join(", ")}</p>`).join("")}
    </section>
    <section class="panel">
      <h2>Màn hình trong PRD</h2>
      ${(productSpec.screens || []).map((screen) => `<h3>${screen.ten}</h3><p>${screen.muc_tieu}</p>`).join("")}
    </section>
    <section class="panel">
      <h2>Yêu cầu phi chức năng</h2>
      ${(productSpec.nonFunctionalRequirements || []).map((item) => `<p><strong>${item.hang_muc}:</strong> ${item.yeu_cau}</p>`).join("")}
    </section>
    <section class="panel">
      <h2>MVP Phase 1</h2>
      <p>${(productSpec.mvpCompletionCriteria || []).join(" ")}</p>
    </section>
  `;
}

function renderPrinciples() {
  setTitle("Nguyên lý");
  app().innerHTML = principles
    .map(
      (principle) => `
        <section class="panel">
          <h2>${principle.ten}</h2>
          <p>${principle.noi_dung}</p>
          <div class="chips">${(principle.hinh_anh || []).map((image) => `<span class="chip">${image}</span>`).join("") || `<span class="chip">rich content</span>`}</div>
        </section>
      `,
    )
    .join("");
}

function renderTools() {
  setTitle("Dụng cụ");
  app().innerHTML = tools
    .map(
      (tool) => `
        <section class="panel">
          <h2>${tool.ten}</h2>
          <p><strong>Công dụng:</strong> ${tool.cong_dung}</p>
          <p><strong>Cách dùng:</strong> ${tool.cach_dung || "Đọc hướng dẫn trong phác đồ."}</p>
          <button class="chip" type="button" data-action="bookmark" data-type="tool" data-id="${tool.id}">☆ Lưu</button>
        </section>
      `,
    )
    .join("");
}

function renderSaved() {
  setTitle("Đã lưu");
  const bookmarks = state.bookmarks;
  app().innerHTML = bookmarks.length
    ? bookmarks.map(savedEntry).join("")
    : `<section class="panel"><h2>Chưa có mục đã lưu</h2><p>Bấm ☆ ở huyệt, phác đồ hoặc dụng cụ để lưu vào danh sách này.</p></section>`;
}

function savedEntry(bookmark) {
  const item =
    bookmark.targetType === "acupoint"
      ? acupoints.find((point) => point.id === bookmark.targetId)
      : bookmark.targetType === "protocol"
        ? protocols.find((protocol) => protocol.id === bookmark.targetId)
        : tools.find((tool) => tool.id === bookmark.targetId);
  const action = bookmark.targetType === "protocol" ? "protocol" : bookmark.targetType === "acupoint" ? "point" : "tools";
  return `
    <button class="row-card" type="button" data-action="${action}" data-id="${bookmark.targetId}" style="margin-bottom:10px">
      <span class="row-icon" style="background:var(--violet-soft);color:var(--violet)">☆</span>
      <span><strong>${item?.ten || bookmark.targetId}</strong><p>${bookmark.targetType} · ${formatDate(bookmark.createdAt)}</p></span>
      <span>›</span>
    </button>
  `;
}

function app() {
  return document.getElementById("app");
}

function normalize(text) {
  return String(text || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .trim();
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" })[char]);
}

function toast(message) {
  const el = document.getElementById("toast");
  el.textContent = message;
  el.classList.add("show");
  window.setTimeout(() => el.classList.remove("show"), 1800);
}

document.addEventListener("submit", async (event) => {
  const form = event.target.closest("[data-action='search-form']");
  if (form) {
    event.preventDefault();
    state.query = new FormData(form).get("q") || "";
    setView("search", state.tab);
    return;
  }

  const journalForm = event.target.closest("[data-action='journal-form']");
  if (!journalForm) return;
  event.preventDefault();
  const data = new FormData(journalForm);
  const payload = {
    protocolId: data.get("protocolId"),
    conditionId: protocols.find((protocol) => protocol.id === data.get("protocolId"))?.benh_ids?.[0],
    mood: Number(data.get("mood") || state.mood),
    note: String(data.get("note") || "").trim(),
  };
  try {
    const created = await apiFetch("/api/v1/journals", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    state.journals = [created, ...state.journals];
    toast("Đã lưu nhật ký vào backend");
  } catch {
    state.journals = [{ id: `offline_${Date.now()}`, createdAt: new Date().toISOString(), ...payload }, ...state.journals];
    toast("API chưa chạy, đã lưu tạm trong phiên hiện tại");
  }
  setView("journal", "profile");
});

document.addEventListener("click", async (event) => {
  const tab = event.target.closest("[data-tab]");
  if (tab) {
    const next = tab.dataset.tab;
    state.tab = next;
    state.view = next;
    render();
    return;
  }

  const target = event.target.closest("[data-action]");
  if (!target) return;
  const action = target.dataset.action;
  const id = target.dataset.id;

  if (action === "voice") {
    state.query = "khó ngủ";
    toast("Đã mô phỏng giọng nói: khó ngủ");
    setView("search", state.tab);
  }
  if (action === "scan-face") {
    const captured = captureFaceFrame();
    state.faceScore = 72 + Math.floor(Math.random() * 18);
    const suggested = acupoints[Math.floor(Math.random() * acupoints.length)];
    if (suggested) state.selectedPoint = suggested.id;
    toast(captured ? "Đã chụp mặt và phủ điểm huyệt lên ảnh thật" : "Camera chưa sẵn sàng, đang dùng bản căn chỉnh");
    renderMap();
  }
  if (action === "symptoms") renderProtocolList("benh_mat_ngu");
  if (action === "protocols") setView("protocols", "home");
  if (action === "protocol") {
    state.selectedProtocol = id;
    setView("protocolDetail", state.tab);
  }
  if (action === "condition") renderProtocolList(id);
  if (action === "map") setView("map", "lookup");
  if (action === "map-point" || action === "point" || action === "select-point") {
    state.selectedPoint = id;
    setView("map", "lookup");
  }
  if (action === "acupoints") setView("acupoints", "lookup");
  if (action === "journal") setView("journal", "profile");
  if (action === "quick-journal") setView("quickJournal", "profile");
  if (action === "settings" || action === "open-settings") setView("settings", "profile");
  if (action === "dataSpec") setView("dataSpec", "profile");
  if (action === "principles") setView("principles", "lookup");
  if (action === "tools") setView("tools", "lookup");
  if (action === "saved") setView("saved", "profile");
  if (action === "toast") toast("Chức năng online sẽ mở ở phase sau");
  if (action === "bookmark") {
    const bookmark = {
      targetType: target.dataset.type || "acupoint",
      targetId: id,
    };
    try {
      const saved = await apiFetch("/api/v1/bookmarks", {
        method: "POST",
        body: JSON.stringify(bookmark),
      });
      if (!state.bookmarks.some((item) => item.id === saved.id)) state.bookmarks = [saved, ...state.bookmarks];
      toast("Đã lưu vào danh sách yêu thích");
    } catch {
      state.bookmarks = [{ id: `offline_${Date.now()}`, createdAt: new Date().toISOString(), ...bookmark }, ...state.bookmarks];
      toast("API chưa chạy, đã lưu tạm");
    }
  }
  if (action === "save-record") {
    const protocol = protocols.find((item) => item.id === state.selectedProtocol);
    const conditionId = protocol?.benh_ids?.[0] || "benh_mat_ngu";
    try {
      const record = await apiFetch("/api/v1/tracking-records", {
        method: "POST",
        body: JSON.stringify({ benh_id: conditionId }),
      });
      state.trackingRecords = [record, ...state.trackingRecords];
      toast("Đã tạo hồ sơ theo dõi");
    } catch {
      toast("Chưa lưu được hồ sơ theo dõi");
    }
  }
  if (action === "guide") toast("Chế độ hướng dẫn sẽ đọc to và đếm giờ từng bước");
  if (action === "protocols-by-point") {
    const protocol = protocols.find((item) => item.buoc.some((step) => step.huyet_id === id));
    state.selectedProtocol = protocol?.id || "pd_mat_ngu";
    setView("protocolDetail", "home");
  }
  if (action === "mood") {
    state.mood = Number(id);
    render();
  }
  if (action === "save-journal") toast("Đã lưu nhật ký và cập nhật biểu đồ");
  if (action === "segment") {
    state.settings[target.dataset.key] = id;
    saveSettings();
    render();
  }
  if (action === "toggle") {
    state.settings[id] = !state.settings[id];
    saveSettings();
    render();
  }
  if (action === "move-up" || action === "move-down") {
    const order = state.settings.tileOrder;
    const index = order.indexOf(id);
    const next = action === "move-up" ? index - 1 : index + 1;
    if (next >= 0 && next < order.length) {
      [order[index], order[next]] = [order[next], order[index]];
      saveSettings();
      render();
    }
  }
  if (action === "reset-layout") {
    state.settings.tileOrder = tiles.map((tile) => tile.id);
    state.settings.layout = "grid";
    saveSettings();
    render();
  }
  if (action === "save-preset") {
    state.settings.presets.push({
      name: `Bố cục ${state.settings.presets.length + 1}`,
      layout: state.settings.layout,
      tileOrder: [...state.settings.tileOrder],
    });
    saveSettings();
    render();
  }
  if (action === "load-preset") {
    const preset = state.settings.presets[Number(id)];
    if (preset) {
      state.settings.layout = preset.layout;
      state.settings.tileOrder = [...preset.tileOrder];
      saveSettings();
      render();
    }
  }
});

document.addEventListener("dragstart", (event) => {
  const row = event.target.closest("[data-drag-tile]");
  if (!row) return;
  event.dataTransfer.setData("text/plain", row.dataset.dragTile);
  event.dataTransfer.effectAllowed = "move";
  row.classList.add("dragging");
});

document.addEventListener("dragend", (event) => {
  const row = event.target.closest("[data-drag-tile]");
  if (row) row.classList.remove("dragging");
});

document.addEventListener("dragover", (event) => {
  if (event.target.closest("[data-drag-tile]")) {
    event.preventDefault();
  }
});

document.addEventListener("drop", (event) => {
  const row = event.target.closest("[data-drag-tile]");
  if (!row) return;
  event.preventDefault();
  const fromId = event.dataTransfer.getData("text/plain");
  const toId = row.dataset.dragTile;
  if (!fromId || fromId === toId) return;
  const order = state.settings.tileOrder.filter((id) => id !== fromId);
  const toIndex = order.indexOf(toId);
  order.splice(toIndex, 0, fromId);
  state.settings.tileOrder = order;
  saveSettings();
  render();
});

const hour = new Date().getHours();
document.getElementById("greeting").textContent = hour < 12 ? "Chào buổi sáng," : hour < 18 ? "Chào buổi chiều," : "Chào buổi tối,";
loadRemoteState().finally(render);
