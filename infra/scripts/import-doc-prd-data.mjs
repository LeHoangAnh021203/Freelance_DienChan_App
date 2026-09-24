import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

const rootDir = resolve(fileURLToPath(new URL("../..", import.meta.url)));
const storePath = resolve(rootDir, "backend/data/store.json");
const store = JSON.parse(await readFile(storePath, "utf8"));

const toolIds = ["dc_cay_lan", "dc_que_do", "dc_bua_go"];

store.catalog.acupoints = store.catalog.acupoints.map((point) => ({
  hinh_anh: `/assets/acupoints/${point.id}.png`,
  dung_cu_goi_y: point.id === "huyet_34" ? ["dc_cay_lan", "dc_que_do"] : toolIds.slice(0, 2),
  ...point,
}));

const conditionDescriptions = {
  benh_mat_ngu: "Khó vào giấc, ngủ không sâu hoặc trằn trọc kéo dài.",
  trc_dau_dau: "Cảm giác nhức, căng hoặc váng vùng đầu.",
  benh_tang_huyet_ap: "Tình trạng huyết áp cao hoặc choáng cần được theo dõi y tế.",
  trc_day_bung: "Cảm giác no hơi, khó tiêu hoặc đầy vùng bụng sau ăn.",
};

store.catalog.conditions = store.catalog.conditions.map((condition) => ({
  mo_ta: conditionDescriptions[condition.id] || "",
  ...condition,
}));

store.catalog.reflexMaps = [
  {
    id: "dohinh_mat_truoc",
    ten: "Mặt nhìn thẳng",
    anh_nen: "/assets/reflex-maps/mat-nhin-thang.png",
    kich_thuoc: { w: 200, h: 260 },
  },
];

store.catalog.touchPoints = store.catalog.acupoints.map((point) => ({
  do_hinh_id: "dohinh_mat_truoc",
  huyet_id: point.id,
  x: point.x,
  y: point.y,
  ban_kinh_cham: 0.075,
}));

store.catalog.principles = [
  {
    id: "np_dong_ung",
    ten: "Nguyên lý Đồng ứng",
    noi_dung:
      "Các vùng trên mặt có thể được dùng như điểm phản chiếu tương ứng với vùng cơ thể. Trong app, nguyên lý này giúp giải thích vì sao một phác đồ chọn nhóm huyệt nhất định.",
    hinh_anh: ["/assets/principles/dong-ung.png"],
  },
  {
    id: "np_phan_chieu",
    ten: "Nguyên lý Phản chiếu",
    noi_dung:
      "Đồ hình phản chiếu biến ảnh tĩnh thành bản đồ chạm được. Mỗi huyệt có tọa độ x/y theo tỉ lệ 0-1 để co giãn trên mọi màn hình.",
    hinh_anh: ["/assets/principles/phan-chieu.png"],
  },
  {
    id: "np_day_an",
    ten: "Nguyên lý Day ấn",
    noi_dung:
      "Tác động nên nhẹ, đều, có thời lượng rõ ràng. Người dùng cần dừng lại khi đau, chóng mặt hoặc có dấu hiệu bất thường.",
    hinh_anh: [],
  },
];

store.catalog.tools = [
  {
    id: "dc_cay_lan",
    ten: "Cây lăn",
    cong_dung: "Lăn nhẹ trên vùng mặt để tác động đều, phù hợp với các bước cần kích thích diện rộng.",
    cach_dung: "Lăn chậm 30-60 giây, lực vừa phải, tránh vùng da đau hoặc tổn thương.",
    hinh_anh: "/assets/tools/cay-lan.png",
  },
  {
    id: "dc_que_do",
    ten: "Que dò",
    cong_dung: "Tìm và tác động điểm huyệt chính xác hơn bằng đầu nhỏ.",
    cach_dung: "Ấn nhẹ từng nhịp, tăng lực từ từ, không ấn mạnh gây đau.",
    hinh_anh: "/assets/tools/que-do.png",
  },
  {
    id: "dc_bua_go",
    ten: "Búa gõ",
    cong_dung: "Gõ nhẹ theo nhịp trên vùng được hướng dẫn trong phác đồ.",
    cach_dung: "Gõ rất nhẹ, đều tay, dừng ngay nếu khó chịu.",
    hinh_anh: "/assets/tools/bua-go.png",
  },
];

