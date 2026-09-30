import {
  FaceLandmarker,
  FilesetResolver,
} from 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/+esm';

let landmarkerPromise;

async function getLandmarker() {
  if (!landmarkerPromise) {
    landmarkerPromise = (async () => {
      const vision = await FilesetResolver.forVisionTasks(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm',
      );
      return FaceLandmarker.createFromOptions(vision, {
        baseOptions: {
          modelAssetPath:
            'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task',
          delegate: 'GPU',
        },
        runningMode: 'IMAGE',
        numFaces: 2,
        minFaceDetectionConfidence: 0.65,
        minFacePresenceConfidence: 0.65,
        minTrackingConfidence: 0.65,
        outputFacialTransformationMatrixes: true,
      });
    })();
  }
  return landmarkerPromise;
}

function imageFromDataUrl(dataUrl) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = reject;
    image.src = dataUrl;
  });
}

function degrees(value) {
  return (value * 180) / Math.PI;
}

function result(
  valid,
  message,
  box,
  yaw = 0,
  pitch = 0,
  roll = 0,
  imageWidth = 1,
  imageHeight = 1,
) {
  return JSON.stringify({
    valid,
    message,
    box,
    yaw,
    pitch,
    roll,
    imageWidth,
    imageHeight,
  });
}

async function analyze(dataUrl) {
  const [landmarker, image] = await Promise.all([
    getLandmarker(),
    imageFromDataUrl(dataUrl),
  ]);
  const detection = landmarker.detect(image);
  const faces = detection.faceLandmarks ?? [];
  if (faces.length === 0) {
    return result(false, 'Không thấy khuôn mặt. Hãy nhìn thẳng vào camera.', null, 0, 0, 0, image.naturalWidth, image.naturalHeight);
  }
  if (faces.length !== 1) {
    return result(false, 'Chỉ để một khuôn mặt trong khung hình.', null, 0, 0, 0, image.naturalWidth, image.naturalHeight);
  }

  const points = faces[0];
  const xs = points.map((point) => point.x);
  const ys = points.map((point) => point.y);
  const left = Math.max(0, Math.min(...xs));
  const top = Math.max(0, Math.min(...ys));
  const right = Math.min(1, Math.max(...xs));
  const bottom = Math.min(1, Math.max(...ys));
  const box = {
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  };

  const leftEye = points[33];
  const rightEye = points[263];
  const nose = points[1];
  const leftCheek = points[234];
  const rightCheek = points[454];
  const forehead = points[10];
  const chin = points[152];
  const roll = degrees(
    Math.atan2(rightEye.y - leftEye.y, rightEye.x - leftEye.x),
  );
  const cheekCenterX = (leftCheek.x + rightCheek.x) / 2;
  const yaw = ((nose.x - cheekCenterX) / Math.max(box.width, 0.01)) * 55;
  const verticalCenter = (forehead.y + chin.y) / 2;
  const pitch = ((nose.y - verticalCenter) / Math.max(box.height, 0.01)) * 45;
  const centerX = box.x + box.width / 2;
  const centerY = box.y + box.height / 2;
  const centerError = Math.hypot(centerX - 0.5, centerY - 0.46);

  if (box.width < 0.32 || box.height < 0.38) {
    return result(false, 'Đưa khuôn mặt lại gần camera hơn.', box, yaw, pitch, roll, image.naturalWidth, image.naturalHeight);
  }
  if (box.width > 0.78 || box.height > 0.82) {
    return result(false, 'Đưa khuôn mặt ra xa camera một chút.', box, yaw, pitch, roll, image.naturalWidth, image.naturalHeight);
  }
  if (centerError > 0.12) {
    return result(false, 'Đưa khuôn mặt vào chính giữa khung.', box, yaw, pitch, roll, image.naturalWidth, image.naturalHeight);
  }
  if (Math.abs(yaw) > 10 || Math.abs(pitch) > 10 || Math.abs(roll) > 7) {
    return result(
      false,
      'Giữ đầu thẳng, không nghiêng hoặc quay sang hai bên.',
      box,
      yaw,
      pitch,
      roll,
      image.naturalWidth,
      image.naturalHeight,
    );
  }
  return result(
    true,
    'Khuôn mặt đạt yêu cầu và đã sẵn sàng đặt huyệt.',
    box,
    yaw,
    pitch,
    roll,
    image.naturalWidth,
    image.naturalHeight,
  );
}

window.dienChanFaceLandmarker = { analyze };
