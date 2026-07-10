import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/config/app_config.dart';
import 'package:flutter_application_1/untils/date_util.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  State<LoginScreen> createState() => _LoginScreenState();
  
}



class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameValueController = TextEditingController();
  final _passwordValueController = TextEditingController();

  Future<(bool, String, String)> _authenRequest() async {
  String username = _usernameValueController.text;
  DateTime now = DateTime.now();
  String formattedDateString = DateUtil.getFormattedDate(now);

  String combinedString = "$username&$formattedDateString";
  print(combinedString);

  String authenRequestString = sha256
      .convert(utf8.encode(combinedString))
      .toString();
  print("authenRequestString: $authenRequestString");
  final response = await http.post(
    Uri.parse("${Appconfig.apiBaseUrl}/authen/authen_request"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'authen_request':authenRequestString}),
  );

  final json = jsonDecode(response.body);

  print(json);

  return (
    json["isError"] as bool,
    json["data"] as String,
    json["errorMessage"] as String,
  );
  
}

Future<({bool isError, String data , String errorMessage})>_accessRequest(
  String authenToken,
  
) async {
  String username = _usernameValueController.text;
  String password = _passwordValueController.text;
  String passwordEncode = sha256.convert(utf8.encode(password)).toString();
  String combinedString = "$username&$passwordEncode&$authenToken";
  String authenSignature = sha256.convert(utf8.encode(combinedString)).toString();

  print(combinedString);
  print(authenSignature);
  
 

  final response = await http.post(
    Uri.parse("${Appconfig.apiBaseUrl}/authen/access_request"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'authen_signature': authenSignature,
      'authen_token': authenToken
      
    }),
  );

  final json = jsonDecode(response.body);
  print(json);

  if(!json["isError"]) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", json["data"]["access_token"]);
    await prefs.setString("username",_usernameValueController.text);
    await prefs.setString("image_url", json["data"]["image_url"]);
    
  }

  return (
    isError: json["isError"] as bool,
    data: json["data"]["access_token"] as String,
    errorMessage: json["errorMessage"] as String,
  );
  
}
void _doLogin (BuildContext context) async{
  var (isError , authenToken, errorMessage) = await _authenRequest();
  print("authenToken: $authenToken");

  if(isError) {
    showDialog(
      context:context,
      builder: (context) {
        return AlertDialog(content: Text(errorMessage));
      },
        );    
  }else{
    var result = await _accessRequest(authenToken);

    print("access_token: ${result.data}");
    if(result.isError) {
      //TO DO
  }else{
    showDialog(
      context:context,
      builder: (context) {
        return AlertDialog(content: Text(result.errorMessage));
      },
    );
  }
  }
}


  @override
  Widget build(BuildContext context) {

     print("BUILD LOGIN SCREEN");
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/pr1.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          height: 400,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
            borderRadius: BorderRadius.circular(15),
            color: Colors.black.withValues(alpha: 0.1),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 50),
                  child: Text("Username"),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: TextFormField(
                    controller: _usernameValueController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอก Username';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 50),
                  child: Text("Password"),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: TextFormField(
                    obscureText: true,
                    controller: _passwordValueController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอก Password';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 40),
                  child: ElevatedButton(
                    onPressed: ()  {
                      if (_formKey.currentState!.validate())
                        {
                          _doLogin(context);
                        }
                    },
                    child: Text("Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