store.productSpec = {
  source: "Dien_Chan_Data_PRD.docx",
  title: "DIỆN CHẨN Điều Khiển Liệu Pháp - Cấu trúc dữ liệu & Đặc tả sản phẩm",
  version: "Bản thảo v1.0",
  date: "Tháng 6, 2026",
  relationships: [
    "Triệu chứng/Bệnh tham chiếu Phác đồ",
    "Phác đồ tham chiếu danh sách Huyệt",
    "Huyệt tham chiếu Điểm trên Đồ hình",
    "Dụng cụ được gợi ý từ Huyệt",
    "Bệnh án tham chiếu Phác đồ đã dùng và nhật ký cảm nhận",
  ],
  sitemap: {
    home: ["Tìm kiếm/giọng nói", "Tra triệu chứng", "Phác đồ chữa", "Tra huyệt & đồ hình", "Bệnh án của tôi", "Dưỡng sinh hôm nay"],
    lookup: ["Đồ hình trên mặt", "Danh sách huyệt", "Bệnh theo nhóm", "Nguyên lý"],
    connect: ["Hỏi đáp cộng đồng", "Tìm chuyên gia/lớp học", "Chia sẻ trải nghiệm"],
    profile: ["Bệnh án", "Đã lưu", "Khóa học", "Cài đặt"],
  },
  screens: [
    {
      id: "home",
      ten: "Trang chủ",
      muc_tieu: "Cho người dùng hiểu ngay nên bấm đâu trong 3 giây.",
      hanh_vi: ["Ô tìm kiếm và micro", "4 thẻ Tôi muốn", "Dưỡng sinh hôm nay đổi nội dung mỗi ngày", "Lời chào theo buổi"],
      truong_hop_dac_biet: ["Chưa đăng nhập vẫn tra cứu được", "Không có mạng vẫn dùng được tra cứu offline"],
    },
    {
      id: "search",
      ten: "Kết quả tìm kiếm",
      muc_tieu: "Trả kết quả phù hợp từ câu nói/gõ của người thường.",
      hanh_vi: ["Tìm trên tu_khoa", "Gộp kết quả theo Bệnh/Triệu chứng, Phác đồ, Huyệt", "Cảnh báo đỏ nếu co_nguy_hiem"],
      truong_hop_dac_biet: ["Không có kết quả thì gợi ý triệu chứng phổ biến và hỏi cộng đồng"],
    },
    {
      id: "protocols",
      ten: "Danh sách Phác đồ",
      muc_tieu: "Cho chọn phác đồ phù hợp với triệu chứng/bệnh.",
      hanh_vi: ["Liệt kê tên, số huyệt, thời lượng, thời điểm", "Sắp theo mức liên quan", "Bấm vào chi tiết"],
      truong_hop_dac_biet: [],
    },
    {
      id: "protocol_detail",
      ten: "Phác đồ chi tiết",
      muc_tieu: "Hướng dẫn người dùng tự làm được mà không cần học trước.",
      hanh_vi: ["Header có badge", "Banner đỏ khi di_kham_ngay", "Bước theo thứ tự", "Bắt đầu hướng dẫn", "Lưu vào bệnh án"],
      truong_hop_dac_biet: ["Bước đang làm phóng to và có thể đọc to", "Cho phép bookmark"],
    },
    {
      id: "interactive_map",
      ten: "Đồ hình tương tác",
      muc_tieu: "Thay ảnh tĩnh khó nhìn bằng bản đồ chạm được.",
      hanh_vi: ["Ảnh nền + điểm chạm", "Chạm điểm hiện panel huyệt", "Vùng chạm rộng", "Hỗ trợ zoom"],
      truong_hop_dac_biet: ["Mở từ phác đồ thì tự highlight đúng huyệt"],
    },
    {
      id: "acupoint_detail",
      ten: "Chi tiết huyệt",
      muc_tieu: "Trang tra cứu đầy đủ một huyệt.",
      hanh_vi: ["Hiện số, tên, công dụng, vị trí, cách tác động, hình ảnh", "Mở đồ hình tại đúng điểm", "Liệt kê phác đồ dùng huyệt", "Gợi ý dụng cụ"],
      truong_hop_dac_biet: [],
    },
    {
      id: "medical_record",
      ten: "Bệnh án tổng quan",
      muc_tieu: "Tạo động lực qua việc thấy rõ sự cải thiện.",
      hanh_vi: ["Chuỗi ngày", "Tổng số buổi", "Biểu đồ cảm nhận", "Danh sách đang theo dõi", "Ghi nhật ký hôm nay"],
      truong_hop_dac_biet: ["Chưa có dữ liệu thì mời bắt đầu theo dõi vấn đề đầu tiên"],
    },
    {
      id: "quick_journal",
      ten: "Ghi nhật ký nhanh",
      muc_tieu: "Ghi xong trong khoảng 10 giây.",
      hanh_vi: ["Chọn phác đồ", "Chọn cảm nhận 1-4", "Ghi chú không bắt buộc", "Lưu cập nhật biểu đồ/streak"],
      truong_hop_dac_biet: [],
    },
    {
      id: "settings_privacy",
      ten: "Cài đặt & Bảo mật",
      muc_tieu: "Cho người dùng kiểm soát trải nghiệm và dữ liệu.",
      hanh_vi: ["Cỡ chữ", "Đồng bộ cloud mặc định tắt", "Chính sách bảo mật", "Nhắc lịch"],
      truong_hop_dac_biet: ["Lần đầu vào Bệnh án phải giải thích dữ liệu lưu ở đâu"],
    },
  ],
  nonFunctionalRequirements: [
    { hang_muc: "Khả dụng cho người già", yeu_cau: "Chữ tối thiểu 16px, vùng chạm tối thiểu 44px, hỗ trợ text-to-speech và tìm bằng giọng nói tiếng Việt." },
    { hang_muc: "Offline", yeu_cau: "Toàn bộ nội dung tra cứu huyệt, phác đồ, đồ hình, nguyên lý xem được không cần mạng." },
    { hang_muc: "Đa nền tảng", yeu_cau: "iOS và Android, dùng chung hệ thống thành phần giao diện; cân nhắc Flutter/React Native." },
    { hang_muc: "Hiệu năng", yeu_cau: "Mở app dưới 2 giây; đồ hình tương tác mượt khi zoom/chạm." },
    { hang_muc: "Bảo mật dữ liệu", yeu_cau: "Bệnh án mặc định on-device, mã hóa khi đồng bộ; tuân thủ chính sách dữ liệu sức khỏe của App Store/Google Play." },
    { hang_muc: "An toàn nội dung", yeu_cau: "Disclaimer toàn app; cảnh báo đi khám với bệnh nguy hiểm; hỏi đáp cộng đồng có kiểm duyệt." },
    { hang_muc: "Đa ngôn ngữ", yeu_cau: "Tách phần văn bản để dễ dịch sang ngôn ngữ khác về sau." },
  ],
  mvpCompletionCriteria: [
    "Người dùng nói/gõ một triệu chứng và nhận được phác đồ phù hợp.",
    "Mở được phác đồ chi tiết, làm theo từng bước có đếm giờ.",
    "Chạm đồ hình xem được huyệt và nhảy sang phác đồ liên quan.",
    "Tra cứu hoạt động offline.",
    "Có disclaimer + cảnh báo bệnh nguy hiểm hoạt động đúng.",
    "Cài đặt cỡ chữ hoạt động toàn app.",
  ],
  privacyNotice:
    "Bệnh án là dữ liệu sức khỏe nhạy cảm. Mặc định lưu trên máy; chỉ đồng bộ cloud khi người dùng chủ động bật.",
};

store.trackingRecords = store.trackingRecords || [];
store.bookmarks = store.bookmarks || [];
store.journals = store.journals || [];
store.settings = {
  ...store.settings,
  cloud: false,
  privacyAcknowledged: false,
};

await writeFile(storePath, `${JSON.stringify(store, null, 2)}\n`);
console.log("Imported PRD data into backend/data/store.json");
