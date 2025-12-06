import 'package:flutter/material.dart';
import 'AuthServices_page.dart' show AuthServices;
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Signup_page.dart';

class Login_page extends StatefulWidget {
  const Login_page({super.key});

  @override
  State<Login_page> createState(){
    return _Login_pageState();
  }
}

class _Login_pageState extends State<Login_page> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          children: [
            Container(
              margin: EdgeInsets.only(top: 80,),
              child: Text('Sign In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Roboto',
                ),
              ),

            ),
            Container(
              margin: EdgeInsets.only(top: 100, right: 30, left: 30),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter Email',
                  hintText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, right: 30, left: 30),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter Password',
                  hintText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, right: 30, left: 30),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      isloading = true;
                    });
                    AuthServices().login(
                        context: context,
                        email: _emailController.text,
                        password: _passwordController.text
                    );
                  },
                  child: isloading ? CircularProgressIndicator(
                    color: Colors.white,) : Text('Submit'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),),
            Container(
              margin: EdgeInsets.only(top: 10, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                            text: "Register Account",
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => Signup_page())); }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}