import 'package:bcdi_detection/homePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController userName = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage("assets/images/cblogo.png"), height: w / 5),
            const SizedBox(
              height: 80,
            ),
            TextFormField(
              controller: userName,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: "UserName",
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.white)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  )),
            ),
            const SizedBox(
              height: 30,
            ),
            TextFormField(
              controller: password,
              style: TextStyle(color: Colors.white),
              obscureText: isObscure,
              decoration: InputDecoration(
                  hintText: "Password",
                  suffixIcon: InkWell(
                    onTap: (){
                      setState(() {});
                      isObscure = !isObscure;
                    },
                      child:(isObscure == false)?Icon(Icons.remove_red_eye , color: Colors.white,):Icon(CupertinoIcons.eye_slash , color: Colors.white,)),
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.white)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  )),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
                width: w / 2,
                child: ElevatedButton(
                  onPressed: () {
                    login();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(15))),
                  child: const Text("Login"),
                ))
          ],
        ),
      ),
    );
  }

  void login() {
    if (userName.text == "Maitri" && password.text == "M@!Tr!") {
      Get.offAll(() => HomePage());
    } else if (userName.text == "") {
      print("Hii");
      Get.showSnackbar(GetSnackBar(
        snackPosition: SnackPosition.TOP,
        title: "Enter UserName",
        message: "UserName should not empty",
        duration: Duration(milliseconds: 1500),
      ));
    } else if (password.text == "") {
      Get.showSnackbar(GetSnackBar(
        snackPosition: SnackPosition.TOP,
        title: "Enter password",
        message: "password should not empty",
        duration: Duration(milliseconds: 1500),
      ));
    } else {
      Get.showSnackbar(GetSnackBar(
        snackPosition: SnackPosition.TOP,
        title: "Invalid Credential",
        message: "Incorrect UserName or Password",
        duration: Duration(milliseconds: 1500),
      ));
    }
  }
}