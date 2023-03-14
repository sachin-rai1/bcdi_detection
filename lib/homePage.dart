import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
import 'package:pdf/widgets.dart' as pw;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  TextEditingController? idTextController;
  TextEditingController? titleTextController;

  var data;
  var Cleanconfidence;
  var cleanClassValue;
  var isLoading = false.obs;
  var id = 0.obs;
  var classStatus;
  var responseStatus;

  TextEditingController runNo = TextEditingController();

  upload(File imageFile) async {
    isLoading.value = true;
    var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var uploadURL = "http://ec2-54-162-165-26.compute-1.amazonaws.com/predict";
    var uri = Uri.parse(uploadURL);
    var request = http.MultipartRequest("POST", uri);
    var multipartFile =
        http.MultipartFile('file', stream, length, filename: (imageFile.path));
    request.files.add(multipartFile);
    var response = await request.send();
    responseStatus = response.statusCode;

    if (response.statusCode == 200) {
      response.stream
          .transform(utf8.decoder)
          .transform(json.decoder)
          .listen((value) {
        print("Value is :  $value");
        data = value;
        setState(() {});
      });
    }
    isLoading.value = false;
  }

  savePdf() async {
    if (_image == null) {
      Get.showSnackbar(GetSnackBar(
        message: "No Image Selected",
        title: "Select Image",
        snackPosition: SnackPosition.TOP,
        duration: Duration(milliseconds: 1500),
      ));
    }
    else if(runNo.text == ""){
      Get.showSnackbar(GetSnackBar(
        message: "Run Number Empty",
        title: "Enter Run No.",
        snackPosition: SnackPosition.TOP,
        duration: Duration(milliseconds: 1500),
      ));
    }
    else {
      var h = MediaQuery.of(context).size.height;
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Column(
              children: [
                pw.Text("Run No : ${runNo.text}" , style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Image(
                  pw.MemoryImage(_image!.readAsBytesSync()),
                  height: h / 1.5,
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
                                  fontSize: 20, fontWeight: pw.FontWeight.bold),
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
                (_image == null)
                    ? Container(
                        height: h / 3,
                        width: w,
                        color: Colors.grey.withOpacity(0.1))
                    : ClipRRect(
                        // borderRadius: BorderRadius.circular(h/2),
                        child: Image.file(
                        _image!,
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
                        ? const Center(child: CircularProgressIndicator())
                        : Text(
                            "Status Code:- ${responseStatus ?? ""}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                (isLoading.value == false)
                    ? (data != null)
                        ? ListView.builder(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          _pickImagefromGallery();
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

  Future<void> _pickImagefromGallery() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    log('image path : ${image?.path} -- MimeType : ${image?.mimeType}');

    setState(() {
      _image = File(image!.path);
    });
    upload(_image!);
    Get.back();
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    log('image path : ${image?.path} -- MimeType : ${image?.mimeType}');

    setState(() {
      _image = File(image!.path);
    });

    upload(_image!);
    Get.back();
  }
}
