import 'package:flutter/material.dart';

import 'Card/card.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0070D0), // Blue background color
      // appBar: AppBar(
      //   title: Text('Flutter Demo'),
      //   backgroundColor: Color(0xFF0070D0),
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 18), // Adds space above the card

          Text(
            'Arete Consultant Pvt Ltd.',
            style: TextStyle(color: Colors.white, fontSize: 24, height: 6),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CustomCard(),
            ),
          ),
        ],
      ),
    );
  }
}
