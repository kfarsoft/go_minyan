import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_minyan/model/model.dart';
import 'package:go_minyan/resources/images.dart';
import 'package:go_minyan/style/theme.dart' as Theme;
import 'package:go_minyan/translation.dart';
import 'package:go_minyan/user_repository.dart';
import 'package:go_minyan/authentication_bloc/bloc.dart';
import 'package:go_minyan/login/login.dart';
import 'package:go_minyan/widget/widget.dart';
import 'package:provider/provider.dart';

enum LoginFormType { login, reset }

class LoginForm extends StatefulWidget {
  final UserRepository _userRepository;

  final LoginFormType loginFormType;

  LoginForm({Key key, @required UserRepository userRepository, this.loginFormType})
      : assert(userRepository != null),
        _userRepository = userRepository,
        super(key: key);

  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with SingleTickerProviderStateMixin{

  LoginFormType loginFormType;
  _LoginFormState({this.loginFormType});

  final FocusNode myFocusNodeEmailLogin = FocusNode();
  final FocusNode myFocusNodePasswordLogin = FocusNode();

  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  bool _darkmode;

  bool _obscureTextLogin = true;

  LoginBloc _loginBloc;

  UserRepository get _userRepository => widget._userRepository;

  bool get isPopulated =>
      loginEmailController.text.isNotEmpty && loginPasswordController.text.isNotEmpty;

  bool isLoginButtonEnabled(LoginState state) {
    return state.isFormValid && isPopulated && !state.isSubmitting;
  }

  final formKey = GlobalKey<FormState>();
  void switchFormState(String state) {
    formKey.currentState.reset();
    if (state == "reset") {
      setState(() {
        loginFormType = LoginFormType.reset;
      });
    } else {
      setState(() {
        loginFormType = LoginFormType.login;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loginBloc = BlocProvider.of<LoginBloc>(context);
    loginEmailController.addListener(_onEmailChanged);
    loginPasswordController.addListener(_onPasswordChanged);
    loginFormType = LoginFormType.login;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _darkmode = Provider.of<AppModel>(context).darkmode;
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.isFailure) {
          Scaffold.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(Translations.of(context).loginFailure), Icon(Icons.error)],
                ),
                backgroundColor: Colors.red,
              ),
            );
        }
        if (state.isSubmitting) {
          Scaffold.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: _darkmode ? Theme.Colors.primaryDarkColor : Theme.Colors.primaryColor,
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextModel(text: Translations.of(context).loginLoading, color: Theme.Colors.secondaryColor),
                    CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.Colors.secondaryColor),),
                  ],
                ),
              ),
            );
        }
        if (state.isSuccess) {
          BlocProvider.of<AuthenticationBloc>(context).dispatch(LoggedIn());
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constrain) {
              var max = constrain.maxWidth;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15, vertical: max < 400 ? 10 : 50),
                child: ListView(
                  physics: NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _buildImage(),
                    _buildAdminBar(max),
                    _buildForm(state, max),
                    _buildLoginButton(state),
                    _buildLastButtons(),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildImage(){
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Image(
          fit: BoxFit.contain,
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.25,
          image: new AssetImage(Images.logoImg)
      ),
    );
  }

  Widget _buildAdminBar(max) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      height: max < 400 ? MediaQuery.of(context).size.height * 0.07 : MediaQuery.of(context).size.height * 0.04,
      width: MediaQuery.of(context).size.width * 0.5,
      decoration: BoxDecoration(
        color: Theme.Colors.secondaryColor,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Align(
          alignment: Alignment.center,
          child: TextModel(
            text: loginFormType == LoginFormType.login ? Translations.of(context).loginTitle : Translations.of(context).lblForgot, size: 14, color: _darkmode ? Theme.Colors.blackColor : Theme.Colors.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(LoginState state, max) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: loginFormType == LoginFormType.reset ? 90 : max < 400 ? MediaQuery.of(context).size.height * 0.2 : MediaQuery.of(context).size.height * 0.15,
        child: Form(
          key: formKey,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                    bottom: 10.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  cursorColor: Theme.Colors.primaryColor,
                  focusNode: myFocusNodeEmailLogin,
                  controller: loginEmailController,
                  autocorrect: false,
                  validator: (_) {
                    return !state.isEmailValid ? Translations.of(context).invalidMail : null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                      fontFamily: Theme.Fonts.primaryFont,
                      fontSize: 15.0,
                      color: Colors.black),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesomeIcons.envelope,
                      color: Colors.black,
                      size: 15.0,
                    ),
                    hintText: Translations.of(context).emailHint,
                    hintStyle: TextStyle(
                        fontFamily: Theme.Fonts.primaryFont, fontSize: 15.0, color: Colors.black54),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Colors.grey,
              ),
              loginFormType == LoginFormType.reset ? Container() : Padding(
                padding: EdgeInsets.only(
                    top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  cursorColor: Theme.Colors.primaryColor,
                  focusNode: myFocusNodePasswordLogin,
                  controller: loginPasswordController,
                  obscureText: _obscureTextLogin,
                  autocorrect: false,
                  validator: (_) {
                    return !state.isPasswordValid ? Translations.of(context).invalidPass : null;
                  },
                  style: TextStyle(
                      fontFamily: Theme.Fonts.primaryFont,
                      fontSize: 15.0,
                      color: Colors.black),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesomeIcons.lock,
                      size: 15.0,
                      color: Colors.black,
                    ),
                    hintText: Translations.of(context).passHint,
                    hintStyle: TextStyle(
                        fontFamily: Theme.Fonts.primaryFont, fontSize: 15.0, color: Colors.black54),
                    suffixIcon: GestureDetector(
                      onTap: _toggleLogin,
                      child: Icon(
                        _obscureTextLogin
                            ? FontAwesomeIcons.eye
                            : FontAwesomeIcons.eyeSlash,
                        size: 15.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginState state){
    return Container(
      margin: EdgeInsets.only(top: loginFormType == LoginFormType.reset ? 80 : MediaQuery.of(context).size.height * 0.03, bottom: 15),
      decoration: new BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _darkmode ? Theme.Colors.secondaryColor : Theme.Colors.primaryColor,
            offset: Offset(1.0, 6.0),
            blurRadius: 20.0,
          ),
        ],
        color: _darkmode ? Theme.Colors.secondaryDarkColor : Theme.Colors.primaryColor,
      ),
      child: LoginButton(
        size: MediaQuery.of(context).size,
        text: loginFormType == LoginFormType.login ? Translations.of(context).btnLogin : Translations.of(context).btnRestore,
        onPressed: loginFormType == LoginFormType.login ? isLoginButtonEnabled(state)
            ? _onFormSubmitted
            : null : _btnResetPress,
      ),
    );
  }

  Widget _buildLastButtons() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height * 0.2,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: FlatButton(
                onPressed: () {
                  if(loginFormType == LoginFormType.reset){
                    switchFormState('login');
                    BlocProvider.of<AuthenticationBloc>(context).dispatch(AppStarted());
                  }else{
                    BlocProvider.of<AuthenticationBloc>(context).dispatch(GuestStarted());
                  }
                  //loginFormType == LoginFormType.login ? BlocProvider.of<AuthenticationBloc>(context).dispatch(GuestStarted()) : BlocProvider.of<AuthenticationBloc>(context).dispatch(AppStarted());
                },
                child: TextModel(text: Translations.of(context).btnBack, size: 17, color: _darkmode ? Theme.Colors.whiteColor : Theme.Colors.primaryColor, decoration: TextDecoration.underline,
                )),
          ),
          loginFormType == LoginFormType.reset ? Container() : Align(
            alignment: Alignment.center,
            child: FlatButton(
                onPressed: () {
                  setState(() {
                    switchFormState('reset');
                  });
                  //BlocProvider.of<AuthenticationBloc>(context).dispatch(ForgotPassword());
                },
                child: TextModel(text: Translations.of(context).btnForgot, size: 17, color: _darkmode ? Theme.Colors.whiteColor : Theme.Colors.primaryColor, decoration: TextDecoration.underline,
                )),
          ),
        ],
      ),
    );
  }

  void _btnResetPress() async{
    try{
      await _userRepository.sendPasswordResetEmail(loginEmailController.text)
          .then((onValue){
        Scaffold.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: _darkmode ? Theme.Colors.primaryDarkColor : Theme.Colors.primaryColor,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(Translations.of(context).lblEmailRestoreSent),
                ],
              ),
            ),
          );
      });
    }on PlatformException catch (e) {
      Scaffold.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: _darkmode ? Theme.Colors.primaryDarkColor : Theme.Colors.primaryColor,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.code == 'ERROR_USER_NOT_FOUND' ? Translations.of(context).connectionError : Translations.of(context).errorDialog),
              ],
            ),
          ),
        );
    }finally {
      print("finally");
    }
  }

  @override
  void dispose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.dispose();
  }

  void _toggleLogin() {
    setState(() {
      _obscureTextLogin = !_obscureTextLogin;
    });
  }

  void _onEmailChanged() {
    _loginBloc.dispatch(
      EmailChanged(email: loginEmailController.text),
    );
  }

  void _onPasswordChanged() {
    _loginBloc.dispatch(
      PasswordChanged(password: loginPasswordController.text),
    );
  }


  void _onFormSubmitted() {
    _loginBloc.dispatch(
      LoginWithCredentialsPressed(
        email: loginEmailController.text,
        password: loginPasswordController.text,
      ),
    );
  }
}