import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  CroppedFile? croppedFile;
  TextEditingController? idTextController;
  TextEditingController? titleTextController;

  var data;
  var cleanConfidence;
  var cleanClassValue;
  var isLoading = false.obs;
  var id = 0.obs;
  var classStatus;
  var responseStatus;
  File? resizedFile;
  TextEditingController runNo = TextEditingController();

  Future<void> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _cropImage();
      }
    } on SocketException catch (e) {
      print(e);
      setState(() {
        data = null;
      });
      Get.showSnackbar(GetSnackBar(
        backgroundColor: Colors.red,
        message: "Please try after some time",
        title: "No Internet Connection",
        snackPosition: SnackPosition.TOP,
        duration: Duration(milliseconds: 2000),
      ));
    }
  }
Future<void> _cropImage() async {
    croppedFile = await ImageCropper().cropImage(
    sourcePath: _image!.path,
    aspectRatioPresets: [
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ],
    uiSettings: [
      AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
      IOSUiSettings(
        title: 'Cropper',
      ),
      WebUiSettings(
        context: context,
      ),
    ],
  );
    final bytes = await croppedFile?.readAsBytes();
    final resizedImage = img.decodeImage(bytes!);
    final resized = img.copyResize(resizedImage!, width: 512, height: 512);
    final tempDir = await getTemporaryDirectory();

    setState(() {
      resizedFile = File('${tempDir.path}/resized${DateTime.now().microsecondsSinceEpoch}.jpeg')..writeAsBytesSync(img.encodeJpg(resized));
    });
    upload(resizedFile!);

}

  upload(File imageFile) async {
    try {
      setState(() {
        isLoading.value = true;
        data = null;
      });


      // ignore: deprecated_member_use
      var stream = http.ByteStream(DelegatingStream.typed(resizedFile!.openRead()));
      var length = await resizedFile?.length();
      var uploadURL = "http://ec2-54-227-80-131.compute-1.amazonaws.com/predict";
      var uri = Uri.parse(uploadURL);
      var request = http.MultipartRequest("POST", uri);
      var multipartFile = http.MultipartFile('file', stream, length!,
          filename: (imageFile.path));
      request.files.add(multipartFile);
      var response = await request.send();
      responseStatus = response.statusCode;
      if (response.statusCode == 200) {
        response.stream.transform(utf8.decoder).transform(json.decoder).listen((value) {
          // print("Value is :  $value");
          data = value;
          setState(() {});
        });
      } else if (responseStatus == 502) {
        Get.showSnackbar(GetSnackBar(
          backgroundColor: Colors.red,
          message: "Please try after some time",
          title: "No Internet Connection",
          snackPosition: SnackPosition.TOP,
          duration: Duration(milliseconds: 2000),
        ));
      } else {
        setState(() {
          isLoading.value = false;
        });
      }
    } finally {
      setState(() {
        isLoading.value = false;
      });
    }
  }

  savePdf() async {
    if (resizedFile == null) {
      Get.showSnackbar(GetSnackBar(
        message: "No Image Selected",
        title: "Select Image",
        snackPosition: SnackPosition.TOP,
        duration: Duration(milliseconds: 1500),
      ));
    } else if (runNo.text == "") {
      Get.showSnackbar(GetSnackBar(
        message: "Run Number Empty",
        title: "Enter Run No.",
        snackPosition: SnackPosition.TOP,
        duration: Duration(milliseconds: 1500),
      ));
    } else {
      var h = MediaQuery.of(context).size.height;
      final pdf = pw.Document();
      (data == null)
          ? Get.showSnackbar(GetSnackBar(
              message: "Please try again",
              title: "No data Found.",
              snackPosition: SnackPosition.TOP,
              duration: Duration(milliseconds: 1500),
            ))
          : pdf.addPage(
              pw.Page(
                build: (pw.Context context) => pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("Run No : ${runNo.text}",
                          style: pw.TextStyle(
                              fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Image(
                        pw.MemoryImage(resizedFile!.readAsBytesSync()),
                        height: h /2,
                      ),
                      pw.ListView.builder(
                        itemCount: data['Class'].length,
                        itemBuilder: (context, index) {
                          print(data['Class'].length);
                          switch (data["Class"][index].toString()) {
                            case "15":
                              classStatus = "CLEAN";
                              break;
                            case "16":
                              classStatus = "DOT ";
                              break;
                            case "17":
                              classStatus = "INCLUSION ";
                              break;
                            case "18":
                              classStatus = "BREAKAGE";
                              break;
                          }
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    "$classStatus = >   ${data["Percentage"][index].toString()} % ",
                                    style: pw.TextStyle(
                                        fontSize: 20,
                                        fontWeight: pw.FontWeight.bold),
                                  )),
                            ],
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            );

      pdf.addPage(pw.Page(
          build: (pw.Context context) => pw.Center(
                  child: pw.Column(children: [
                pw.Image(
                  pw.MemoryImage(base64Decode(data["image"])),
                  height: h / 1.5,
                ),
              ]))));
      Directory? directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
      }
      if (!await directory.exists())
        directory = await getExternalStorageDirectory();
      final bytes = await pdf.save();
      File file = File(
          '${directory!.path}/bcdi_detection${DateTime.now().microsecondsSinceEpoch}.pdf');
      print(file);
      await file.writeAsBytes(bytes);

      Get.showSnackbar(GetSnackBar(
        message: "File Save Successfully on Downloads Folder",
        title: "Saved",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 1500),
      ));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    log('image path : ${image?.path} -- MimeType : ${image?.mimeType}');

    setState(() {
      _image = File(image!.path);
    });
    hasNetwork();

    Get.back();
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    log('image path : ${image?.path} -- MimeType : ${image?.mimeType}');

    setState(() {
      _image = File(image!.path);
    });

    hasNetwork();
    Get.back();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Center(
                    child: Image(
                        image: AssetImage("assets/images/bg.png"),
                        height: w / 5),
                  ),
                ),
                const Center(
                    child: Text(
                  "Maitri Diamond Purity",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 25),
                )),
                const SizedBox(
                  height: 10,
                ),
                const Center(
                    child: Text(
                  "BCDI-DETECTION",
                  style: TextStyle(color: Colors.black, fontSize: 25),
                )),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Run No :- ",
                          style: const TextStyle(fontSize: 25),
                        ),
                        TextFormField(
                          controller: runNo,
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.only(left: 10),
                              constraints: BoxConstraints(
                                maxWidth: w / 4,
                                maxHeight: 35,
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                            onTap: () {
                              savePdf();
                            },
                            child: const Icon(
                              Icons.download_sharp,
                              size: 35,
                            )),
                        const SizedBox(
                          width: 20,
                        ),
                        InkWell(
                            onTap: () {
                              setState(() {
                                runNo.text = "";
                                _image = null;
                                data = null;
                                responseStatus = "";
                              });
                            },
                            child: const Icon(Icons.delete, size: 35)),
                      ],
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                (resizedFile == null)
                    ? Container(
                        height: h / 3,
                        width: w,
                        color: Colors.grey.withOpacity(0.1))
                    : ClipRRect(
                        // borderRadius: BorderRadius.circular(h/2),
                        child: Image.file(
                        resizedFile!,
                        width: w,
                        // height: h / 3,
                        fit: BoxFit.fill,
                      )),
                const SizedBox(
                  height: 10,
                ),
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: (isLoading.value == true)
                        ? Container()
                        : (responseStatus == 200)
                            ? Container()
                            : Text(
                                "Status Code:- ${responseStatus ?? ""}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                  ),
                ),
                (isLoading.value == false)
                    ? (data != null)
                        ? (data["Percentage"].isEmpty && data["Class"].isEmpty)
                            ? Text(
                                "As i am ml model i can detect only diamond images",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: data['Class'].length,
                                itemBuilder: (BuildContext context, index) {
                                  switch (data["Class"][index].toString()) {
                                    case "15":
                                      classStatus = "CLEAN";
                                      break;
                                    case "16":
                                      classStatus = "DOT ";
                                      break;
                                    case "17":
                                      classStatus = "INCLUSION ";
                                      break;
                                    case "18":
                                      classStatus = "BREAKAGE";
                                      break;
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "$classStatus = >   ${data["Percentage"][index].toString()} % ",
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          )),
                                    ],
                                  );
                                })
                        : Container()
                    : const Center(child: CircularProgressIndicator()),
                const SizedBox(
                  height: 10,
                ),
                (data == null)
                    ? Container()
                    : (isLoading.value == true)
                        ? Container()
                        : Image.memory(base64Decode(data["image"])),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          _pickImageFromGallery();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Icon(
                          CupertinoIcons.photo,
                          size: 80,
                          color: Colors.black,
                        )),
                    ElevatedButton(
                        onPressed: () async {
                          _pickImageFromCamera();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Icon(
                          CupertinoIcons.camera,
                          size: 80,
                          color: Colors.black,
                        )),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  decoration: InputDecoration(
                      hintText: "Feedback",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      )),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                    width: w,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      child: const Text("Feedback"),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
