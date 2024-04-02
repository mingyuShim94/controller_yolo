import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class YoloSample extends StatefulWidget {
  const YoloSample({super.key});

  @override
  State<YoloSample> createState() => _YoloSampleState();
}

class _YoloSampleState extends State<YoloSample> {
  List<Widget> boxes = []; // 경계 상자를 나타낼 위젯 리스트
  Image? image;
  @override
  void initState() {
    super.initState();
    testYolov8();
  }

  testYolov8() async {
    img.Image? image = await _loadImage('assets/images/any_image.png');
    Interpreter interpreter =
        await Interpreter.fromAsset('assets/models/yolov8n_float16.tflite');
    final input = _preProcess(image!);

    // output shape:
    // 1 : batch size
    // 4 + 80: left, top, right, bottom and probabilities for each class
    // 8400: num predictions
    final output = List<num>.filled(1 * 84 * 8400, 0).reshape([1, 84, 8400]);
    int predictionTimeStart = DateTime.now().millisecondsSinceEpoch;
    interpreter.run([input], output);
    int predictionTime =
        DateTime.now().millisecondsSinceEpoch - predictionTimeStart;
    print('Prediction time: $predictionTime ms');
    double scaleFactorW = 1440 / 640;
    double scaleFactorH = 800 / 640;
    var prediction = output[0][0]; // 첫 번째 예측 결과
    var left = prediction[0] *
        scaleFactorW; // scaleFactor는 실제 이미지와 모델 입력 사이의 비율 조정을 위한 값입니다.
    var top = prediction[1] * scaleFactorH;
    var right = prediction[2] * scaleFactorW;
    var bottom = prediction[3] * scaleFactorH;

    // 좌표를 사용하여 상자를 그립니다. 여기서는 간단히 left와 top을 시작점으로,
    // right와 bottom으로부터 width와 height를 계산합니다.
    var width = right - left;
    var height = bottom - top;
// Flutter의 Color 객체를 사용하여 색상을 정의
    Color flutterColor = const Color(0xFFFF0000); // 빨간색

// image 라이브러리에 적합한 형식으로 색상 값을 변환
    int imageColor = flutterColor.value;
    img.drawLine(image,
        x1: left,
        y1: top,
        x2: right,
        y2: top,
        color: const Color(0xFFFF0000),
        thickness: 2); // 상단
    img.drawLine(image,
        x1: right,
        y1: top,
        x2: right,
        y2: bottom,
        color: img.getColor(255, 0, 0),
        thickness: 2); // 우측
    img.drawLine(image,
        x1: right,
        y1: bottom,
        x2: left,
        y2: bottom,
        color: img.getColor(255, 0, 0),
        thickness: 2); // 하단
    img.drawLine(image,
        x1: left,
        y1: bottom,
        x2: left,
        y2: top,
        color: img.getColor(255, 0, 0),
        thickness: 2); // 좌측

    setState(() {
      boxes = [buildBox(left, top, width, height, Colors.red)]; // 예시 좌표
    });
  }

  Future<img.Image?> _loadImage(String imagePath) async {
    final imageData = await rootBundle.load(imagePath);
    return img.decodeImage(imageData.buffer.asUint8List());
  }

  List<List<List<num>>> _preProcess(img.Image image) {
    final imgResized = img.copyResize(image, width: 640, height: 640);
    image = imgResized;
    return convertImageToMatrix(imgResized);
  }

// yolov8 requires input normalized between 0 and 1
  List<List<List<num>>> convertImageToMatrix(img.Image image) {
    return List.generate(
      image.height,
      (y) => List.generate(
        image.width,
        (x) {
          final pixel = image.getPixel(x, y);

          return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
        },
      ),
    );
  }

  Widget buildBox(
      double left, double top, double width, double height, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(child: image ?? Image.asset('assets/images/any_image.png')),
          ...boxes, // 경계 상자 위젯들을 여기에 포함합니다.
        ],
      ),
    );
  }
}
