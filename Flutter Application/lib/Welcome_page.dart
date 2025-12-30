import 'Login_page.dart';
import 'Signup_page.dart';
import 'package:flutter/material.dart';

class Welcome_page extends StatefulWidget {
  const Welcome_page({super.key});

  @override
  State<Welcome_page> createState(){
    return _Welcome_pageState();
  }
}

class _Welcome_pageState extends State<Welcome_page> {
  bool isloadingr = false;
  bool isloadings = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 120),
              child: Text('Welcome to Axoratoor App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 80),
              child: Text('Get Started...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 20, right: 15, left: 30),
                    height: 56,
                    child: SizedBox(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isloadingr = true;
                          });
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => Signup_page()),
                          );
                        },
                        child: isloadingr? CircularProgressIndicator(color: Colors.white,) :  Text('Register Account'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 20, right: 30, left: 15),
                    height: 56,
                    child: SizedBox(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isloadings = true;
                          });
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => Login_page()),
                          );
                        },
                        child: isloadings? CircularProgressIndicator(color: Colors.white,) :  Text('Sign In'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
