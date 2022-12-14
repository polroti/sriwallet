import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:sriwallet/auth/functions/create_user.dart';
import 'package:sriwallet/auth/functions/validators.dart';
import 'package:sriwallet/auth/screens/login.dart';
import 'package:sriwallet/constants/colors/text_color.dart';
import 'package:sriwallet/constants/labels/button_labels.dart';
import 'package:sriwallet/constants/labels/input_labels.dart';
import 'package:sriwallet/constants/texts/register_texts.dart';
import 'package:sriwallet/home/screens/homepage.dart';
import 'package:sriwallet/themes/theme.dart';
import 'package:sriwallet/utils/input/name_input.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _registerPageKey = GlobalKey<FormState>();
  bool verificationSent = false;
  bool phoneNumberFilled = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController nicController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNoControlller = TextEditingController();
  TextEditingController codeController = TextEditingController();

  bool isOtpFilled = false;

  FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseFirestore db = FirebaseFirestore.instance;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  String phoneNumber = "";
  String verificationIdReceived = "";
  String dialogMessage = "";

  late ProgressDialog progressDialog;

  @override
  Widget build(BuildContext context) {
    progressDialog = ProgressDialog(context, type: ProgressDialogType.normal);
    progressDialog.style(
        message: dialogMessage,
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: const CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: const TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: const TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor(context),
        title: Text(
            "REGISTER WITH MOBILE",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: textLabelColor(context), fontWeight: FontWeight.bold),
          ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _registerPageKey,
          child: Column(children: [
            Form(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
               // registerWithPhoneNoText(),
                nameInput(nameController, context),
                nicInput(),
                emailInput(),
                phoneNumberInput(),
                otpInput(),
                masterButton(),
                const SizedBox(
                  height: 120,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [alreadyHaveAccPrompt()],
                ),
                goAndLogin()
              ],
            )),
          ]),
        ),
      ),
    );
  }

  void verifyMobile() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) {
        verificationIdReceived = verificationId;

        setState(() {
          verificationSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Widget phoneNumberInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
      child: TextFormField(
        onChanged: (value) {
          setState(() {
            if (value.length == 9) {
              setState(() {
                phoneNumber = "+94${phoneNoControlller.text}";
                phoneNumberFilled = true;
              });
            } else {
              setState(() {
                phoneNumberFilled = false;
              });
            }
          });
        },
        controller: phoneNoControlller,
        maxLength: 9,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
            counterText: "",
            label: const Text(InputLabels.MOBILE_NO),
            prefix: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Text(
                "+94",
                style: TextStyle(
                    color: getInputPrefixTextColorForTheme(context)),
              ),
            ),
            hintText: HintTexts.MOBILE_NO,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Theme.of(context).primaryColor))),
      ),
    );
  }

  Widget otpInput() {
    //verification
    return Visibility(
        visible: verificationSent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10, right: 10, bottom: 10, top: 10),
                child: TextFormField(
                  onChanged: (value) {
                    if (value.length == 6) {
                      setState(() {
                        isOtpFilled = true;
                      });
                    } else {
                      setState(() {
                        isOtpFilled = false;
                      });
                    }
                  },
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  controller: codeController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      hintText: HintTexts.OTP,
                      label: const Text(InputLabels.OTP),
                      counterText: "",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor))),
                ),
              ),
            ),
          ],
        ));
  }

  Widget masterButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.lightBlue[500],
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: !phoneNumberFilled
            ? null
            : () {
                if (_registerPageKey.currentState!.validate()) {
                  if (!verificationSent) {
                    verifyMobile();
                  } else {
                    if (_registerPageKey.currentState!.validate()) {
                      loginWithMobileNo(context);
                    }
                  }
                }
              },
        child: Text(
          !verificationSent
              ? ButtonConstants.SEND_OTP
              : ButtonConstants.REGISTER_WITH_MOBILE,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget goAndLogin() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(width: 2.0, color: Colors.blue),
        ),
        onPressed: () {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginPage()));
        },
        child: Text(
          ButtonConstants.LOGIN,
          style: const TextStyle(color: Colors.blue),
        ),
      ),
    );
  }

  void loginWithMobileNo(BuildContext context) async {
    await progressDialog.show();
    PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: verificationIdReceived, smsCode: codeController.text);

    await auth.signInWithCredential(phoneAuthCredential).then((value) => {
          {
            dialogMessage = "Creating user...",
            createUserAndWallet(
              nameController.text,
              emailController.text,
              nicController.text,
              phoneNoControlller.text,
            ),
            dialogMessage = "Logging in...",
            progressDialog.hide().then((value) => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage())))
          }
        });
  }

  Widget nicInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
      child: TextFormField(
        controller: nicController,
        validator: nicValidator,
        decoration: InputDecoration(
            label: const Text(InputLabels.NIC),
            counterText: "",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Theme.of(context).primaryColor))),
      ),
    );
  }

  Widget emailInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
      child: TextFormField(
        controller: emailController,
        validator: emailValidator,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
            label: const Text(InputLabels.EMAIL),
            counterText: "",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Theme.of(context).primaryColor))),
      ),
    );
  }
}
