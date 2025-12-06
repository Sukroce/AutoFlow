import 'Login_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'AuthServices_page.dart' show AuthServices;
import 'package:flutter/services.dart';


class Signup_page extends StatefulWidget {
  const Signup_page({super.key});

  @override
  State<Signup_page> createState(){
    return _Signup_pageState();
  }
}

class _Signup_pageState extends State<Signup_page> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolnameController = TextEditingController();
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
              child: Text('Register Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 60, right: 30, left: 30),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter Your Name',
                  hintText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, right: 30, left: 30),
              child: TextField(
                controller: _schoolnameController,
                decoration: InputDecoration(
                  labelText: 'Enter School Name',
                  hintText: 'School Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, right: 30, left: 30),
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
                    AuthServices().signup(
                        context: context,
                        email: _emailController.text,
                        password: _passwordController.text
                    );
                  },
                  child: isloading? CircularProgressIndicator(color: Colors.white,) : Text('Submit'),
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
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                            text: "Sign In",
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => Login_page())); }
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