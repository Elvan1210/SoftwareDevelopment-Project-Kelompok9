import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: LayoutBuilder(builder: (ctx, c) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: double.infinity),
              child: Wrap(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Container(height: 100, color: Colors.red),
                  )
                ],
              )
            )
          )
        );
      })
    )
  ));
}
