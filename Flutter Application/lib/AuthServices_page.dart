import 'Home_page.dart';
import 'Welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthServices_page extends StatefulWidget {
  const AuthServices_page({super.key});

  @override
  State<AuthServices_page> createState(){
    return _AuthServices_pageState();
  }
}

class _AuthServices_pageState extends State<AuthServices_page> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if(snapshot.hasData) {
                return Home_page();
              }else {
                return Welcome_page();
              }
            },
          )
      ),
    );
  }
}

class AuthServices {

  Future<void> login({
    required BuildContext context,
    required String email,
    required String password
  }) async {


    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password);
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (BuildContext context) => Home_page())
      );
    }
    on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided, try again";
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
    catch (e) {

      Fluttertoast.showToast(
        msg: "Something went wrong. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signup({
    required BuildContext context,
    required String email,
    required String password
  }) async {


    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password);
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (BuildContext context) => Home_page())
      );
    }
    on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        message = "An account already exists with that email.";
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
    catch (e) {

      Fluttertoast.showToast(
        msg: "Something went wrong. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signout({
    required BuildContext context
  }) async {

    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (BuildContext context) => Welcome_page())
    );
  }
}
